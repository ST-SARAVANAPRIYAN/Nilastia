import shutil
import textwrap
from argparse import Namespace
from pathlib import Path

from nilastia.utils.dots.deployer import Deployer
from nilastia.utils.dots.legacy import (
    LEGACY_META_PKG,
    detect_legacy_repo,
    legacy_config_symlinks,
    legacy_symlinks,
    legacy_to_delete,
)
from nilastia.utils.dots.manifest import ComponentError, Manifest, ManifestError
from nilastia.utils.dots.misc import build_local_packages, run_hooks
from nilastia.utils.dots.packages import DEFAULT_AUR_HELPER, PackageError, PackageInstaller
from nilastia.utils.dots.source import DotsSource, SourceError
from nilastia.utils.dots.state import DotsState
from nilastia.utils.io import confirm, disable_input, fatal, info, log, pause, prompt_selection, warn
from nilastia.utils.paths import (
    config_backup_dir,
    config_dir,
    cache_dir,
)


def _parse_list_arg(value: str | None) -> list[str] | None:
    if value is None:
        return None
    return [item.strip() for item in value.split(",") if item.strip()]


def _deref_symlink(link: Path, target: Path) -> None:
    """Replace symlink `link` with a real copy of `target`'s content."""

    bak = link.rename(link.parent / f"{link.name}.bak")
    try:
        if target.is_dir():
            shutil.copytree(target, link, symlinks=True)
        else:
            shutil.copy2(target, link)
    except OSError:
        bak.rename(link)
        raise
    bak.unlink()


