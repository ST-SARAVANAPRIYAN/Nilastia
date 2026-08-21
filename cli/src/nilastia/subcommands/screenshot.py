import subprocess
from argparse import Namespace
from datetime import datetime

from nilastia.utils import hypr
from nilastia.utils.notify import notify
from nilastia.utils.paths import screenshots_cache_dir, screenshots_dir


class Command:
    args: Namespace

    def __init__(self, args: Namespace) -> None:
        self.args = args

    def run(self) -> None:
        if self.args.region:
            self.region()
        else:
            self.fullscreen()

    def region(self) -> None:
        if self.args.region == "slurp":
            subprocess.run(
                ["qs", "-c", "niri-nilastia-shell", "ipc", "call", "picker", "openFreeze" if self.args.freeze else "open"]
            )
        else:
            sc_data = subprocess.check_output(["grim", "-l", "0", "-g", self.args.region.strip(), "-"])
            swappy = subprocess.Popen(["swappy", "-f", "-"], stdin=subprocess.PIPE, start_new_session=True)

            # Ensure stdin is not None for the type checker
            if swappy.stdin:
                swappy.stdin.write(sc_data)
                swappy.stdin.close()

    def fullscreen(self) -> None:
        import json
        import os
        cmd = ["grim"]
        is_hyprland = "HYPRLAND_INSTANCE_SIGNATURE" in os.environ
        focused_name = None
        if is_hyprland:
            try:
                focused_monitor = next(monitor for monitor in hypr.message("monitors") if monitor["focused"])
                focused_name = focused_monitor["name"]
            except Exception:
                pass
        else:
            try:
                focused_data = json.loads(subprocess.check_output(["niri", "msg", "-j", "focused-output"], text=True))
                focused_name = focused_data.get("name")
            except Exception:
                pass

        if focused_name:
            cmd += ["-o", focused_name]
        cmd += ["-"]
        sc_data = subprocess.check_output(cmd)

        subprocess.run(["wl-copy"], input=sc_data)

        dest = screenshots_cache_dir / datetime.now().strftime("%Y%m%d%H%M%S")
        screenshots_cache_dir.mkdir(exist_ok=True, parents=True)
        dest.write_bytes(sc_data)

        action = notify(
            "-i",
            "image-x-generic-symbolic",
            "-h",
            f"STRING:image-path:{dest}",
            "--action=open=Open",
            "--action=save=Save",
            "Screenshot taken",
            f"Screenshot stored in {dest} and copied to clipboard",
        )

        if action == "open":
            subprocess.Popen(["swappy", "-f", dest], start_new_session=True)
        elif action == "save":
            new_dest = (screenshots_dir / dest.name).with_suffix(".png")
            new_dest.parent.mkdir(exist_ok=True, parents=True)
            dest.rename(new_dest)
            notify("Screenshot saved", f"Saved to {new_dest}")
