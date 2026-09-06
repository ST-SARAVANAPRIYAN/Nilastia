#!/usr/bin/env python3
import sys
import json
import argparse
import base64
import hashlib
import tempfile
from pathlib import Path

def clean_filename(name: str) -> str:
    return "".join(c for c in name if c.isalnum() or c in ("-", "_", ".")).strip()

def unpack_nilawall(config_path_str: str):
    config_path = Path(config_path_str)
    if not config_path.is_file():
        print(f"Error: Config file not found: {config_path}", file=sys.stderr)
        sys.exit(1)
        
    try:
        config = json.loads(config_path.read_text())
    except Exception as e:
        print(f"Error parsing JSON: {e}", file=sys.stderr)
        sys.exit(1)
        
    if config.get("type") != "parallax" or "parallax" not in config:
        print("Error: Invalid parallax config format", file=sys.stderr)
        sys.exit(1)
        
    layers = config["parallax"].get("layers", [])
    unpacked_layers = []
    
    base_dir = config_path.parent
    
    for i, layer in enumerate(layers):
        src = layer.get("source", "")
        depth = layer.get("depth", 0.5)
        sensitivity = layer.get("sensitivity", 1.0)
        
        if src.startswith("data:") and "base64," in src:
            try:
                header, b64_data = src.split("base64,", 1)
                mime = header.split(";")[0].replace("data:", "")
                suffix = ".png"
                if "jpeg" in mime or "jpg" in mime:
                    suffix = ".jpg"
                elif "webp" in mime:
                    suffix = ".webp"
                elif "gif" in mime:
                    suffix = ".gif"
                
                img_bytes = base64.b64decode(b64_data)
                
                # Write to temp file
                temp_filename = f"nilastia_layer_{i}_{hashlib.md5(img_bytes[:100]).hexdigest()}{suffix}"
                temp_path = Path(tempfile.gettempdir()) / temp_filename
                temp_path.write_bytes(img_bytes)
                
                unpacked_layers.append({
                    "path": str(temp_path),
                    "depth": depth,
                    "sensitivity": sensitivity
                })
            except Exception as e:
                print(f"Error unpacking base64 layer {i}: {e}", file=sys.stderr)
                unpacked_layers.append({
                    "path": src,
                    "depth": depth,
                    "sensitivity": sensitivity
                })
        elif src == "virtual://clock":
            unpacked_layers.append({
                "path": "virtual://clock",
                "depth": depth,
                "sensitivity": sensitivity
            })
        else:
            # It's a local/relative file path
            full_path = src if Path(src).is_absolute() else str((base_dir / src).resolve())
            unpacked_layers.append({
                "path": full_path,
                "depth": depth,
                "sensitivity": sensitivity
            })
            
    # Print the unpacked config/layers to stdout as JSON
    result = {
        "name": config_path.stem.replace("_", " "),
        "duration": config["parallax"].get("animation", {}).get("duration", 800),
        "maxX": config["parallax"].get("maxDisplacementX", 35.0),
        "maxY": config["parallax"].get("maxDisplacementY", 20.0),
        "intensity": config["parallax"].get("intensity", 1.0),
        "layers": unpacked_layers
    }
    print(json.dumps(result))

def main():
    parser = argparse.ArgumentParser(description="Create custom parallax wallpaper theme")
    parser.add_argument("--name", help="Theme name")
    parser.add_argument("--stiffness", type=float, default=18.0)
    parser.add_argument("--damping", type=float, default=0.85)
    parser.add_argument("--duration", type=int, default=800, help="Glide duration in milliseconds")
    parser.add_argument("--intensity", type=float, default=1.0)
    parser.add_argument("--max-x", type=float, default=75.0)
    parser.add_argument("--max-y", type=float, default=45.0)
    parser.add_argument("--layers", default="-", help="JSON array of layers, or '-' to read from stdin")
    parser.add_argument("--unpack", help="Path to a .nilawall file to unpack base64 layers from")

    args = parser.parse_args()

    if args.unpack:
        unpack_nilawall(args.unpack)
        return

    if not args.name:
        print("Error: --name is required unless --unpack is specified", file=sys.stderr)
        sys.exit(1)

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

    output_dir = Path.home() / "Pictures" / "Wallpapers"
    output_dir.mkdir(parents=True, exist_ok=True)

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
            "intensity": args.intensity,
            "maxDisplacementX": args.max_x,
            "maxDisplacementY": args.max_y,
            "animation": {
                "duration": args.duration
            },
            "spring": {
                "stiffness": args.stiffness,
                "damping": args.damping
            },
            "layers": json_layers
        }
    }

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
