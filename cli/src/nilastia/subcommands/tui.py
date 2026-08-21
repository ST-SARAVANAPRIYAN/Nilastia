import os
import re
import sys
import shutil
import tty
import termios
import select
import subprocess
from argparse import Namespace
from pathlib import Path
from datetime import datetime

# Import theme utilities dynamically to load all 40+ combinations
from nilastia.utils.scheme import (
    get_scheme,
    get_scheme_names,
    get_scheme_flavours,
    get_scheme_modes,
    scheme_variants
)

class Command:
    args: Namespace

    def __init__(self, args: Namespace) -> None:
        self.args = args
        self.active_tab = 0  # 0: Services, 1: Doctor, 2: Backups, 3: Themes
        self.focus_area = "sidebar"  # "sidebar" or "content"
        self.active_button_idx = 0
        self.running = True
        self.buttons = []    
        
        # Load theme configuration values
        curr_scheme = get_scheme()
        self.sel_name = curr_scheme.name
        self.sel_flavour = curr_scheme.flavour
        self.sel_mode = curr_scheme.mode
        self.sel_variant = curr_scheme.variant
        
        self.doctor_logs = ["Press [D] or click [ Run Diagnostics ] below to scan system health."]
        self.backups = []
        self.refresh_backups()

    def run(self) -> None:
        self.fd = sys.stdin.fileno()
        old_settings = termios.tcgetattr(self.fd)
        
        try:
            # Enable mouse reporting (SGR mode 1006)
            sys.stdout.write("\033[?1000h\033[?1006h")
            # Hide cursor
            sys.stdout.write("\033[?25l")
            sys.stdout.write("\033[2J\033[H")
            sys.stdout.flush()
            
            tty.setraw(self.fd)
            self.main_loop()
        finally:
            # Restore cursor, disable mouse reporting
            sys.stdout.write("\033[?1000l\033[?1006l")
            sys.stdout.write("\033[?25h")
            sys.stdout.write("\033[2J\033[H")
            sys.stdout.flush()
            termios.tcsetattr(self.fd, termios.TCSADRAIN, old_settings)

    def main_loop(self) -> None:
        self.draw_ui()
        while self.running:
            r, _, _ = select.select([sys.stdin], [], [], 0.2)
            if r:
                seq = os.read(self.fd, 1024).decode("utf-8", errors="ignore")
                if not seq:
                    continue
                
                # Exit keys
                if seq in ("\x1b", "q", "Q"):
                    self.running = False
                    break
                
                # Direct numeric tab switching
                if seq in ("1", "2", "3", "4"):
                    self.active_tab = int(seq) - 1
                    self.focus_area = "sidebar"
                    self.draw_ui()
                    continue

                # Parse mouse clicks
                mouse = self.parse_sgr_mouse(seq)
                if mouse:
                    button, col, row, is_press = mouse
                    if is_press:
                        self.handle_click(col, row)
                        self.draw_ui()
                    continue

                # Keyboard Arrow/Enter Navigation
                if self.focus_area == "sidebar":
                    if seq == "\x1b[A":  # Up
                        self.active_tab = (self.active_tab - 1) % 4
                        self.draw_ui()
                    elif seq == "\x1b[B":  # Down
                        self.active_tab = (self.active_tab + 1) % 4
                        self.draw_ui()
                    elif seq in ("\x1b[C", "\r", "\n"):  # Right or Enter
                        if self.buttons:
                            self.focus_area = "content"
                            self.active_button_idx = 0
                            self.draw_ui()
                
                elif self.focus_area == "content":
                    if seq == "\x1b[A":  # Up Arrow
                        self.navigate_grid("up")
                        self.draw_ui()
                    elif seq == "\x1b[B":  # Down Arrow
                        self.navigate_grid("down")
                        self.draw_ui()
                    elif seq in ("\x1b[C", "\t"):  # Right Arrow or Tab
                        self.navigate_grid("right")
                        self.draw_ui()
                    elif seq == "\x1b[D":  # Left Arrow
                        prev_idx = self.active_button_idx
                        self.navigate_grid("left")
                        if self.active_button_idx == prev_idx:
                            self.focus_area = "sidebar"
                        self.draw_ui()
                    elif seq == "\x7f":  # Backspace
                        self.focus_area = "sidebar"
                        self.draw_ui()
                    elif seq in ("\r", "\n"):  # Enter
                        if self.buttons and self.active_button_idx < len(self.buttons):
                            self.handle_action(self.buttons[self.active_button_idx]["action"])
                            self.draw_ui()

    def parse_sgr_mouse(self, seq: str):
        match = re.match(r'.*?\x1b\[<(\d+);(\d+);(\d+)([Mm])', seq)
        if match:
            button = int(match.group(1))
            col = int(match.group(2))
            row = int(match.group(3))
            is_press = match.group(4) == 'M'
            return button, col, row, is_press
        return None

    def navigate_grid(self, direction: str) -> None:
        if not self.buttons:
            return
            
        curr = self.buttons[self.active_button_idx]
        best_idx = self.active_button_idx
        min_dist = float('inf')
        
        for idx, btn in enumerate(self.buttons):
            if idx == self.active_button_idx:
                continue
                
            dx = btn["x1"] - curr["x1"]
            dy = btn["y"] - curr["y"]
            
            if direction == "up" and dy < 0:
                dist = abs(dy) * 100 + abs(dx)
                if dist < min_dist:
                    min_dist = dist
                    best_idx = idx
            elif direction == "down" and dy > 0:
                dist = abs(dy) * 100 + abs(dx)
                if dist < min_dist:
                    min_dist = dist
                    best_idx = idx
            elif direction == "right" and dy == 0 and dx > 0:
                dist = dx
                if dist < min_dist:
                    min_dist = dist
                    best_idx = idx
            elif direction == "left" and dy == 0 and dx < 0:
                dist = -dx
                if dist < min_dist:
                    min_dist = dist
                    best_idx = idx
                    
        self.active_button_idx = best_idx

    def draw_text(self, x: int, y: int, text: str, color: str = "\033[0m") -> None:
        sys.stdout.write(f"\033[{y};{x}H{color}{text}\033[0m")

    def draw_ui(self) -> None:
        width, height = shutil.get_terminal_size()
        sys.stdout.write("\033[2J\033[H")
        
        self.draw_border(1, 1, width, height)
        
        title = " N I L A S T I A   D E S K T O P   M A N A G E R "
        self.draw_text((width - len(title)) // 2, 2, title, "\033[1;36m")
        self.draw_text(2, 3, "─" * (width - 2), "\033[38;5;240m")
        
        self.draw_sidebar(width, height)
        
        for y in range(4, height):
            self.draw_text(24, y, "│", "\033[38;5;240m")
            
        self.buttons = []
        if self.active_tab == 0:
            self.draw_status_tab(width, height)
        elif self.active_tab == 1:
            self.draw_doctor_tab(width, height)
        elif self.active_tab == 2:
            self.draw_backups_tab(width, height)
        elif self.active_tab == 3:
            self.draw_style_tab(width, height)

        self.draw_footer_helpers(width, height)
        sys.stdout.flush()

    def draw_border(self, x1: int, y1: int, x2: int, y2: int) -> None:
        self.draw_text(x1, y1, "╔", "\033[38;5;244m")
        self.draw_text(x2, y1, "╗", "\033[38;5;244m")
        self.draw_text(x1, y2, "╚", "\033[38;5;244m")
        self.draw_text(x2, y2, "╝", "\033[38;5;244m")
        
        self.draw_text(x1 + 1, y1, "═" * (x2 - x1 - 1), "\033[38;5;244m")
        self.draw_text(x1 + 1, y2, "═" * (x2 - x1 - 1), "\033[38;5;244m")
        
        for y in range(y1 + 1, y2):
            self.draw_text(x1, y, "║", "\033[38;5;244m")
            self.draw_text(x2, y, "║", "\033[38;5;244m")

    def draw_sidebar(self, width: int, height: int) -> None:
        menu_items = [
            "Services Control",
            "System Doctor",
            "Config Backups",
            "Styles & Themes",
            "Exit Dashboard"
        ]
        
        for i, item in enumerate(menu_items):
            y_pos = 5 + (i * 2)
            if i == 4:
                y_pos = height - 2
            
            is_active_tab = (i == self.active_tab)
            is_focused = is_active_tab and (self.focus_area == "sidebar")
            
            if is_focused:
                color = "\033[1;37;44m"
                marker = "▶ "
            elif is_active_tab:
                color = "\033[1;36m"
                marker = "○ "
            else:
                color = "\033[0m"
                marker = "  "
            
            label = f"{marker}[{i+1}] {item:<14}"
            self.draw_text(3, y_pos, label, color)

    def register_button(self, label: str, action: str, x: int, y: int) -> None:
        idx = len(self.buttons)
        is_focused = (self.focus_area == "content") and (idx == self.active_button_idx)
        
        color = "\033[1;30;43m" if is_focused else "\033[1;34m"
        self.draw_text(x, y, label, color)
        
        self.buttons.append({
            "x1": x, "x2": x + len(label), "y": y,
            "action": action
        })

    def draw_status_tab(self, width: int, height: int) -> None:
        self.draw_text(26, 5, "=== Services Status & Controls ===", "\033[1;37m")
        
        niri_status = self.get_service_status("niri.service")
        shell_status = self.get_service_status("niri-nilastia-shell.service")
        xwayland_status = self.get_service_status("xwayland-satellite.service")
        
        niri_color = "\033[1;32m" if "active (running)" in niri_status else "\033[1;31m"
        shell_color = "\033[1;32m" if "active (running)" in shell_status else "\033[1;31m"
        xway_color = "\033[1;32m" if "active (running)" in xwayland_status else "\033[1;31m"
        
        self.draw_text(28, 7, "Niri Compositor Service:", "\033[0m")
        self.draw_text(55, 7, "RUNNING" if "active (running)" in niri_status else "STOPPED", niri_color)
        
        self.draw_text(28, 8, "Nilastia Desktop Shell:", "\033[0m")
        self.draw_text(55, 8, "RUNNING" if "active (running)" in shell_status else "STOPPED", shell_color)

        self.draw_text(28, 9, "Xwayland Satellite Server:", "\033[0m")
        self.draw_text(55, 9, "RUNNING" if "active (running)" in xwayland_status else "STOPPED", xway_color)
        
        self.draw_text(26, 11, "--- Desktop Service Controls ---", "\033[1;30m")
        
        self.register_button("[ Start Shell ]", "shell_start", 28, 13)
        self.register_button("[ Restart Shell ]", "shell_restart", 47, 13)
        self.register_button("[ Reload QML ]", "shell_reload", 68, 13)
        
        self.register_button("[ Stop Shell ]", "shell_stop", 28, 15)
        self.register_button("[ Start Niri ]", "niri_start", 47, 15)
        self.register_button("[ Restart Niri ]", "niri_restart", 68, 15)
        
        self.register_button("[ Stop Niri ]", "niri_stop", 28, 17)
        self.register_button("[ View Logs ]", "shell_logs", 47, 17)

        self.draw_text(26, 19, "--- Shell Console logs ---", "\033[1;30m")
        log_box_height = height - 22
        recent_logs = self.get_shell_logs(log_box_height)
        for idx, line in enumerate(recent_logs):
            if 20 + idx < height - 2:
                self.draw_text(28, 20 + idx, line[:width - 32], "\033[38;5;246m")

    def draw_doctor_tab(self, width: int, height: int) -> None:
        self.draw_text(26, 5, "=== System Doctor Diagnostics ===", "\033[1;37m")
        
        self.register_button("[ Run Diagnostics ]", "doctor_run", 28, 7)
        self.register_button("[ Apply System Auto-Fixes ]", "doctor_fix", 52, 7)

        self.draw_text(26, 10, "--- Diagnostics Report Logs ---", "\033[1;30m")
        for idx, line in enumerate(self.doctor_logs):
            y_pos = 12 + idx
            if y_pos < height - 3:
                color = "\033[38;5;250m"
                if "WARNING:" in line or "Warning:" in line:
                    color = "\033[1;33m"
                elif "Everything looks great" in line or "registered" in line or "stable" in line:
                    color = "\033[1;32m"
                elif "Missing" in line:
                    color = "\033[1;31m"
                self.draw_text(28, y_pos, line[:width - 32], color)

    def draw_backups_tab(self, width: int, height: int) -> None:
        self.draw_text(26, 5, "=== Configuration Backups ===", "\033[1;37m")
        
        self.register_button("[ Create Config Snapshot ]", "backup_create", 28, 7)

        self.draw_text(26, 10, "--- Stored Backup Archives ---", "\033[1;30m")
        self.draw_text(28, 12, f"{'Backup File Name':<35} | {'Size':<10}", "\033[1;34m")
        self.draw_text(28, 13, "-" * (width - 32), "\033[38;5;240m")
        
        for idx, bp in enumerate(self.backups):
            y_pos = 15 + (idx * 2)
            if y_pos < height - 3:
                self.draw_text(28, y_pos, f"{bp['name']:<35} | {bp['size']}", "\033[0m")
                self.register_button("[ Restore Snapshot ]", f"backup_restore_{bp['name']}", 28 + 48, y_pos)

    def draw_style_tab(self, width: int, height: int) -> None:
        self.draw_text(26, 5, "=== Styles & Color Themes ===", "\033[1;37m")
        
        self.draw_text(28, 7, "Cycle property values with arrow selectors, then apply:", "\033[38;5;244m")
        
        # 1. Scheme Name Row
        self.draw_text(28, 9, "Scheme Name:  ", "\033[0m")
        self.register_button(" ◀ ", "theme_name_prev", 45, 9)
        self.draw_text(50, 9, f"{self.sel_name:<15}", "\033[1;36m")
        self.register_button(" ▶ ", "theme_name_next", 67, 9)
        
        # 2. Scheme Flavour Row
        self.draw_text(28, 11, "Flavour:      ", "\033[0m")
        self.register_button(" ◀ ", "theme_flavour_prev", 45, 11)
        self.draw_text(50, 11, f"{self.sel_flavour:<15}", "\033[1;36m")
        self.register_button(" ▶ ", "theme_flavour_next", 67, 11)
        
        # 3. Scheme Mode Row
        self.draw_text(28, 13, "System Mode:  ", "\033[0m")
        self.register_button(" ◀ ", "theme_mode_prev", 45, 13)
        self.draw_text(50, 13, f"{self.sel_mode:<15}", "\033[1;36m")
        self.register_button(" ▶ ", "theme_mode_next", 67, 13)
        
        # 4. Scheme Variant Row
        self.draw_text(28, 15, "Variant Type: ", "\033[0m")
        self.register_button(" ◀ ", "theme_variant_prev", 45, 15)
        self.draw_text(50, 15, f"{self.sel_variant:<15}", "\033[1;36m")
        self.register_button(" ▶ ", "theme_variant_next", 67, 15)
        
        # Apply button
        self.register_button("[ Apply Selected Combination ]", "theme_apply", 28, 18)

        # Wallpaper triggers
        self.draw_text(26, height - 6, "=== Desktop Wallpaper ===", "\033[1;37m")
        self.register_button("[ Apply Random Wallpaper ]", "wallpaper_random", 28, height - 4)

    def draw_footer_helpers(self, width: int, height: int) -> None:
        if self.focus_area == "sidebar":
            footer_hint = " Navigation: [▲/▼] Change Tab | [Enter/►] Enter Section Content | [Q] Exit TUI"
        else:
            footer_hint = " Navigation: [▲/▼/◄/►] Move Selection | [Enter] Activate Option | [Backspace/◄] Back to Sidebar"
            
        self.draw_text(26, height - 2, footer_hint, "\033[1;30;47m" if self.focus_area == "content" else "\033[1;30m")

    def handle_click(self, col: int, row: int) -> None:
        for i in range(5):
            y_pos = 5 + (i * 2)
            if i == 4:
                y_pos = shutil.get_terminal_size()[1] - 2
            if row == y_pos and 3 <= col <= 22:
                if i == 4:
                    self.running = False
                else:
                    self.active_tab = i
                    self.focus_area = "sidebar"
                return

        for idx, btn in enumerate(self.buttons):
            if btn["y"] == row and btn["x1"] <= col <= btn["x2"]:
                self.focus_area = "content"
                self.active_button_idx = idx
                self.handle_action(btn["action"])
                return

    def handle_action(self, action: str) -> None:
        # Status tab actions
        if action == "shell_start":
            subprocess.run(["systemctl", "--user", "start", "niri-nilastia-shell.service"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        elif action == "shell_stop":
            subprocess.run(["systemctl", "--user", "stop", "niri-nilastia-shell.service"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        elif action == "shell_restart":
            subprocess.run(["systemctl", "--user", "restart", "niri-nilastia-shell.service"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        elif action == "shell_reload":
            subprocess.run(["qs", "-c", "niri-nilastia-shell", "reload"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        elif action == "niri_start":
            subprocess.run(["systemctl", "--user", "start", "niri.service"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        elif action == "niri_restart":
            subprocess.run(["systemctl", "--user", "restart", "niri.service"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        elif action == "niri_stop":
            subprocess.run(["systemctl", "--user", "stop", "niri.service"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        elif action == "shell_logs":
            self.view_logs_fullscreen()
            
        # Doctor actions
        elif action == "doctor_run":
            self.run_doctor_checks()
        elif action == "doctor_fix":
            self.run_doctor_fixes()
            
        # Backup actions
        elif action == "backup_create":
            self.create_snapshot()
        elif action.startswith("backup_restore_"):
            backup_name = action.replace("backup_restore_", "")
            self.restore_snapshot(backup_name)
            
        # Theme Cycle Carousels
        elif action == "theme_name_next":
            names = get_scheme_names()
            idx = names.index(self.sel_name)
            self.sel_name = names[(idx + 1) % len(names)]
            self._update_theme_dependencies()
        elif action == "theme_name_prev":
            names = get_scheme_names()
            idx = names.index(self.sel_name)
            self.sel_name = names[(idx - 1) % len(names)]
            self._update_theme_dependencies()
            
        elif action == "theme_flavour_next":
            flavs = get_scheme_flavours(self.sel_name)
            idx = flavs.index(self.sel_flavour) if self.sel_flavour in flavs else 0
            self.sel_flavour = flavs[(idx + 1) % len(flavs)]
            self._update_theme_dependencies()
        elif action == "theme_flavour_prev":
            flavs = get_scheme_flavours(self.sel_name)
            idx = flavs.index(self.sel_flavour) if self.sel_flavour in flavs else 0
            self.sel_flavour = flavs[(idx - 1) % len(flavs)]
            self._update_theme_dependencies()
            
        elif action == "theme_mode_next":
            modes = get_scheme_modes(self.sel_name, self.sel_flavour)
            idx = modes.index(self.sel_mode) if self.sel_mode in modes else 0
            self.sel_mode = modes[(idx + 1) % len(modes)]
        elif action == "theme_mode_prev":
            modes = get_scheme_modes(self.sel_name, self.sel_flavour)
            idx = modes.index(self.sel_mode) if self.sel_mode in modes else 0
            self.sel_mode = modes[(idx - 1) % len(modes)]
            
        elif action == "theme_variant_next":
            vars_list = scheme_variants
            idx = vars_list.index(self.sel_variant) if self.sel_variant in vars_list else 0
            self.sel_variant = vars_list[(idx + 1) % len(vars_list)]
        elif action == "theme_variant_prev":
            vars_list = scheme_variants
            idx = vars_list.index(self.sel_variant) if self.sel_variant in vars_list else 0
            self.sel_variant = vars_list[(idx - 1) % len(vars_list)]
            
        elif action == "theme_apply":
            cmd = ["nilastia", "scheme", "set", "-n", self.sel_name, "-f", self.sel_flavour, "-m", self.sel_mode, "-v", self.sel_variant]
            subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            
        elif action == "wallpaper_random":
            subprocess.run(["nilastia", "wallpaper", "-r"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    def _update_theme_dependencies(self) -> None:
        flavs = get_scheme_flavours(self.sel_name)
        if self.sel_flavour not in flavs:
            self.sel_flavour = flavs[0] if flavs else "default"
            
        modes = get_scheme_modes(self.sel_name, self.sel_flavour)
        if self.sel_mode not in modes:
            self.sel_mode = modes[0] if modes else "dark"

    def get_service_status(self, service_name: str) -> str:
        try:
            out = subprocess.check_output(["systemctl", "--user", "status", service_name], text=True, stderr=subprocess.DEVNULL)
            return out
        except subprocess.CalledProcessError as e:
            return e.output if e.output else "inactive"

    def get_shell_logs(self, max_lines: int) -> list[str]:
        try:
            out = subprocess.check_output(["journalctl", "--user", "-u", "niri-nilastia-shell.service", "-n", str(max_lines), "--no-pager"], text=True, stderr=subprocess.DEVNULL)
            lines = [line.strip() for line in out.splitlines() if line.strip()]
            return lines[-max_lines:]
        except Exception:
            return ["No console logs available."]

    def view_logs_fullscreen(self) -> None:
        sys.stdout.write("\033[?1000l\033[?1006l\033[?25h\033[2J\033[H")
        sys.stdout.flush()
        
        fd = sys.stdin.fileno()
        old_settings = termios.tcgetattr(fd)
        termios.tcsetattr(fd, termios.TCSADRAIN, old_settings)
        
        print("=== Displaying active systemd user logs (Press 'q' to exit journal view) ===")
        subprocess.run(["journalctl", "--user", "-u", "niri-nilastia-shell.service", "-e"])
        
        # Re-enter raw mode
        tty.setraw(fd)
        sys.stdout.write("\033[?1000h\033[?1006h\033[?25l")
        sys.stdout.flush()

    def run_doctor_checks(self) -> None:
        self.doctor_logs = ["Running diagnostics..."]
        try:
            self.doctor_logs = []
            
            self.doctor_logs.append("Checking GPU config...")
            try:
                lspci_out = subprocess.check_output("lspci -k", shell=True, text=True)
                if "Kernel driver in use" in lspci_out:
                    driver = [line for line in lspci_out.splitlines() if "Kernel driver" in line and ("xe" in line or "i915" in line)]
                    self.doctor_logs.append(f"  Active driver: {driver[0].split(':')[-1].strip() if driver else 'i915'}")
            except Exception:
                pass
                
            self.doctor_logs.append("Checking CPU priorities (Nice values)...")
            niri_nice = self.get_process_nice("niri")
            shell_nice = self.get_process_nice("quickshell")
            
            self.doctor_logs.append(f"  Niri priority: Nice={niri_nice if niri_nice is not None else 0}")
            self.doctor_logs.append(f"  Quickshell priority: Nice={shell_nice if shell_nice is not None else 0}")
            
            self.doctor_logs.append("Verifying core package dependencies...")
            required = ["niri", "quickshell", "wl-copy", "mpv", "swaybg", "pipewire"]
            missing = [cmd for cmd in required if shutil.which(cmd) is None]
            self.doctor_logs.append(f"  Missing packages: {', '.join(missing) if missing else 'None'}")
            
            self.doctor_logs.append("Session Check:")
            if Path("/usr/share/wayland-sessions/niri.desktop").exists():
                self.doctor_logs.append("  Niri Wayland session is registered.")
            else:
                self.doctor_logs.append("  WARNING: Niri session file is not registered.")
                
            self.doctor_logs.append("Diagnostic complete.")
        except Exception as e:
            self.doctor_logs.append(f"Failed running doctor module: {e}")

    def run_doctor_fixes(self) -> None:
        self.doctor_logs = ["Applying auto-fixes..."]
        try:
            from nilastia.subcommands.doctor import Command as DoctorCmd
            doc = DoctorCmd(Namespace())
            doc.fix_service_priorities()
            self.doctor_logs.append("Systemd priority overrides written!")
            self.doctor_logs.append("Nice=0 set for Quickshell, Nice=-15 set for Niri.")
        except Exception as e:
            self.doctor_logs.append(f"Failed applying auto-fixes: {e}")

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

    def refresh_backups(self) -> None:
        self.backups = []
        backup_root = Path(os.getenv("XDG_CACHE_HOME", Path.home() / ".cache")) / "nilastia" / "backups"
        if backup_root.exists():
            for path in sorted(backup_root.glob("*.tar.gz"), key=os.path.getmtime, reverse=True):
                size_mb = path.stat().st_size / (1024 * 1024)
                self.backups.append({
                    "name": path.stem,
                    "size": f"{size_mb:.2f} MB"
                })

    def create_snapshot(self) -> None:
        from nilastia.subcommands.backup import Command as BackupCmd
        cmd = BackupCmd(Namespace(action="create", name=None))
        cmd.run()
        self.refresh_backups()

    def restore_snapshot(self, backup_name: str) -> None:
        sys.stdout.write("\033[?1000l\033[?1006l\033[?25h\033[2J\033[H")
        sys.stdout.flush()
        
        fd = sys.stdin.fileno()
        old_settings = termios.tcgetattr(fd)
        termios.tcsetattr(fd, termios.TCSADRAIN, old_settings)
        
        from nilastia.subcommands.backup import Command as BackupCmd
        cmd = BackupCmd(Namespace(action="restore", name=backup_name))
        try:
            cmd.run()
        except SystemExit:
            pass
            
        # Re-enter raw mode
        tty.setraw(fd)
        sys.stdout.write("\033[?1000h\033[?1006h\033[?25l")
        sys.stdout.flush()
        self.refresh_backups()
