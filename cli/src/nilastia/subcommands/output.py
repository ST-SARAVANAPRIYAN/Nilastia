import os
import re
import subprocess
from argparse import Namespace

class Command:
    args: Namespace

    def __init__(self, args: Namespace) -> None:
        self.args = args

    def _resolve_config_path(self) -> str:
        # 1. Direct environment variable
        env_path = os.environ.get("NIRI_CONFIG")
        if env_path and os.path.exists(env_path):
            return env_path

        # 2. Systemd user manager environment
        try:
            res = subprocess.run(
                ["systemctl", "--user", "show-environment"],
                capture_output=True,
                text=True,
                timeout=1
            )
            for line in res.stdout.splitlines():
                if line.startswith("NIRI_CONFIG="):
                    val = line.split("=", 1)[1].strip()
                    if val and os.path.exists(val):
                        return val
        except Exception:
            pass

        # 3. Running niri process environment
        try:
            pids = subprocess.check_output(["pgrep", "-x", "niri"], text=True).strip().split()
            for pid in pids:
                env_file = f"/proc/{pid}/environ"
                if os.path.exists(env_file):
                    with open(env_file, "rb") as f:
                        env_data = f.read().decode("utf-8", errors="ignore")
                        for item in env_data.split("\0"):
                            if item.startswith("NIRI_CONFIG="):
                                val = item.split("=", 1)[1].strip()
                                if val and os.path.exists(val):
                                    return val
        except Exception:
            pass

        return os.path.expanduser("~/.config/niri/config.kdl")

    def run(self) -> None:
        config_path = self._resolve_config_path()
        if not os.path.exists(config_path):
            print(f"Error: Niri config not found at {config_path}")
            return

        with open(config_path, "r") as f:
            content = f.read()

        name = self.args.name

        # Parse existing block settings if the block exists
        existing_mode = None
        existing_scale = None
        existing_vrr = False
        existing_off = False

        block_pattern = rf'output\s+"{re.escape(name)}"\s*\{{([^}}]*)\}}'
        match = re.search(block_pattern, content)
        if match:
            block_content = match.group(1)
            # Find mode
            mode_match = re.search(r'mode\s+"([^"]+)"', block_content)
            if mode_match:
                existing_mode = mode_match.group(1)
            # Find scale
            scale_match = re.search(r'scale\s+([0-9.]+)', block_content)
            if scale_match:
                existing_scale = scale_match.group(1)
            # Find vrr
            if "variable-refresh-rate" in block_content:
                existing_vrr = True
            # Find off
            if "off" in block_content:
                existing_off = True

        # Override properties only if passed in CLI args
        status = getattr(self.args, "status", None)
        if status == "off":
            off = True
        elif status == "on":
            off = False
        else:
            off = existing_off

        if self.args.mode is not None:
            mode = self.args.mode
        else:
            mode = existing_mode

        if self.args.scale is not None:
            scale = self.args.scale
        else:
            scale = existing_scale

        vrr_arg = getattr(self.args, "vrr", None)
        if vrr_arg is not None:
            vrr = vrr_arg
        else:
            vrr = existing_vrr

        # Execute runtime IPC calls immediately so changes take effect without restart
        try:
            if status == "off":
                subprocess.run(["niri", "msg", "output", name, "off"], check=False)
            elif status == "on":
                subprocess.run(["niri", "msg", "output", name, "on"], check=False)

            if not off:
                if mode:
                    subprocess.run(["niri", "msg", "output", name, "mode", mode], check=False)
                if scale is not None:
                    subprocess.run(["niri", "msg", "output", name, "scale", str(scale)], check=False)
                if vrr_arg is not None:
                    vrr_mode = "on" if vrr else "off"
                    subprocess.run(["niri", "msg", "output", name, "vrr", vrr_mode], check=False)
        except Exception as e:
            print(f"Warning: Failed to apply live Niri IPC output settings: {e}")

        # Helper to construct an output block
        def build_block(target_name: str) -> str:
            lines = [f'output "{target_name}" {{']
            if off:
                lines.append("    off")
            else:
                if mode:
                    lines.append(f'    mode "{mode}"')
                if scale is not None:
                    lines.append(f'    scale {scale}')
                if vrr:
                    lines.append("    variable-refresh-rate")
            lines.append("}")
            return "\n".join(lines)

        # Build the new block content for target output
        new_block = build_block(name)

        # Replace or append the output configuration block
        if match:
            content = re.sub(block_pattern, new_block, content)
            print(f"Updated output '{name}' in {os.path.basename(config_path)}")
        else:
            content = content.rstrip() + "\n\n" + new_block + "\n"
            print(f"Added output '{name}' to {os.path.basename(config_path)}")

        # If configuring eDP-1 or eDP-2, keep any existing sibling eDP output blocks synced
        if re.match(r"^eDP-\d+$", name):
            sibling = "eDP-2" if name == "eDP-1" else "eDP-1"
            sibling_pattern = rf'output\s+"{re.escape(sibling)}"\s*\{{([^}}]*)\}}'
            if re.search(sibling_pattern, content):
                content = re.sub(sibling_pattern, build_block(sibling), content)
                print(f"Synchronized sibling output '{sibling}' in {os.path.basename(config_path)}")

        with open(config_path, "w") as f:
            f.write(content)
