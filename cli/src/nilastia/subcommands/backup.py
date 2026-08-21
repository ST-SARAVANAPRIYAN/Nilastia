import os
import tarfile
import shutil
from argparse import Namespace
from datetime import datetime
from pathlib import Path

from nilastia.utils.io import confirm, fatal, info, log, warn
from nilastia.utils.paths import cache_dir, config_dir

class Command:
    args: Namespace

    def __init__(self, args: Namespace) -> None:
        self.args = args
        self.backup_root = cache_dir / "nilastia" / "backups"

    def run(self) -> None:
        self.backup_root.mkdir(parents=True, exist_ok=True)

        if self.args.action == "create":
            self.create_backup(self.args.name)
        elif self.args.action == "list":
            self.list_backups()
        elif self.args.action == "restore":
            if not self.args.name:
                fatal("Please specify a backup name to restore using --name <backup_name>")
            self.restore_backup(self.args.name)
        else:
            fatal("Invalid backup action. Choose from: create, list, restore")

    def create_backup(self, custom_name: str | None) -> None:
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        name = custom_name if custom_name else f"backup_{timestamp}"
        archive_path = self.backup_root / f"{name}.tar.gz"

        log(f"Creating snapshot archive: {archive_path.name}...")

        targets = [
            ("config/niri", config_dir / "niri"),
            ("config/quickshell", config_dir / "quickshell"),
            ("config/caelestia", config_dir / "nilastia"),
        ]

        active_targets = [(arcname, path) for arcname, path in targets if path.exists()]
        if not active_targets:
            fatal("No configuration directories found to back up!")

        try:
            with tarfile.open(archive_path, "w:gz") as tar:
                for arcname, path in active_targets:
                    log(f"  Archiving {path.relative_to(Path.home())}...")
                    tar.add(path, arcname=arcname)
            info(f"Successfully created backup: {archive_path.name}")
        except Exception as e:
            if archive_path.exists():
                archive_path.unlink()
            fatal(f"Failed to create backup archive: {e}")

    def list_backups(self) -> None:
        backups = sorted(self.backup_root.glob("*.tar.gz"), key=os.path.getmtime, reverse=True)
        if not backups:
            info("No backups found.")
            return

        info("Available configuration backups:")
        print(f"  {'Backup Name':<30} | {'Created At':<20} | {'Size':<10}")
        print("  " + "-" * 70)
        for path in backups:
            mtime = datetime.fromtimestamp(path.stat().st_mtime).strftime("%Y-%m-%d %H:%M:%S")
            size_mb = path.stat().st_size / (1024 * 1024)
            print(f"  {path.stem:<30} | {mtime:<20} | {size_mb:.2f} MB")

    def restore_backup(self, name: str) -> None:
        archive_path = self.backup_root / f"{name}.tar.gz"
        if not archive_path.exists():
            # Try adding extension in case the user omitted it
            if (self.backup_root / f"{name}").exists():
                archive_path = self.backup_root / f"{name}"
            else:
                fatal(f"Backup '{name}' not found under {self.backup_root}")

        warn(f"Restoring this backup will overwrite your current Niri, Quickshell, and Caelestia configs!")
        if not confirm("Are you sure you want to proceed with restore?", default=False):
            info("Restore cancelled.")
            return

        log(f"Extracting {archive_path.name} to {config_dir}...")
        try:
            with tarfile.open(archive_path, "r:gz") as tar:
                # Pre-clean the directories we are going to restore to prevent mixing old and new files
                for member in tar.getmembers():
                    # member.name is like "config/niri/...", map it to local Path
                    parts = Path(member.name).parts
                    if len(parts) >= 2 and parts[0] == "config":
                        dest_dir = config_dir / parts[1]
                        if dest_dir.exists():
                            log(f"  Cleaning old directory {dest_dir.name}...")
                            shutil.rmtree(dest_dir)
                
                # Now extract
                # We extract to a temporary folder or extract members mapped to config_dir
                for member in tar.getmembers():
                    parts = Path(member.name).parts
                    if len(parts) >= 2 and parts[0] == "config":
                        # Strip the "config/" prefix from member name
                        member.name = str(Path(*parts[1:]))
                        tar.extract(member, path=config_dir)

            info("Restore completed successfully!")
            
            # Offer to restart quickshell
            if confirm("Restart Quickshell service now to apply restored configurations?", default=True):
                log("Restarting quickshell...")
                import subprocess
                subprocess.run(["systemctl", "--user", "restart", "niri-nilastia-shell.service"])
        except Exception as e:
            fatal(f"Failed to restore backup: {e}")
