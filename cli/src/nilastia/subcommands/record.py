import json
import os
import re
import shutil
import signal
import subprocess
import time
from argparse import Namespace
from datetime import datetime
from pathlib import Path

from nilastia.utils import hypr
from nilastia.utils.notify import close_notification, notify
from nilastia.utils.paths import get_config, recording_notif_path, recording_path, recordings_dir

RECORDERS = ["wf-recorder", "gpu-screen-recorder"]


def is_nvidia_available() -> bool:
    return Path("/dev/nvidia0").exists() and (
        shutil.which("nvidia-smi") is not None or Path("/usr/share/glvnd/egl_vendor.d/10_nvidia.json").exists()
    )


def get_running_recorder() -> tuple[str, int] | None:
    for rec in RECORDERS:
        try:
            out = subprocess.check_output(["pidof", rec], text=True).strip()
            if out:
                pid = int(out.split()[0])
                return rec, pid
        except (subprocess.CalledProcessError, ValueError):
            continue
    return None


class Command:
    args: Namespace

    def __init__(self, args: Namespace) -> None:
        self.args = args

    def run(self) -> None:
        if self.args.stop:
            if self.proc_running():
                self.stop()
            else:
                subprocess.run(["pkill", "-INT", "-f", "^(wf-recorder|gpu-screen-recorder)"], stdout=subprocess.DEVNULL)
            return
        if self.args.start:
            if not self.proc_running():
                self.start()
            return
        if self.args.pause:
            running = get_running_recorder()
            if running:
                rec_name, pid = running
                if rec_name == "wf-recorder":
                    try:
                        state = subprocess.check_output(["ps", "-o", "state=", "-p", str(pid)], text=True).strip()
                        sig = signal.SIGCONT if state.startswith("T") else signal.SIGSTOP
                        os.kill(pid, sig)
                    except Exception:
                        pass
                else:
                    subprocess.run(["pkill", "-USR2", "-f", rec_name], stdout=subprocess.DEVNULL)
        elif self.proc_running():
            self.stop()
        else:
            self.start()

    def proc_running(self) -> bool:
        return get_running_recorder() is not None

    def intersects(self, a: tuple[int, int, int, int], b: tuple[int, int, int, int]) -> bool:
        return a[0] < b[0] + b[2] and a[0] + a[2] > b[0] and a[1] < b[1] + b[3] and a[1] + a[3] > b[1]

    def start(self) -> None:
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
                        "height": logical.get("height", 1080),
                    })
            except Exception:
                monitors = [{
                    "name": "eDP-1",
                    "focused": True,
                    "refreshRate": 60.0,
                    "x": 0,
                    "y": 0,
                    "width": 1920,
                    "height": 1080,
                }]

        focused_monitor = next((monitor for monitor in monitors if monitor["focused"]), None)
        if not focused_monitor and monitors:
            focused_monitor = monitors[0]

        target_fps = round(focused_monitor["refreshRate"]) if focused_monitor else 60
        wf_geometry = None
        gsr_region = None

        if self.args.region:
            if self.args.region == "slurp":
                try:
                    raw_region = subprocess.check_output(["slurp", "-f", "%wx%h+%x+%y"], text=True).strip()
                except subprocess.CalledProcessError:
                    return
            else:
                raw_region = self.args.region.strip()

            m = re.match(r"(\d+)x(\d+)\+(-?\d+)\+(-?\d+)", raw_region)
            if not m:
                raise ValueError(f"Invalid region: {raw_region}")

            w, h, x, y = map(int, m.groups())
            region_rect = (x, y, w, h)
            wf_geometry = f"{x},{y} {w}x{h}"
            gsr_region = raw_region

            max_rr = 0
            for monitor in monitors:
                if self.intersects((monitor["x"], monitor["y"], monitor["width"], monitor["height"]), region_rect):
                    rr = round(monitor["refreshRate"])
                    max_rr = max(max_rr, rr)
            if max_rr > 0:
                target_fps = max_rr

        config = get_config()
        record_cfg = config.get("record", {}) if isinstance(config, dict) else {}

        # Resolve quality preset: default to 'very_high' to guarantee crystal clear recordings
        quality = getattr(self.args, "quality", None) or record_cfg.get("quality", "very_high")
        if quality not in ("medium", "high", "very_high", "ultra"):
            quality = "very_high"

        # Resolve GPU choice
        gpu_choice = getattr(self.args, "gpu", None) or record_cfg.get("gpu", "auto")

        # Resolve backend choice
        backend_choice = getattr(self.args, "backend", None) or record_cfg.get("backend", "auto")

        has_nvidia = is_nvidia_available()
        has_wf = shutil.which("wf-recorder") is not None
        has_gsr = shutil.which("gpu-screen-recorder") is not None

        # On hybrid laptops (Intel display KMS):
        # - gpu-screen-recorder on Intel iGPU captures directly from KMS with zero-copy and 0% CPU at 144 FPS.
        # - wf-recorder (wlr-screencopy) handles NVIDIA NVENC hardware encoding without DRM KMS modifier mismatches.
        if backend_choice == "auto":
            if gpu_choice == "nvidia":
                backend = "wf-recorder" if has_wf else "gpu-screen-recorder"
            elif has_gsr:
                backend = "gpu-screen-recorder"
            elif has_wf:
                backend = "wf-recorder"
            else:
                backend = "gpu-screen-recorder"
        else:
            backend = backend_choice

        use_nvidia = (gpu_choice == "nvidia") or (
            gpu_choice == "auto" and backend == "wf-recorder" and has_nvidia
        )

        proc_env = os.environ.copy()
        if use_nvidia:
            # Strip variables that lock graphics/compute to Intel/Mesa (e.g. from niri-nilastia-shell.service)
            for var in (
                "__EGL_VENDOR_LIBRARY_FILENAMES",
                "VK_DRIVER_FILES",
                "LIBVA_DRIVER_NAME",
                "VDPAU_DRIVER",
                "NVIDIA_VISIBLE_DEVICES",
                "CUDA_VISIBLE_DEVICES",
                "CUDA_DISABLE_PERF_BOOST",
                "WLR_RENDER_DRM_DEVICE",
                "INIR_GPU_POLICY",
            ):
                proc_env.pop(var, None)

            proc_env["__NV_PRIME_RENDER_OFFLOAD"] = "1"
            proc_env["__GLX_VENDOR_LIBRARY_NAME"] = "nvidia"
            proc_env["__VK_LAYER_NV_optimus"] = "NVIDIA_only"
        else:
            # Native Intel KMS capture requires unpolluted environment without forced NVIDIA offload
            proc_env.pop("__NV_PRIME_RENDER_OFFLOAD", None)
            proc_env.pop("__GLX_VENDOR_LIBRARY_NAME", None)
            proc_env.pop("__VK_LAYER_NV_optimus", None)

        codec = getattr(self.args, "codec", None) or record_cfg.get("codec")

        cmd = []
        if backend == "wf-recorder":
            cmd = ["wf-recorder", "-y"]
            if wf_geometry:
                cmd += ["-g", wf_geometry]
            elif focused_monitor:
                cmd += ["-o", focused_monitor["name"]]

            cmd += ["-r", str(target_fps)]

            if self.args.sound:
                cmd += ["-a"]

            # Output standard high-definition BT.709 colorimetry
            cmd += [
                "-x", "yuv420p",
                "-p", "color_primaries=bt709",
                "-p", "color_trc=bt709",
                "-p", "colorspace=bt709",
            ]

            if use_nvidia:
                codec_map = {"h264": "h264_nvenc", "hevc": "hevc_nvenc", "av1": "av1_nvenc"}
                nv_codec = codec_map.get(codec, "h264_nvenc")
                cmd += ["-c", nv_codec]

                quality_nvenc_map = {
                    "ultra": {"cq": "14", "b": "50M", "maxrate": "80M", "bufsize": "100M", "preset": "p6"},
                    "very_high": {"cq": "18", "b": "35M", "maxrate": "50M", "bufsize": "60M", "preset": "p5"},
                    "high": {"cq": "22", "b": "20M", "maxrate": "35M", "bufsize": "40M", "preset": "p5"},
                    "medium": {"cq": "26", "b": "12M", "maxrate": "20M", "bufsize": "25M", "preset": "p4"},
                }
                params = quality_nvenc_map.get(quality, quality_nvenc_map["very_high"])
                cmd += [
                    "-p", f"preset={params['preset']}",
                    "-p", "tune=hq",
                    "-p", "rc=vbr",
                    "-p", f"cq={params['cq']}",
                    "-p", f"b={params['b']}",
                    "-p", f"maxrate={params['maxrate']}",
                    "-p", f"bufsize={params['bufsize']}",
                ]
            else:
                codec_map = {"h264": "h264_vaapi", "hevc": "hevc_vaapi"}
                va_codec = codec_map.get(codec, "h264_vaapi")
                cmd += ["-c", va_codec, "-d", "/dev/dri/renderD128"]
                quality_vaapi_map = {
                    "ultra": {"qp": "14", "b": "50M"},
                    "very_high": {"qp": "18", "b": "35M"},
                    "high": {"qp": "22", "b": "20M"},
                    "medium": {"qp": "26", "b": "12M"},
                }
                params = quality_vaapi_map.get(quality, quality_vaapi_map["very_high"])
                cmd += [
                    "-p", f"qp={params['qp']}",
                    "-p", f"b={params['b']}",
                ]

            try:
                if "extraArgs" in record_cfg:
                    cmd += record_cfg["extraArgs"]
            except TypeError as e:
                raise ValueError(f"Config option 'record.extraArgs' should be an array: {e}")

            cmd += ["-f", str(recording_path)]
        else:
            # gpu-screen-recorder
            cmd = ["gpu-screen-recorder", "-w"]
            if gsr_region:
                cmd += ["region", "-region", gsr_region, "-f", str(target_fps)]
            elif focused_monitor:
                cmd += [focused_monitor["name"], "-f", str(target_fps)]
            else:
                cmd += ["screen", "-f", str(target_fps)]

            if self.args.sound:
                cmd += ["-a", "default_output"]

            if codec and codec != "auto":
                cmd += ["-k", codec]

            cmd += ["-q", quality, "-tune", "quality", "-fallback-cpu-encoding", "yes"]

            try:
                if "extraArgs" in record_cfg:
                    cmd += record_cfg["extraArgs"]
            except TypeError as e:
                raise ValueError(f"Config option 'record.extraArgs' should be an array: {e}")

            cmd += ["-o", str(recording_path)]

        recording_path.parent.mkdir(parents=True, exist_ok=True)
        log_path = recording_path.parent / "recorder.log"
        log_file = open(log_path, "wb")

        proc = subprocess.Popen(
            cmd,
            env=proc_env,
            start_new_session=True,
            stdout=log_file,
            stderr=log_file,
            stdin=subprocess.DEVNULL,
        )

        gpu_label = "NVIDIA NVENC" if use_nvidia else "Intel VA-API"
        notif = notify("-p", "Recording started", f"Recording in {quality} quality ({gpu_label} via {backend})...")
        recording_notif_path.write_text(notif)

        time.sleep(0.15)
        if proc.poll() is not None:
            close_notification(notif)
            notify(
                "Recording failed",
                "An error occurred attempting to start recorder. "
                f"Command `{' '.join(proc.args)}` failed with exit code {proc.returncode}",
            )

    def stop(self) -> None:
        running = get_running_recorder()
        if running:
            rec_name, pid = running
            try:
                os.kill(pid, signal.SIGINT)
            except Exception:
                subprocess.run(["pkill", "-INT", "-f", rec_name], stdout=subprocess.DEVNULL)

        # Stop any and all recorders cleanly
        subprocess.run(["pkill", "-INT", "-f", "^(wf-recorder|gpu-screen-recorder)"], stdout=subprocess.DEVNULL)

        # Wait for recorder to finalize file (up to 4 seconds)
        timeout = time.time() + 4.0
        while self.proc_running() and time.time() < timeout:
            time.sleep(0.05)

        if self.proc_running():
            subprocess.run(["pkill", "-9", "-f", "^(wf-recorder|gpu-screen-recorder)"], stdout=subprocess.DEVNULL)

        new_path = recordings_dir / f"recording_{datetime.now().strftime('%Y%m%d_%H-%M-%S')}.mp4"
        recordings_dir.mkdir(exist_ok=True, parents=True)
        if recording_path.exists():
            shutil.move(recording_path, new_path)

        try:
            close_notification(recording_notif_path.read_text())
        except IOError:
            pass

        if self.args.clipboard:
            file_uri = Path(new_path).resolve().as_uri() + "\n"
            subprocess.run(["wl-copy", "--type", "text/uri-list"], input=file_uri.encode())

        # Spawn notification handler in a detached process so stop() returns immediately without blocking
        helper_code = f"""
import subprocess, sys
from pathlib import Path
new_path = Path({repr(str(new_path))})
try:
    action = subprocess.check_output([
        "notify-send", "-a", "caelestia-cli",
        "--action=watch=Watch",
        "--action=open=Open",
        "--action=delete=Delete",
        "Recording stopped",
        f"Recording saved in {{new_path}}",
    ], text=True).strip()
    if action == "watch":
        subprocess.Popen(["xdg-open", str(new_path)], start_new_session=True)
    elif action == "open":
        p = subprocess.run([
            "dbus-send", "--session",
            "--dest=org.freedesktop.FileManager1",
            "--type=method_call",
            "/org/freedesktop/FileManager1",
            "org.freedesktop.FileManager1.ShowItems",
            f"array:string:file://{{new_path}}",
            "string:",
        ])
        if p.returncode != 0:
            subprocess.Popen(["xdg-open", str(new_path.parent)], start_new_session=True)
    elif action == "delete":
        new_path.unlink(missing_ok=True)
except Exception:
    pass
"""
        subprocess.Popen(
            ["python", "-c", helper_code],
            start_new_session=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            stdin=subprocess.DEVNULL,
        )
