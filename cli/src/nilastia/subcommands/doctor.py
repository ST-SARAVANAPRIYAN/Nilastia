import os
import shutil
import subprocess
from argparse import Namespace
from pathlib import Path

from nilastia.utils.io import confirm, fatal, info, log, warn

class Command:
    args: Namespace

    def __init__(self, args: Namespace) -> None:
        self.args = args

    def run(self) -> None:
        info("=== Nilastia System Doctor ===")
        log("Running diagnostic checks...")

        gpu_ok = self.check_gpu_driver()
        priority_ok = self.check_process_priorities()
        deps_ok = self.check_dependencies()
        session_ok = self.check_sessions()

        print()
        if gpu_ok and priority_ok and deps_ok and session_ok:
            info("Everything looks great! Your system is healthy.")
        else:
            warn("Some diagnostic checks returned warnings/errors. See above for details.")

    def check_gpu_driver(self) -> bool:
        print()
        log("[1/4] Checking GPU Driver configurations...")
        try:
            lspci_out = subprocess.check_output("lspci -k", shell=True, text=True)
        except Exception:
            warn("  Unable to run lspci to check graphics drivers.")
            return False

        has_intel = "Intel Corporation" in lspci_out
        if not has_intel:
            info("  No Intel integrated GPU detected. Skipping driver checks.")
            return True

        # Check which kernel driver is active for Intel graphics
        intel_lines = [line for line in lspci_out.splitlines() if "Intel Corporation" in line or "Kernel driver in use" in line]
        intel_driver = ""
        for i, line in enumerate(intel_lines):
            if "Intel Corporation" in line and i + 1 < len(intel_lines) and "Kernel driver" in intel_lines[i + 1]:
                intel_driver = intel_lines[i + 1].split(":")[-1].strip()

        if not intel_driver:
            # Fallback search
            for line in lspci_out.splitlines():
                if "Kernel driver in use" in line and ("xe" in line or "i915" in line):
                    intel_driver = line.split(":")[-1].strip()

        info(f"  Active Intel GPU driver: '{intel_driver}'")

        # Read /proc/cmdline to see active boot parameters
        try:
            cmdline = Path("/proc/cmdline").read_text().strip()
        except Exception:
            cmdline = ""

        if intel_driver == "xe":
            warn("  WARNING: Your Intel iGPU is using the new, experimental 'xe' driver.")
            warn("           The 'xe' driver has known Wayland stutter/hang issues with custom QML shaders.")
            warn("           It is highly recommended to switch to the stable 'i915' driver.")
            
            if "i915.force_probe" not in cmdline or "xe.force_probe" not in cmdline:
                warn("  Recommended boot parameters are missing in /proc/cmdline.")
                if confirm("Would you like to configure GRUB to force the stable 'i915' driver?", default=True):
                    self.fix_intel_driver()
            return False
        else:
            info("  Intel GPU is utilizing the stable 'i915' driver.")
            return True

    def fix_intel_driver(self) -> None:
        grub_file = Path("/etc/default/grub")
        if not grub_file.exists():
            fatal("  Could not locate /etc/default/grub to apply fix.")

        log("  Modifying /etc/default/grub (requires root)...")
        try:
            # First fetch the device ID of Raptor Lake/Alder Lake graphics if possible, default to a78b
            dev_id = "a78b"
            # Read file
            content = grub_file.read_text()
            if "i915.force_probe" in content:
                # Replace existing force_probe options
                import re
                content = re.sub(r'i915\.force_probe=[^\s"]+', f'i915.force_probe={dev_id}', content)
                content = re.sub(r'xe\.force_probe=[^\s"]+', f'xe.force_probe=!{dev_id}', content)
            else:
                # Add to GRUB_CMDLINE_LINUX_DEFAULT
                if 'GRUB_CMDLINE_LINUX_DEFAULT="' in content:
                    content = content.replace(
                        'GRUB_CMDLINE_LINUX_DEFAULT="',
                        f'GRUB_CMDLINE_LINUX_DEFAULT="i915.force_probe={dev_id} xe.force_probe=!{dev_id} '
                    )
            
            # Write out using sudo
            temp_path = Path("/tmp/grub.tmp")
            temp_path.write_text(content)
            
            subprocess.run(["sudo", "mv", str(temp_path), str(grub_file)], check=True)
            log("  Regenerating GRUB configuration...")
            subprocess.run(["sudo", "grub-mkconfig", "-o", "/boot/grub/grub.cfg"], check=True)
            info("  GRUB configured successfully! Please reboot your system to apply the driver change.")
        except Exception as e:
            warn(f"  Failed to configure GRUB: {e}")

    def check_process_priorities(self) -> bool:
        print()
        log("[2/4] Checking CPU scheduling priorities (Nice levels)...")
        
        # Check running Niri process Nice value
        niri_nice = self.get_process_nice("niri")
        shell_nice = self.get_process_nice("quickshell")

        ok = True
        if niri_nice is not None:
            if niri_nice >= 0:
                warn(f"  WARNING: Niri compositor is running at normal priority (Nice={niri_nice}).")
                warn("           To prevent desktop animations from stuttering, it should run at high priority (Nice=-15).")
                ok = False
            else:
                info(f"  Niri compositor is running at high priority (Nice={niri_nice}).")
        else:
            warn("  Niri compositor is not currently running.")

        if shell_nice is not None:
            if shell_nice < 0:
                warn(f"  WARNING: Quickshell daemon is running at high priority (Nice={shell_nice}).")
                warn("           It should run at normal priority (Nice=0) so it does not preempt the compositor.")
                ok = False
            else:
                info(f"  Quickshell daemon is running at normal priority (Nice={shell_nice}).")
        
        if not ok:
            if confirm("Would you like to write the correct systemd user service priority overrides?", default=True):
                self.fix_service_priorities()
        return ok

    def get_process_nice(self, comm_name: str) -> int | None:
        try:
            out = subprocess.check_output(f"ps -eo ni,comm | grep -i {comm_name} || true", shell=True, text=True)
            for line in out.splitlines():
                parts = line.strip().split()
                if len(parts) >= 2 and comm_name in parts[1].lower():
                    return int(parts[0])
        except Exception:
            pass
        return None

    def fix_service_priorities(self) -> None:
        log("  Configuring systemd service overrides...")
        try:
            # 1. Update quickshell service nice to 0
            qs_service = Path.home() / ".config" / "systemd" / "user" / "niri-nilastia-shell.service"
            if qs_service.exists():
                content = qs_service.read_text()
                if "Nice=" in content:
                    import re
                    content = re.sub(r"Nice=[^\n]+", "Nice=0", content)
                    qs_service.write_text(content)
                    info("  Set Quickshell priority override to Nice=0.")

            # 2. Update niri service override nice to -15
            niri_override_dir = Path.home() / ".config" / "systemd" / "user" / "niri.service.d"
            niri_override_dir.mkdir(parents=True, exist_ok=True)
            niri_override_file = niri_override_dir / "override.conf"
            
            override_content = "[Service]\nNice=-15\n"
            if niri_override_file.exists():
                content = niri_override_file.read_text()
                if "[Service]" in content:
                    if "Nice=" in content:
                        import re
                        content = re.sub(r"Nice=[^\n]+", "Nice=-15", content)
                    else:
                        content = content.replace("[Service]", "[Service]\nNice=-15")
                    niri_override_file.write_text(content)
                else:
                    niri_override_file.write_text(override_content + content)
            else:
                niri_override_file.write_text(override_content)
            
            info("  Set Niri priority override to Nice=-15.")
            
            # Reload systemd daemon
            subprocess.run(["systemctl", "--user", "daemon-reload"], check=True)
            info("  Systemd daemon reloaded! Please log out and back in to apply compositor priorities.")
        except Exception as e:
            warn(f"  Failed to write service priority overrides: {e}")

    def check_dependencies(self) -> bool:
        print()
        log("[3/4] Scanning required packages and binaries...")
        
        required = [
            ("niri", "Wayland Tiling Compositor"),
            ("quickshell", "Shell layout framework"),
            ("wl-copy", "Clipboard copy utilities (wl-clipboard)"),
            ("mpv", "Video wallpaper renderer"),
            ("swaybg", "Static wallpaper renderer"),
            ("pipewire", "Audio/Video streams server"),
        ]

        missing = []
        for cmd, desc in required:
            if shutil.which(cmd) is None:
                missing.append((cmd, desc))

        if missing:
            warn("  Missing required utilities:")
            for cmd, desc in missing:
                warn(f"    - {cmd:<15} ({desc})")
            return False
        else:
            info("  All core binary dependencies are installed.")
            return True

    def check_sessions(self) -> bool:
        print()
        log("[4/4] Verifying display manager sessions...")
        
        desktop_session = Path("/usr/share/wayland-sessions/niri.desktop")
        if not desktop_session.exists():
            warn("  WARNING: Niri Wayland session file is not registered under /usr/share/wayland-sessions/.")
            warn("           It will not appear in SDDM/GDM/Greetd login managers.")
            
            if confirm("Would you like to register Niri in your display manager sessions?", default=True):
                self.fix_session_registration()
            return False
        else:
            info("  Niri Wayland session is correctly registered.")
            return True

    def fix_session_registration(self) -> None:
        log("  Registering Niri session (requires root)...")
        try:
            session_content = """[Desktop Entry]
Name=Niri
Comment=A scrollable-tiling Wayland compositor
Exec=niri-session
Type=Application
DesktopNames=niri
"""
            temp_path = Path("/tmp/niri.desktop")
            temp_path.write_text(session_content)
            
            subprocess.run(["sudo", "mv", str(temp_path), "/usr/share/wayland-sessions/niri.desktop"], check=True)
            info("  Niri session registered successfully!")
        except Exception as e:
            warn(f"  Failed to register session: {e}")
