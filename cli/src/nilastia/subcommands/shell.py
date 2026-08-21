import subprocess
import sys
from argparse import Namespace

from nilastia.utils.paths import c_cache_dir
from nilastia.utils.io import info, log, warn

class Command:
    args: Namespace

    def __init__(self, args: Namespace) -> None:
        self.args = args

    def run(self) -> None:
        if self.args.message:
            action = self.args.message[0].lower()
            if action in ("start", "stop", "restart", "status"):
                self.manage_service(action)
                return
            elif action == "reload":
                log("Reloading Quickshell configuration...")
                try:
                    self.shell("reload")
                    info("Shell reloaded successfully.")
                except Exception as e:
                    warn(f"Failed to reload shell: {e}")
                return
            elif action in ("log", "logs"):
                self.print_systemd_log()
                return
            else:
                # Send a standard IPC message
                self.message(*self.args.message)
                return

        if self.args.show:
            self.print_ipc()
        elif self.args.log:
            self.print_log()
        elif self.args.kill:
            self.shell("kill")
        else:
            # Start the shell directly
            args = ["qs", "-c", "niri-nilastia-shell", "-n"]
            if self.args.log_rules:
                args.extend(["--log-rules", self.args.log_rules])
            if self.args.daemon:
                args.append("-d")
                subprocess.run(args)
            else:
                shell = subprocess.Popen(args, stdout=subprocess.PIPE, universal_newlines=True)

                if shell.stdout:
                    for line in shell.stdout:
                        if self.filter_log(line):
                            print(line, end="")

    def manage_service(self, action: str) -> None:
        service_name = "niri-nilastia-shell.service"
        if action == "status":
            info(f"=== Service Status: {service_name} ===")
            subprocess.run(["systemctl", "--user", "status", service_name])
            print()
            info("=== Service Status: niri.service ===")
            subprocess.run(["systemctl", "--user", "status", "niri.service"])
        else:
            log(f"Running systemctl --user {action} {service_name}...")
            res = subprocess.run(["systemctl", "--user", action, service_name])
            if res.returncode == 0:
                info(f"Successfully executed {action} on {service_name}")
            else:
                warn(f"Failed to execute {action} on {service_name}")

    def print_systemd_log(self) -> None:
        service_name = "niri-nilastia-shell.service"
        log(f"Tailing journalctl logs for {service_name} (Press Ctrl+C to exit)...")
        try:
            subprocess.run(["journalctl", "--user", "-f", "-u", service_name])
        except KeyboardInterrupt:
            print()
            info("Log tail stopped.")

    def shell(self, *args: str) -> str:
        return subprocess.check_output(["qs", "-c", "niri-nilastia-shell", *args], text=True)

    def filter_log(self, line: str) -> bool:
        return f"Cannot open: file://{c_cache_dir}/imagecache/" not in line

    def print_ipc(self) -> None:
        print(self.shell("ipc", "show"), end="")

    def print_log(self) -> None:
        if self.args.log_rules:
            log_out = self.shell("log", "-r", self.args.log_rules)
        else:
            log_out = self.shell("log")
        for line in log_out.splitlines():
            if self.filter_log(line):
                print(line)

    def message(self, *args: str) -> None:
        try:
            print(self.shell("ipc", "call", *args), end="")
        except subprocess.CalledProcessError as e:
            warn(f"Failed to send IPC message to Quickshell: {e.output.strip() if e.output else e}")
            warn("Is the shell currently running?")
