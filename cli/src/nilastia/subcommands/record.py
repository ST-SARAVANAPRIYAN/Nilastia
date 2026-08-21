import re
import shutil
import subprocess
import time
from argparse import Namespace
from datetime import datetime
from pathlib import Path

from nilastia.utils import hypr
from nilastia.utils.notify import close_notification, notify
from nilastia.utils.paths import get_config, recording_notif_path, recording_path, recordings_dir

RECORDER = "gpu-screen-recorder"


class Command:
    args: Namespace

    def __init__(self, args: Namespace) -> None:
        self.args = args

    def run(self) -> None:
        if self.args.pause:
            subprocess.run(["pkill", "-USR2", "-f", RECORDER], stdout=subprocess.DEVNULL)
        elif self.proc_running():
            self.stop()
        else:
            self.start()

    def proc_running(self) -> bool:
        return subprocess.run(["pidof", RECORDER], stdout=subprocess.DEVNULL).returncode == 0

    def intersects(self, a: tuple[int, int, int, int], b: tuple[int, int, int, int]) -> bool:
        return a[0] < b[0] + b[2] and a[0] + a[2] > b[0] and a[1] < b[1] + b[3] and a[1] + a[3] > b[1]

    def start(self) -> None:
        import json
        import os
        args = ["-w"]

        is_hyprland = "HYPRLAND_INSTANCE_SIGNATURE" in os.environ
        if is_hyprland:
            monitors = hypr.message("monitors")
        else:
            try:
                outputs_data = json.loads(subprocess.check_output(["niri", "msg", "-j", "outputs"], text=True))
                focused_data = json.loads(subprocess.check_output(["niri", "msg", "-j", "focused-output"], text=True))
                monitors = []
                for name, out in outputs_data.items():
                    current_mode_idx = out.get("current_mode", 0)
                    mode = out.get("modes", [{}])[current_mode_idx]
                    refresh_rate = mode.get("refresh_rate", 60000) / 1000.0
                    logical = out.get("logical", {})
                    monitors.append({
                        "name": out.get("name", name),
                        "focused": out.get("name") == focused_data.get("name"),
                        "refreshRate": refresh_rate,
                        "x": logical.get("x", 0),
                        "y": logical.get("y", 0),
                        "width": logical.get("width", 1920),
                        "height": logical.get("height", 1080)
                    })
            except Exception:
                monitors = [{
                    "name": "eDP-1",
                    "focused": True,
                    "refreshRate": 60.0,
                    "x": 0,
                    "y": 0,
                    "width": 1920,
                    "height": 1080
                }]

        if self.args.region:
            if self.args.region == "slurp":
                region = subprocess.check_output(["slurp", "-f", "%wx%h+%x+%y"], text=True)
            else:
                region = self.args.region.strip()
            args += ["region", "-region", region]

            m = re.match(r"(\d+)x(\d+)\+(-?\d+)\+(-?\d+)", region)
            if not m:
                raise ValueError(f"Invalid region: {region}")

            w, h, x, y = map(int, m.groups())
            r = x, y, w, h
            max_rr = 0
            for monitor in monitors:
                if self.intersects((monitor["x"], monitor["y"], monitor["width"], monitor["height"]), r):
                    rr = round(monitor["refreshRate"])
                    max_rr = max(max_rr, rr)
            args += ["-f", str(max_rr)]
        else:
            focused_monitor = next((monitor for monitor in monitors if monitor["focused"]), None)
            if not focused_monitor and monitors:
                focused_monitor = monitors[0]
            if focused_monitor:
                args += [focused_monitor["name"], "-f", str(round(focused_monitor["refreshRate"]))]

        if self.args.sound:
            args += ["-a", "default_output"]

        config = get_config()
        try:
            if "record" in config and "extraArgs" in config["record"]:
                args += config["record"]["extraArgs"]
        except TypeError as e:
            raise ValueError(f"Config option 'record.extraArgs' should be an array: {e}")

        recording_path.parent.mkdir(parents=True, exist_ok=True)
        proc = subprocess.Popen([RECORDER, *args, "-o", str(recording_path)], start_new_session=True)

        notif = notify("-p", "Recording started", "Recording...")
        recording_notif_path.write_text(notif)

        try:
            if proc.wait(1) != 0:
                close_notification(notif)
                notify(
                    "Recording failed",
                    "An error occurred attempting to start recorder. "
                    f"Command `{' '.join(proc.args)}` failed with exit code {proc.returncode}",
                )
        except subprocess.TimeoutExpired:
            pass

    def stop(self) -> None:
        # Start killing recording process
        subprocess.run(["pkill", "-f", RECORDER], stdout=subprocess.DEVNULL)

        # Wait for recording to finish to avoid corrupted video file
        while self.proc_running():
            time.sleep(0.1)

        # Move to recordings folder
        new_path = recordings_dir / f"recording_{datetime.now().strftime('%Y%m%d_%H-%M-%S')}.mp4"
        recordings_dir.mkdir(exist_ok=True, parents=True)
        shutil.move(recording_path, new_path)

        # Close start notification
        try:
            close_notification(recording_notif_path.read_text())
        except IOError:
            pass

        if self.args.clipboard:
            file_uri = Path(new_path).resolve().as_uri() + "\n"
            subprocess.run(["wl-copy", "--type", "text/uri-list"], input=file_uri.encode())

        action = notify(
            "--action=watch=Watch",
            "--action=open=Open",
            "--action=delete=Delete",
            "Recording stopped",
            f"Recording saved in {new_path}",
        )

        if action == "watch":
            subprocess.Popen(["xdg-open", new_path], start_new_session=True)
        elif action == "open":
            p = subprocess.run(
                [
                    "dbus-send",
                    "--session",
                    "--dest=org.freedesktop.FileManager1",
                    "--type=method_call",
                    "/org/freedesktop/FileManager1",
                    "org.freedesktop.FileManager1.ShowItems",
                    f"array:string:file://{new_path}",
                    "string:",
                ]
            )
            if p.returncode != 0:
                subprocess.Popen(["xdg-open", new_path.parent], start_new_session=True)
        elif action == "delete":
            new_path.unlink()
