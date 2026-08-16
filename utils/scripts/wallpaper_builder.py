#!/usr/bin/env python3
import sys
import os
import json
import shutil
import argparse
from pathlib import Path

def clean_filename(name: str) -> str:
    return "".join(c for c in name if c.isalnum() or c in ("-", "_", ".")).strip()

def main():
    parser = argparse.ArgumentParser(description="Create custom parallax wallpaper theme")
    parser.add_argument("--name", required=True, help="Theme name")
    parser.add_argument("--stiffness", type=float, default=2.0)
    parser.add_argument("--damping", type=float, default=0.8)
    parser.add_argument("--max-x", type=float, default=35.0)
    parser.add_argument("--max-y", type=float, default=20.0)
    parser.add_argument("--layers", required=True, help="JSON array of layers: [{'path': '...', 'depth': 0.5, 'sensitivity': 1.0}]")

    args = parser.parse_args()

    # Parse layers
    try:
        layers_data = json.loads(args.layers)
    except Exception as e:
        print(f"Error parsing layers JSON: {e}", file=sys.stderr)
        sys.exit(1)

    if not layers_data:
        print("Error: No layers specified", file=sys.stderr)
        sys.exit(1)

    # Output directory
    import time
    safe_name = clean_filename(args.name.replace(" ", "_"))
    if not safe_name:
        safe_name = f"custom_parallax_{int(time.time())}"
        
    dest_dir = Path.home() / "Pictures" / "Wallpapers" / f"custom_{safe_name}"
    dest_dir.mkdir(parents=True, exist_ok=True)

    json_layers = []

    for i, layer in enumerate(layers_data):
        src_path = Path(layer["path"])
        if not src_path.is_file():
            print(f"Warning: Layer path not found: {src_path}", file=sys.stderr)
            continue
            
        # Unique layer file name inside the dest folder
        file_suffix = src_path.suffix
        if not file_suffix:
            file_suffix = ".png"
        dest_filename = f"layer_{i}_{clean_filename(src_path.stem)}{file_suffix}"
        dest_file_path = dest_dir / dest_filename
        
        # Copy file
        try:
            shutil.copy2(src_path, dest_file_path)
        except Exception as e:
            print(f"Error copying {src_path} to {dest_file_path}: {e}", file=sys.stderr)
            continue

        json_layers.append({
            "source": dest_filename,
            "depth": float(layer.get("depth", 0.5)),
            "sensitivity": float(layer.get("sensitivity", 1.0))
        })

    # Generate wallpaper.json
    config = {
        "type": "parallax",
        "parallax": {
            "maxDisplacementX": args.max_x,
            "maxDisplacementY": args.max_y,
            "spring": {
                "stiffness": args.stiffness,
                "damping": args.damping
            },
            "layers": json_layers
        }
    }

    config_path = dest_dir / "wallpaper.json"
    try:
        config_path.write_text(json.dumps(config, indent=2))
        print(f"SUCCESS: Created wallpaper configuration at {config_path}")
        
        # Print path so caller can read it
        print(f"PATH:{config_path}")

        # Create a portable zip archive next to the folder
        try:
            zip_dest = dest_dir.parent / dest_dir.name
            shutil.make_archive(str(zip_dest), 'zip', str(dest_dir))
            print(f"ZIP:{zip_dest}.zip")
        except Exception as e:
            print(f"Warning: Failed to create portable zip archive: {e}", file=sys.stderr)
    except Exception as e:
        print(f"Error writing wallpaper.json: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
