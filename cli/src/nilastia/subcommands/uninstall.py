import shutil
import subprocess
from argparse import Namespace
from pathlib import Path

from nilastia.utils.io import confirm, fatal, info, log, warn
from nilastia.utils.paths import config_dir, cache_dir

class Command:
    args: Namespace

    def __init__(self, args: Namespace) -> None:
        self.args = args

    def run(self) -> None:
        info("=== Nilastia Uninstallation Utility ===")
        warn("This will remove your Nilastia and Niri configurations and services!")
        
        # 1. Prompt for configuration backup before deleting
        if confirm("Would you like to create a backup of your configuration before uninstalling?", default=True):
            from nilastia.subcommands.backup import Command as BackupCommand
            BackupCommand(Namespace(action="create", name="pre_uninstall")).run()
            
        if not confirm("Are you sure you want to proceed with full uninstallation?", default=False):
            info("Uninstallation cancelled.")
            return

        # 2. Stop and disable systemd services
        log("Disabling and stopping Nilastia user services...")
        try:
            subprocess.run(["systemctl", "--user", "disable", "--now", "niri-nilastia-shell.service"], check=False)
            subprocess.run(["systemctl", "--user", "disable", "--now", "niri.service"], check=False)
        except Exception as e:
            warn(f"  Could not stop/disable systemd services: {e}")

        # 3. Clean files in config
        log("Removing configuration files...")
        folders_to_clean = [
            config_dir / "niri",
            config_dir / "quickshell" / "niri-nilastia-shell",
            config_dir / "quickshell" / "niri-caelestia-shell",
            config_dir / "nilastia",
        ]
        for path in folders_to_clean:
            if path.exists():
                try:
                    if path.is_symlink() or path.is_file():
                        path.unlink()
                    elif path.is_dir():
                        shutil.rmtree(path)
                    info(f"  Removed: {path.relative_to(Path.home()) if Path.home() in path.parents else path}")
                except Exception as e:
                    warn(f"  Failed to remove {path}: {e}")

        # 4. Remove XDG session desktop entry
        session_file = Path("/usr/share/wayland-sessions/niri.desktop")
        if session_file.exists():
            log("Removing Niri session desktop entry (requires root)...")
            try:
                subprocess.run(["sudo", "rm", str(session_file)], check=True)
                info("  Removed Niri session desktop entry.")
            except Exception as e:
                warn(f"  Failed to remove session desktop entry: {e}")

        # 5. Clean systemd files
        service_files = [
            config_dir / "systemd" / "user" / "niri-nilastia-shell.service",
            config_dir / "systemd" / "user" / "niri.service.d" / "override.conf",
        ]
        for file in service_files:
            if file.exists():
                try:
                    file.unlink()
                    info(f"  Removed: {file.relative_to(Path.home())}")
                except Exception as e:
                    warn(f"  Failed to remove service file {file}: {e}")

        # Reload systemd user daemon
        subprocess.run(["systemctl", "--user", "daemon-reload"], check=False)

        # 6. Global command clean suggestion
        global_bin = Path.home() / ".local/bin" / "nilastia"
        if global_bin.exists():
            if confirm("Would you like to remove the global 'nilastia' command executable from ~/.local/bin?", default=True):
                try:
                    global_bin.unlink()
                    info("  Removed global 'nilastia' command.")
                except Exception as e:
                    warn(f"  Failed to remove global command: {e}")

        info("Nilastia uninstallation completed successfully.")
