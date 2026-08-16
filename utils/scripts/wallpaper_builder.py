#!/usr/bin/env python3
import sys
import json
import argparse
import base64
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
    parser.add_argument("--layers", default="-", help="JSON array of layers, or '-' to read from stdin")

    args = parser.parse_args()

    # Parse layers
    if args.layers == "-":
        try:
            layers_data = json.loads(sys.stdin.readline())
        except Exception as e:
            print(f"Error parsing layers JSON from stdin: {e}", file=sys.stderr)
            sys.exit(1)
    else:
        try:
            layers_data = json.loads(args.layers)
        except Exception as e:
            print(f"Error parsing layers JSON: {e}", file=sys.stderr)
            sys.exit(1)

    if not layers_data:
        print("Error: No layers specified", file=sys.stderr)
        sys.exit(1)

    import time
    safe_name = clean_filename(args.name.replace(" ", "_"))
    if not safe_name:
        safe_name = f"custom_parallax_{int(time.time())}"

    json_layers = []

    for i, layer in enumerate(layers_data):
        path_str = layer["path"]
        if path_str == "virtual://clock":
            json_layers.append({
                "source": "virtual://clock",
                "depth": float(layer.get("depth", 0.5)),
                "sensitivity": float(layer.get("sensitivity", 1.0))
            })
            continue

        if path_str.startswith("data:"):
            json_layers.append({
                "source": path_str,
                "depth": float(layer.get("depth", 0.5)),
                "sensitivity": float(layer.get("sensitivity", 1.0))
            })
            continue

        src_path = Path(path_str)
        if not src_path.is_file():
            print(f"Warning: Layer path not found: {src_path}", file=sys.stderr)
            continue
            
        file_suffix = src_path.suffix.lower()
        if not file_suffix:
            file_suffix = ".png"

        try:
            img_bytes = src_path.read_bytes()
            b64_str = base64.b64encode(img_bytes).decode('utf-8')
            
            mime_type = "image/png"
            if file_suffix in [".jpg", ".jpeg"]:
                mime_type = "image/jpeg"
            elif file_suffix == ".webp":
                mime_type = "image/webp"
            elif file_suffix == ".gif":
                mime_type = "image/gif"
                
            source_val = f"data:{mime_type};base64,{b64_str}"
        except Exception as e:
            print(f"Error reading and base64-encoding {src_path}: {e}", file=sys.stderr)
            continue

        json_layers.append({
            "source": source_val,
            "depth": float(layer.get("depth", 0.5)),
            "sensitivity": float(layer.get("sensitivity", 1.0))
        })

    # Generate wallpaper configuration
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

    output_dir = Path.home() / "Pictures" / "Wallpapers"
    output_dir.mkdir(parents=True, exist_ok=True)
    config_path = output_dir / f"{safe_name}.nilawall"

    try:
        config_path.write_text(json.dumps(config, indent=2))
        print(f"SUCCESS: Created wallpaper configuration at {config_path}")
        print(f"PATH:{config_path}")
    except Exception as e:
        print(f"Error writing .nilawall file: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