class Command:
    args: Namespace

    def __init__(self, args: Namespace) -> None:
        self.args = args

    def run(self) -> None:
        if self.args.noconfirm:
            disable_input()

        self.print_greeting()
        self.migrate_from_other_wm()
        self.create_backup()
        
        legacy_dir = detect_legacy_repo()  # Detect legacy repo first cause deploy overwrites legacy syms

        source, tip, manifest = self.fetch_manifest()
        
        # Determine packages installer and check optional prereqs
        installer = PackageInstaller.get(self.args.aur_helper, self.args.noconfirm)
        self.install_prereqs(installer)

        try:
            installer, packages, local_packages = self.install_packages(source, manifest)
        except PackageError as e:
            fatal(e)
            
        run_hooks(manifest, "post_package")
        self.dereference_legacy(legacy_dir)  # Copy legacy content into place before deploy overwrites the symlinks
        deployed = self.deploy_configs(source, manifest)
        
        # Auto-configure systemd service overrides and Wayland sessions
        self.setup_systemd_and_session()
        
        run_hooks(manifest, "post_install")

        DotsState(
            aur_helper=getattr(installer, "helper", DEFAULT_AUR_HELPER),
            applied_rev=tip,
            enabled_components=manifest.enabled_components,
            packages=packages,
            local_packages=local_packages,
            deployed_files=deployed,
        ).save()

        self.migrate_legacy(installer, legacy_dir)
        self.print_done()

    def print_greeting(self) -> None:
        print(
            "\033[38;2;150;241;241m"  # Nilastia colour
            + textwrap.dedent(
                r"""
                ╭─────────────────────────────────────────────────╮
                │      _   ___ _             _   _                │
                │     | \ | (_) |           | | (_)               │
                │     |  \| |_| | __ _  ___ | |_ _  __ _          │
                │     | . ` | | |/ _` |/ __|| __| |/ _` |         │
                │     | |\  | | | (_| |\__ \| |_| | (_| |         │
                │     |_| \_|_|_|\__,_||___/ \__|_|\__,_|         │
                │                                                 │
                ╰─────────────────────────────────────────────────╯
                """
            )
            + "\033[0m"
        )
        info("Welcome to the Nilastia Desktop Environment installer!")
        info("Here's a quick overview of what this installer will configure:")
        info("  - Install system dependency packages via AUR helper")
        info("  - Setup desktop shell configurations and systemd user services")
        info("  - Scan for migrations and back up conflicting directories safely")
        pause()
        print()

    def migrate_from_other_wm(self) -> None:
        print()
        log("Scanning for other Window Manager configurations...")
        wms = [
            ("hypr", "Hyprland"),
            ("sway", "Sway"),
            ("i3", "i3wm"),
            ("niri", "Existing Niri"),
        ]
        found = []
        for folder, name in wms:
            if (config_dir / folder).exists():
                found.append((folder, name))

        if found:
            info(f"Detected existing configurations for: {', '.join(name for _, name in found)}")
            if confirm("Would you like to safely back up these directories before proceeding?", default=True):
                from datetime import datetime
                import tarfile
                timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                backup_root = cache_dir / "nilastia" / "backups"
                backup_root.mkdir(parents=True, exist_ok=True)
                backup_file = backup_root / f"migration_backup_{timestamp}.tar.gz"

                with tarfile.open(backup_file, "w:gz") as tar:
                    for folder, name in found:
                        log(f"  Backing up {name} config folder...")
                        tar.add(config_dir / folder, arcname=f"config/{folder}")
                info(f"Backup saved to: {backup_file.name}")

    def install_prereqs(self, installer: PackageInstaller) -> None:
        if self.args.noconfirm:
            return

        print()
        log("Select additional Nilastia modules/dependencies to install:")
        choices = [
            "Screen Recording Support (wf-recorder, pipewire, wireplumber)",
            "Video Wallpaper Utilities (mpv, swaybg)",
            "System Monitoring Fonts & Icons (ttf-nerd-fonts-symbols-common, otf-font-awesome)",
        ]
        selected = prompt_selection(choices, "Optional components to install?")

        packages = []
        if any("Screen Recording" in s for s in selected):
            packages.extend(["wf-recorder", "pipewire", "pipewire-pulse", "wireplumber"])
        if any("Video Wallpaper" in s for s in selected):
            packages.extend(["mpv", "swaybg"])
        if any("System Monitoring Fonts" in s for s in selected):
            packages.extend(["ttf-nerd-fonts-symbols-common", "otf-font-awesome"])

        if packages:
            log(f"Installing selected packages: {', '.join(packages)}...")
            try:
                installer.install(packages)
                info("Packages installed successfully.")
            except Exception as e:
                warn(f"Failed to install some optional packages: {e}")

    def setup_systemd_and_session(self) -> None:
        print()
        log("Configuring display manager session and priorities...")
        try:
            # Rebrand/rename the systemd service unit file from dots to nilastia namespace!
            old_service = Path.home() / ".config" / "systemd" / "user" / "niri-caelestia-shell.service"
            new_service = Path.home() / ".config" / "systemd" / "user" / "niri-nilastia-shell.service"
            
            new_service.parent.mkdir(parents=True, exist_ok=True)
            
            if old_service.exists():
                content = old_service.read_text()
                content = content.replace("caelestia", "nilastia")
                new_service.write_text(content)
                old_service.unlink()
                info("  Rebranded niri-caelestia-shell.service to niri-nilastia-shell.service")
            else:
                # Fresh install: deploy from our extras template and resolve absolute path dynamically
                repo_root = Path(__file__).parent.parent.parent.parent.parent
                template_path = repo_root / "extras" / "niri-nilastia-shell.service"
                if template_path.exists():
                    content = template_path.read_text()
                    content = content.replace("@REPO_ROOT@", str(repo_root))
                    new_service.write_text(content)
                    info("  Deployed new niri-nilastia-shell.service from template")

            from nilastia.subcommands.doctor import Command as DoctorCommand
            doc = DoctorCommand(Namespace())
            doc.fix_service_priorities()
            doc.fix_session_registration()

            import subprocess
            subprocess.run(["systemctl", "--user", "daemon-reload"], check=True)
            subprocess.run(["systemctl", "--user", "enable", "niri-nilastia-shell.service"], check=True)
            subprocess.run(["systemctl", "--user", "start", "niri-nilastia-shell.service"], check=False)
            info("  Activated and started niri-nilastia-shell.service")
        except Exception as e:
            warn(f"Failed to run automatic alignments: {e}")

    def create_backup(self) -> None:
        if config_dir.exists():
            if not confirm("Back up your ~/.config directory?", default=True):
                return

            log(f"Creating a backup of {config_dir}...")
            if config_backup_dir.exists():
                if not confirm("A backup already exists, overwrite?", default=False):
                    info("Not creating backup.")
                    return

                log("Deleting old backup...")
                shutil.rmtree(config_backup_dir)

            shutil.copytree(config_dir, config_backup_dir, symlinks=True)
            info(f"Created backup at {config_backup_dir}")

    def fetch_manifest(self) -> tuple[DotsSource, str, Manifest]:
        print()
        log("Fetching dots repo...")
        source = DotsSource()
        try:
            source.ensure()
            tip = source.checkout_tip()
        except SourceError as e:
            fatal(e)

        enable = _parse_list_arg(self.args.enable_components) or []
        disable = _parse_list_arg(self.args.disable_components) or []
        if "hypr" not in enable and "hypr" not in disable:
            disable.append("hypr")
        try:
            manifest = source.manifest_at(tip)

            # No flags given, prompt user for non-default components
            if enable is None and disable is None:
                optional = [name for name, comp in manifest.components.items() if not comp.default]
                if optional:
                    enable = prompt_selection(optional, "Components to enable?")

            manifest.resolve_components(enable=enable, disable=disable)
        except (SourceError, ManifestError, ComponentError) as e:
            fatal(e)

        names = ", ".join(manifest.enabled_components) or "none"
        info(f"Enabled components: {names}")

        return source, tip, manifest

    def deploy_configs(self, source: DotsSource, manifest: Manifest) -> dict[str, str]:
        print()
        log("Installing configs...")
        deployer = Deployer()
        for entry in manifest.enabled_entries():
            src = source.working_path(entry.expanded_src())
            if not src.exists():
                warn(f"missing in source, skipping: {entry.src}")
                continue

            dests = entry.expanded_dests()
            if not dests:
                warn(f"dest glob matched nothing, skipping: {entry.dest}")
                continue

            for dest in dests:
                deployer.place(src, Path(dest))
                info(f"{entry.src} -> {dest}")

        # Copy niri configuration from local repo if present
        repo_niri = Path(__file__).parent.parent.parent.parent.parent / "niri"
        if repo_niri.is_dir():
            dest_niri = Path.home() / ".config" / "niri"
            import shutil
            if dest_niri.exists():
                shutil.rmtree(dest_niri)
            shutil.copytree(repo_niri, dest_niri)
            info("  Deployed Niri configuration from repository to ~/.config/niri/")

        return deployer.deployed_files

    def install_packages(
        self, source: DotsSource, manifest: Manifest
    ) -> tuple[PackageInstaller, dict[str, str], dict[str, list[str]]]:
        installer = PackageInstaller.get(self.args.aur_helper, self.args.noconfirm)

        packages = {}
        desired = [pkg for pkg in manifest.enabled_packages() if pkg not in (
            "caelestia-shell", "caelestia-cli", 
            "caelestia-shell-git", "caelestia-cli-git",
            "nilastia-shell", "nilastia-cli",
            "nilastia-shell-git", "nilastia-cli-git",
            "firefox", "zed", "vscode", "vscodium", "vscodium-bin", 
            "vscodium-bin-marketplace", "spotify", "spicetify-cli", 
            "spicetify-marketplace-bin", "discord", "equibop-bin", 
            "todoist-appimage", "zen-browser-bin", "code"
        )]
        if desired:
            print()
            log("Installing packages...")
            # Record each desired name -> its real installed name so removal later is exact
            packages = dict(zip(desired, installer.install(desired)))

        local_packages = {}
        local_dirs = manifest.enabled_local_packages()
        if local_dirs:
            print()
            log("Building local packages...")
            local_packages = build_local_packages(installer, source, local_dirs)

        return installer, packages, local_packages

    def dereference_legacy(self, legacy_dir: Path | None) -> None:
        """Replace legacy symlinks with real copies of their targets."""

        symlinks = legacy_symlinks(legacy_dir)
        if not symlinks:
            return

        print()
        log("Preserving content from legacy symlinks...")
        for path in symlinks:
            target = path.resolve()
            if not target.exists():
                continue

            try:
                _deref_symlink(path, target)
                info(f"Copied {target} -> {path}")
            except OSError as e:
                warn(f"failed to preserve {path}: {e}")

    def deref_backup_syms(self, legacy_dir: Path | None) -> None:
        """Deref the backup's legacy symlinks before the repo is cleared, so the backup keeps real content."""

        if not config_backup_dir.is_dir():
            return

        for link in legacy_config_symlinks(config_backup_dir, legacy_dir):
            target = link.resolve()
            if not target.exists():
                continue

            try:
                _deref_symlink(link, target)
            except OSError as e:
                warn(f"failed to preserve {link} in backup: {e}")

    def migrate_legacy(self, installer: PackageInstaller, legacy_dir: Path | None) -> None:
        """Clean up a previous install.fish setup (repo, symlinks and metapackage)."""

        to_delete = legacy_to_delete(legacy_dir)
        meta_installed = installer.is_installed(LEGACY_META_PKG)
        if not to_delete and not meta_installed:
            return

        print()
        log("Found a legacy installation...")
        if not confirm("Clear legacy installation?"):
            return

        deployer = Deployer()
        try:
            self.deref_backup_syms(legacy_dir)
            for path in to_delete:
                deployer.remove(path)
                info(f"Deleted {path}")

            if meta_installed:
                log("Removing legacy meta package...")
                installer.remove([LEGACY_META_PKG])
        except (OSError, PackageError) as e:
            warn(f"could not fully clear the legacy installation: {e}")

    def print_done(self) -> None:
        print()
        info("All done! Nilastia has been installed successfully.")
        info("A few things to finish up:")
        info("  - A reboot/logout is recommended to apply GPU and Nice scheduler priorities.")
        info("  - Edit your compositor bindings in: ~/.config/niri/config.kdl")
        info("  - Run 'nilastia shell status' to check on shell services.")
        info("Enjoy your clean scrollable Wayland workspace!")
