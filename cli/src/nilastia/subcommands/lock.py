import subprocess
from argparse import Namespace


class Command:
    def __init__(self, args: Namespace) -> None:
        self.args = args

    def run(self) -> None:
        subprocess.run(["quickshell", "-c", "niri-nilastia-shell", "ipc", "call", "lock", "lock"])
