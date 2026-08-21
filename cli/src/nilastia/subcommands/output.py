import os
import re
from argparse import Namespace

class Command:
    args: Namespace

    def __init__(self, args: Namespace) -> None:
        self.args = args

    def run(self) -> None:
        config_path = os.path.expanduser("~/.config/niri/config.kdl")
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

        # Build the new block content
        block_lines = [f'output "{name}" {{']
        if off:
            block_lines.append("    off")
        else:
            if mode:
                block_lines.append(f'    mode "{mode}"')
            if scale is not None:
                block_lines.append(f'    scale {scale}')
            if vrr:
                block_lines.append("    variable-refresh-rate")
        block_lines.append("}")
        new_block = "\n".join(block_lines)

        # Replace or append the output configuration block
        if match:
            content = re.sub(block_pattern, new_block, content)
            print(f"Updated output '{name}' in config.kdl")
        else:
            content = content.rstrip() + "\n\n" + new_block + "\n"
            print(f"Added output '{name}' to config.kdl")

        with open(config_path, "w") as f:
            f.write(content)
