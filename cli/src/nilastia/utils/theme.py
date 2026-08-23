import fcntl
import json
import os
import re
import shutil
import subprocess
import tempfile
from pathlib import Path

from nilastia.utils.colour import get_dynamic_colours
from nilastia.utils.hypr import is_lua_config
from nilastia.utils.io import log_exception
from nilastia.utils.paths import (
    atomic_write,
    c_state_dir,
    config_dir,
    data_dir,
    get_config,
    templates_dir,
    theme_dir,
    user_templates_dir,
)
from nilastia.utils.scheme import get_scheme


def gen_conf(colours: dict[str, str]) -> str:
    conf = ""
    for name, colour in colours.items():
        conf += f"${name} = {colour}\n"
    return conf


def gen_lua(colours: dict[str, str]) -> str:
    lua = "return {\n"
    for name, colour in colours.items():
        lua += f'  {name} = "{colour}",\n'
    lua += "}"
    return lua


def gen_scss(colours: dict[str, str]) -> str:
    scss = ""
    for name, colour in colours.items():
        scss += f"${name}: #{colour};\n"
    return scss


def gen_replace(colours: dict[str, str], template: Path, hash: bool = False) -> str:
    new_template = template.read_text()
    for name, colour in colours.items():
        new_template = new_template.replace(f"{{{{ ${name} }}}}", f"#{colour}" if hash else colour)
    return new_template


def gen_replace_dynamic(colours: dict[str, str], template: Path, mode: str) -> str:
    def fill_colour(match: re.Match) -> str:
        data = match.group(1).strip().split(".")
        if len(data) != 2:
            return match.group()
        col, form = data
        if col not in colours_dyn or not hasattr(colours_dyn[col], form):
            return match.group()
        return getattr(colours_dyn[col], form)

    # match atomic {{ . }} pairs
    dotField = r"\{\{((?:(?!\{\{|\}\}).)*)\}\}"

    # match {{ mode }}
    modeField = r"\{\{\s*mode\s*\}\}"

    colours_dyn = get_dynamic_colours(colours)
    template_content = template.read_text()

    template_filled = re.sub(dotField, fill_colour, template_content)
    template_filled = re.sub(modeField, mode, template_filled)

    return template_filled


def hex_to_ansi(c: str, *i: int) -> str:
    """Hex to ANSI sequence (e.g. ffffff, 11 -> \x1b]11;rgb:ff/ff/ff\x1b\\)"""
    return f"\x1b]{';'.join(map(str, i))};rgb:{c[0:2]}/{c[2:4]}/{c[4:6]}\x1b\\"


def gen_sequences(colours: dict[str, str]) -> str:
    """
    10: foreground
    11: background
    12: cursor
    17: selection
    4:
        0 - 7: normal colours
        8 - 15: bright colours
        16+: 256 colours
    """
    return (
        hex_to_ansi(colours["onSurface"], 10)
        + hex_to_ansi(colours["surface"], 11)
        + hex_to_ansi(colours["secondary"], 12)
        + hex_to_ansi(colours["secondary"], 17)
        + hex_to_ansi(colours["term0"], 4, 0)
        + hex_to_ansi(colours["term1"], 4, 1)
        + hex_to_ansi(colours["term2"], 4, 2)
        + hex_to_ansi(colours["term3"], 4, 3)
        + hex_to_ansi(colours["term4"], 4, 4)
        + hex_to_ansi(colours["term5"], 4, 5)
        + hex_to_ansi(colours["term6"], 4, 6)
        + hex_to_ansi(colours["term7"], 4, 7)
        + hex_to_ansi(colours["term8"], 4, 8)
        + hex_to_ansi(colours["term9"], 4, 9)
        + hex_to_ansi(colours["term10"], 4, 10)
        + hex_to_ansi(colours["term11"], 4, 11)
        + hex_to_ansi(colours["term12"], 4, 12)
        + hex_to_ansi(colours["term13"], 4, 13)
        + hex_to_ansi(colours["term14"], 4, 14)
        + hex_to_ansi(colours["term15"], 4, 15)
        + hex_to_ansi(colours["primary"], 4, 16)
        + hex_to_ansi(colours["secondary"], 4, 17)
        + hex_to_ansi(colours["tertiary"], 4, 18)
    )


@log_exception
def apply_terms(sequences: str) -> None:
    state = c_state_dir / "sequences.txt"
    state.parent.mkdir(parents=True, exist_ok=True)
    state.write_text(sequences)

    pts_path = Path("/dev/pts")
    for pt in pts_path.iterdir():
        if pt.name.isdigit():
            try:
                # Use non-blocking write with timeout to prevent hangs
                import os

                fd = os.open(str(pt), os.O_WRONLY | os.O_NONBLOCK | os.O_NOCTTY)
                try:
                    os.write(fd, sequences.encode())
                finally:
                    os.close(fd)
            except (PermissionError, OSError, BlockingIOError):
                # Skip terminals that are busy, closed, or inaccessible
                pass


@log_exception
def apply_hypr(conf: str) -> None:
    ext = "lua" if is_lua_config() else "conf"
    atomic_write(config_dir / f"hypr/scheme/current.{ext}", conf)


@log_exception
def apply_discord(scss: str) -> None:
    with tempfile.TemporaryDirectory("w") as tmp_dir:
        (Path(tmp_dir) / "_colours.scss").write_text(scss)
        conf = subprocess.check_output(["sass", "-I", tmp_dir, templates_dir / "discord.scss"], text=True)

    for client in "Equicord", "Vencord", "BetterDiscord", "equibop", "vesktop", "legcord":
        atomic_write(config_dir / client / "themes/caelestia.theme.css", conf)


@log_exception
def apply_pandora(colours: dict[str, str], mode: str) -> None:
    template = gen_replace(colours, templates_dir / "pandora.json", hash=True)
    template = template.replace("{{ $mode }}", mode)
    atomic_write(data_dir / "PandoraLauncher/themes/caelestia.json", template)


@log_exception
def apply_spicetify(colours: dict[str, str], mode: str) -> None:
    template = gen_replace(colours, templates_dir / f"spicetify-{mode}.ini")
    atomic_write(config_dir / "spicetify/Themes/caelestia/color.ini", template)


@log_exception
def apply_fuzzel(colours: dict[str, str]) -> None:
    template = gen_replace(colours, templates_dir / "fuzzel.ini")
    atomic_write(config_dir / "fuzzel/fuzzel.ini", template)


@log_exception
def apply_btop(colours: dict[str, str]) -> None:
    template = gen_replace(colours, templates_dir / "btop.theme", hash=True)
    atomic_write(config_dir / "btop/themes/caelestia.theme", template)
    subprocess.run(["killall", "-USR2", "btop"], stderr=subprocess.DEVNULL)


@log_exception
def apply_nvtop(colours: dict[str, str]) -> None:
    template = gen_replace(colours, templates_dir / "nvtop.colors", hash=True)
    atomic_write(config_dir / "nvtop/nvtop.colors", template)


@log_exception
def apply_htop(colours: dict[str, str]) -> None:
    template = gen_replace(colours, templates_dir / "htop.theme", hash=True)
    atomic_write(config_dir / "htop/htoprc", template)
    subprocess.run(["killall", "-USR2", "htop"], stderr=subprocess.DEVNULL)


def sync_papirus_colors(hex_color: str) -> None:
    """Sync Papirus folder icon colors using hue/saturation analysis"""
    try:
        result = subprocess.run(["which", "papirus-folders"], capture_output=True, check=False)
        if result.returncode != 0:
            return
    except Exception:
        return

    papirus_paths = [
        Path("/usr/share/icons/Papirus"),
        Path("/usr/share/icons/Papirus-Dark"),
        Path.home() / ".local/share/icons/Papirus",
        Path.home() / ".icons/Papirus",
    ]

    if not any(p.exists() for p in papirus_paths):
        return

    r = int(hex_color[0:2], 16)
    g = int(hex_color[2:4], 16)
    b = int(hex_color[4:6], 16)

    # Brightness and saturation
    max_val = max(r, g, b)
    min_val = min(r, g, b)
    brightness = max_val
    saturation = 0 if max_val == 0 else ((max_val - min_val) * 100) // max_val

    # Low saturation = grayscale
    if saturation < 20:
        if brightness < 85:
            color = "black"
        elif brightness < 170:
            color = "grey"
        else:
            color = "white"
    # Medium-low saturation with high brightness = pale variants
    elif saturation < 60 and brightness > 180:
        use_pale = True
        color = _determine_hue_color(r, g, b, brightness, use_pale)
    else:
        color = _determine_hue_color(r, g, b, brightness, False)

    try:
        subprocess.Popen(
            ["sudo", "-n", "papirus-folders", "-C", color, "-u"],
            stderr=subprocess.DEVNULL,
            stdout=subprocess.DEVNULL,
            start_new_session=True,
        )
    except Exception:
        pass


def _determine_hue_color(r: int, g: int, b: int, brightness: int, use_pale: bool) -> str:
    if b > r and b > g:
        # Blue dominant
        r_ratio = (r * 100) // b if b > 0 else 0
        g_ratio = (g * 100) // b if b > 0 else 0
        rg_diff = abs(r - g)

        if r_ratio > 70 and g_ratio > 70:
            # Both R and G high relative to B = light blue/periwinkle
            if rg_diff < 15:
                return "blue"
            elif r > g:
                return "violet"
            else:
                return "cyan"
        elif r_ratio > 60 and r > g:
            return "violet"
        elif g_ratio > 60 and g > r:
            return "cyan"
        else:
            return "blue"
    elif r > g and r > b:
        # Red dominant
        if g > b + 30:
            # Orange/yellow-ish/brown
            rg_ratio = (g * 100) // r if r > 0 else 0
            if use_pale:
                if rg_ratio > 70 and brightness < 220:
                    return "palebrown"
                else:
                    return "paleorange"
            else:
                if rg_ratio > 70 and brightness < 180:
                    return "brown"
                else:
                    return "orange"
        elif b > g + 20:
            return "pink"
        else:
            return "pink" if use_pale else "red"
    elif g > r and g > b:
        # Green dominant
        if r > b + 30:
            return "yellow"
        else:
            return "green"
    else:
        return "grey"


@log_exception
def apply_gtk(colours: dict[str, str], mode: str, icon_theme: str | None = None) -> None:
    gtk_template = gen_replace(colours, templates_dir / "gtk.css", hash=True)
    thunar_template = gen_replace(colours, templates_dir / "thunar.css", hash=True)

    for gtk_version in ["gtk-3.0", "gtk-4.0"]:
        gtk_config_dir = config_dir / gtk_version
        atomic_write(gtk_config_dir / "gtk.css", gtk_template)
        atomic_write(gtk_config_dir / "thunar.css", thunar_template)

    subprocess.run(["dconf", "write", "/org/gnome/desktop/interface/gtk-theme", "'adw-gtk3-dark'"])
    subprocess.run(["dconf", "write", "/org/gnome/desktop/interface/color-scheme", f"'prefer-{mode}'"])
    gtk_icon_theme = icon_theme if icon_theme is not None else f"Papirus-{mode.capitalize()}"
    subprocess.run(["dconf", "write", "/org/gnome/desktop/interface/icon-theme", f"'{gtk_icon_theme}'"])

    sync_papirus_colors(colours["primary"])


@log_exception
def apply_qt(colours: dict[str, str], mode: str, icon_theme: str | None = None) -> None:
    colours = gen_replace(colours, templates_dir / f"qt{mode}.colors", hash=True)
    atomic_write(config_dir / "qtengine/caelestia.colors", colours)

    config = (templates_dir / "qtengine.json").read_text()
    config = config.replace("{{ $mode }}", mode.capitalize())
    if icon_theme is not None:
        config = config.replace(f'"iconTheme": "Papirus-{mode.capitalize()}"', f'"iconTheme": "{icon_theme}"')
    atomic_write(config_dir / "qtengine/config.json", config)


@log_exception
def apply_warp(colours: dict[str, str], mode: str) -> None:
    warp_mode = "darker" if mode == "dark" else "lighter"

    template = gen_replace(colours, templates_dir / "warp.yaml", hash=True)
    template = template.replace("{{ $warp_mode }}", warp_mode)
    atomic_write(data_dir / "warp-terminal/themes/caelestia.yaml", template)


def configure_chromium_use_system(base_dir: Path) -> None:
    if not base_dir.is_dir():
        return
    for profile in base_dir.iterdir():
        if profile.is_dir() and (profile / "Preferences").exists():
            pref_path = profile / "Preferences"
            try:
                data = json.loads(pref_path.read_text())
                ext = data.setdefault("extensions", {})
                theme = ext.setdefault("theme", {})
                theme["use_system"] = True
                atomic_write(pref_path, json.dumps(data))
            except Exception:
                pass


def apply_chromium(colours: dict[str, str]) -> None:
    surface_hex = colours["surface"]
    theme_color = f"#{surface_hex}"

    for user_dir in [
        Path.home() / ".config/BraveSoftware/Brave-Browser",
        Path.home() / ".config/google-chrome",
        Path.home() / ".config/chromium"
    ]:
        configure_chromium_use_system(user_dir)

    browsers = [
        ("chromium", Path("/etc/chromium/policies/managed")),
        ("brave", Path("/etc/brave/policies/managed")),
        ("google-chrome-stable", Path("/etc/opt/chrome/policies/managed")),
    ]

    for cmd, policy_dir in browsers:
        if shutil.which(cmd) is None:
            continue
        try:
            if not policy_dir.is_dir():
                subprocess.run(["sudo", "-n", "mkdir", "-p", str(policy_dir)], stderr=subprocess.DEVNULL)
            if not policy_dir.is_dir():
                continue

            res = subprocess.run(
                ["sudo", "-n", "tee", str(policy_dir / "caelestia.json")],
                input=json.dumps({"BrowserThemeColor": theme_color, "BrowserColorScheme": "device"}),
                text=True,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
            if res.returncode == 0:
                subprocess.run(
                    [cmd, "--refresh-platform-policy", "--no-startup-window"],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                    timeout=5,
                )
        except Exception:
            pass


def apply_zed(colours: dict[str, str], mode: str) -> None:
    theme_path = config_dir / "zed/themes/caelestia.json"
    # Zed's file watcher does not detect changes through symlinks,
    # so resolve to a regular file before writing
    if theme_path.is_symlink():
        theme_path.unlink()

    content = gen_replace_dynamic(colours, templates_dir / "zed.json", mode)
    atomic_write(theme_path, content)

@log_exception
def apply_alacritty(colours: dict[str, str]) -> None:
    path = config_dir / "alacritty/colours.toml"
    content = f"""# Nilastia Alacritty Theme
[colors.primary]
background = '#{colours.get("surface", "000000")}'
foreground = '#{colours.get("onSurface", "ffffff")}'

[colors.normal]
black = '#{colours.get("term0", "000000")}'
red = '#{colours.get("term1", "ff0000")}'
green = '#{colours.get("term2", "00ff00")}'
yellow = '#{colours.get("term3", "ffff00")}'
blue = '#{colours.get("term4", "0000ff")}'
magenta = '#{colours.get("term5", "ff00ff")}'
cyan = '#{colours.get("term6", "00ffff")}'
white = '#{colours.get("term7", "ffffff")}'

[colors.bright]
black = '#{colours.get("term8", "555555")}'
red = '#{colours.get("term9", "ff5555")}'
green = '#{colours.get("term10", "55ff55")}'
yellow = '#{colours.get("term11", "ffff55")}'
blue = '#{colours.get("term12", "5555ff")}'
magenta = '#{colours.get("term13", "ff55ff")}'
cyan = '#{colours.get("term14", "55ffff")}'
white = '#{colours.get("term15", "ffffff")}'
"""
    atomic_write(path, content)

    main_config = config_dir / "alacritty/alacritty.toml"
    import_line = 'import = ["~/.config/alacritty/colours.toml"]'
    if main_config.exists():
        try:
            content_main = main_config.read_text()
            if "colours.toml" not in content_main:
                atomic_write(main_config, import_line + "\n" + content_main)
        except Exception:
            pass
    else:
        atomic_write(main_config, import_line + "\n")


@log_exception
def apply_kitty(colours: dict[str, str]) -> None:
    path = config_dir / "kitty/theme.conf"
    content = f"""# Nilastia Kitty Theme
background #{colours.get("surface", "000000")}
foreground #{colours.get("onSurface", "ffffff")}
cursor #{colours.get("secondary", "ffffff")}
selection_background #{colours.get("secondary", "ffffff")}
selection_foreground #{colours.get("surface", "000000")}

color0 #{colours.get("term0", "000000")}
color1 #{colours.get("term1", "ff0000")}
color2 #{colours.get("term2", "00ff00")}
color3 #{colours.get("term3", "ffff00")}
color4 #{colours.get("term4", "0000ff")}
color5 #{colours.get("term5", "ff00ff")}
color6 #{colours.get("term6", "00ffff")}
color7 #{colours.get("term7", "ffffff")}

color8 #{colours.get("term8", "555555")}
color9 #{colours.get("term9", "ff5555")}
color10 #{colours.get("term10", "55ff55")}
color11 #{colours.get("term11", "ffff55")}
color12 #{colours.get("term12", "5555ff")}
color13 #{colours.get("term13", "ff55ff")}
color14 #{colours.get("term14", "55ffff")}
color15 #{colours.get("term15", "ffffff")}
"""
    atomic_write(path, content)

    main_config = config_dir / "kitty/kitty.conf"
    if main_config.exists():
        try:
            content_main = main_config.read_text()
            if not re.search(r'(?m)^\s*include\s+theme\.conf', content_main):
                with open(main_config, "a") as f:
                    f.write("\ninclude theme.conf\n")
        except Exception:
            pass
    else:
        atomic_write(main_config, "include theme.conf\n")

    subprocess.run(["killall", "-USR1", "kitty"], stderr=subprocess.DEVNULL)


@log_exception
def apply_neovim(colours: dict[str, str]) -> None:
    path = config_dir / "nvim/lua/nilastia_theme.lua"
    content = "-- Nilastia Neovim Palette\nreturn {\n"
    for name, val in colours.items():
        clean_name = re.sub(r'[^a-zA-Z0-9_]', '_', name)
        content += f'  {clean_name} = "#{val}",\n'
    content += "}\n"
    atomic_write(path, content)


@log_exception
def apply_vscode_like(colours: dict[str, str], config_name: str) -> None:
    settings_path = config_dir / f"{config_name}/User/settings.json"
    if not settings_path.parent.is_dir():
        return

    try:
        if settings_path.exists():
            data = json.loads(settings_path.read_text())
        else:
            data = {}
    except Exception:
        data = {}

    bg = f"#{colours.get('surface', '131317')}"
    fg = f"#{colours.get('onSurface', 'e5e1e7')}"
    primary = f"#{colours.get('primary', 'c2c1ff')}"
    accent = f"#{colours.get('secondary', 'c6c4e0')}"
    border = f"#{colours.get('outlineVariant', '47464f')}"
    activity_bar_bg = f"#{colours.get('surfaceContainerLow', '1c1b1f')}"
    sidebar_bg = f"#{colours.get('surfaceContainerLow', '1c1b1f')}"
    editor_bg = f"#{colours.get('surface', '131317')}"

    customizations = data.setdefault("workbench.colorCustomizations", {})
    customizations["editor.background"] = editor_bg
    customizations["editor.foreground"] = fg
    customizations["activityBar.background"] = activity_bar_bg
    customizations["activityBar.foreground"] = primary
    customizations["activityBar.inactiveForeground"] = f"{fg}80"
    customizations["sideBar.background"] = sidebar_bg
    customizations["sideBar.foreground"] = fg
    customizations["sideBar.border"] = border
    customizations["editorGroupHeader.tabsBackground"] = activity_bar_bg
    customizations["tab.activeBackground"] = editor_bg
    customizations["tab.activeForeground"] = primary
    customizations["tab.inactiveBackground"] = activity_bar_bg
    customizations["tab.inactiveForeground"] = f"{fg}80"
    customizations["statusBar.background"] = activity_bar_bg
    customizations["statusBar.foreground"] = fg
    customizations["titleBar.activeBackground"] = activity_bar_bg
    customizations["titleBar.activeForeground"] = fg

    try:
        with open(settings_path, "w") as f:
            json.dump(data, f, indent=4)
    except Exception:
        pass


@log_exception
def apply_firefox_like(colours: dict[str, str], base_dir: Path) -> None:
    if not base_dir.is_dir():
        return
    
    bg = f"#{colours.get('surface', '131317')}"
    fg = f"#{colours.get('onSurface', 'e5e1e7')}"
    primary = f"#{colours.get('primary', 'c2c1ff')}"
    on_primary = f"#{colours.get('onPrimary', '000000')}"
    border = f"#{colours.get('outlineVariant', '47464f')}"
    
    css_content = f"""/* Nilastia Theme */
:root {{
  --toolbar-bgcolor: {bg} !important;
  --toolbar-color: {fg} !important;
  --tab-selected-bgcolor: {primary} !important;
  --tab-selected-color: {on_primary} !important;
  --tab-background-color: {bg} !important;
  --lwt-accent-color: {bg} !important;
  --lwt-text-color: {fg} !important;
  --lwt-selected-tab-background-color: {primary} !important;
  --chrome-content-separator-color: {border} !important;
}}
"""
    for profile in base_dir.iterdir():
        if profile.is_dir() and (profile / "prefs.js").exists():
            chrome_dir = profile / "chrome"
            chrome_dir.mkdir(parents=True, exist_ok=True)
            atomic_write(chrome_dir / "userChrome.css", css_content)


@log_exception
def apply_cava(colours: dict[str, str]) -> None:
    template = gen_replace(colours, templates_dir / "cava.conf", hash=True)
    atomic_write(config_dir / "cava/config", template)
    subprocess.run(["killall", "-USR2", "cava"], stderr=subprocess.DEVNULL)


@log_exception
def apply_user_templates(colours: dict[str, str], mode: str) -> None:
    if not user_templates_dir.is_dir():
        return

    for file in user_templates_dir.iterdir():
        if file.is_file():
            content = gen_replace_dynamic(colours, file, mode)
            atomic_write(theme_dir / file.name, content)


def check_app_status(key: str, cfg: dict) -> str:
    if not (cfg[key] if key in cfg else True):
        return "Disabled"
    
    if key == "enableTerm":
        return "Applied"
        
    elif key == "enableAlacritty":
        if shutil.which("alacritty") or (config_dir / "alacritty").is_dir():
            return "Applied"
        return "Not Installed"
        
    elif key == "enableKitty":
        if shutil.which("kitty") or (config_dir / "kitty").is_dir():
            return "Applied"
        return "Not Installed"
        
    elif key == "enableNeovim":
        if shutil.which("nvim") or (config_dir / "nvim").is_dir():
            return "Applied"
        return "Not Installed"
        
    elif key == "enableVSCode":
        if (config_dir / "Code").is_dir() or (config_dir / "VSCodium").is_dir():
            return "Applied"
        return "Not Installed"
        
    elif key == "enableCursor":
        if (config_dir / "Cursor").is_dir():
            return "Applied"
        return "Not Installed"
        
    elif key == "enableAntigravity":
        if (config_dir / "Antigravity").is_dir() or (config_dir / "Antigravity IDE").is_dir():
            return "Applied"
        return "Not Installed"
        
    elif key == "enableZed":
        if shutil.which("zed") or shutil.which("zeditor") or (config_dir / "zed").is_dir():
            return "Applied"
        return "Not Installed"
        
    elif key == "enableChromium":
        browsers_found = False
        for cmd in ["chromium", "brave", "google-chrome-stable", "google-chrome"]:
            if shutil.which(cmd):
                browsers_found = True
                break
        if not browsers_found:
            return "Not Installed"
        return "Applied"
        
    elif key == "enableFirefox":
        if (Path.home() / ".mozilla/firefox").is_dir():
            return "Applied"
        return "Not Installed"
        
    elif key == "enableZen":
        if (Path.home() / ".zen").is_dir():
            return "Applied"
        return "Not Installed"
        
    elif key == "enableDiscord":
        discord_found = False
        for client in ["Equicord", "Vencord", "BetterDiscord", "equibop", "vesktop", "legcord"]:
            if (config_dir / client).is_dir():
                discord_found = True
                break
        if not discord_found:
            return "Not Installed"
        return "Applied"
        
    elif key == "enableSpicetify":
        if shutil.which("spicetify") or (config_dir / "spicetify").is_dir():
            return "Applied"
        return "Not Installed"
        
    elif key in ["enableGtk", "enableQt", "enableHypr", "enableFuzzel", "enableBtop", "enableNvtop", "enableHtop", "enableCava"]:
        return "Applied"
        
    return "Applied"


def apply_colours(colours: dict[str, str], mode: str) -> None:
    # Use file-based lock to prevent concurrent theme changes
    lock_file = c_state_dir / "theme.lock"
    c_state_dir.mkdir(parents=True, exist_ok=True)

    try:
        with open(lock_file, "w") as lock_fd:
            try:
                fcntl.flock(lock_fd.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
            except BlockingIOError:
                return

            cfg = get_config().get("theme", {})

            def check(key: str) -> bool:
                return cfg[key] if key in cfg else True

            status = {}
            for key in [
                "enableTerm", "enableAlacritty", "enableKitty", "enableNeovim",
                "enableVSCode", "enableCursor", "enableAntigravity", "enableZed",
                "enableChromium", "enableFirefox", "enableZen", "enableGtk",
                "enableQt", "enableDiscord", "enableSpicetify", "enableCava",
                "enableBtop", "enableHtop", "enableNvtop", "enableFuzzel", "enableHypr"
            ]:
                status[key] = check_app_status(key, cfg)

            if status.get("enableTerm") == "Applied":
                apply_terms(gen_sequences(colours))
            if status.get("enableHypr") == "Applied":
                apply_hypr(gen_lua(colours) if is_lua_config() else gen_conf(colours))
            if status.get("enableDiscord") == "Applied":
                apply_discord(gen_scss(colours))
            if status.get("enableSpicetify") == "Applied":
                apply_spicetify(colours, mode)
            if check("enablePandora"):
                apply_pandora(colours, mode)
            if status.get("enableFuzzel") == "Applied":
                apply_fuzzel(colours)
            if status.get("enableBtop") == "Applied":
                apply_btop(colours)
            if status.get("enableNvtop") == "Applied":
                apply_nvtop(colours)
            if status.get("enableHtop") == "Applied":
                apply_htop(colours)
            icon_theme = cfg.get(f"iconTheme{mode.capitalize()}") or cfg.get("iconTheme")
            if status.get("enableGtk") == "Applied":
                apply_gtk(colours, mode, icon_theme)
            if status.get("enableQt") == "Applied":
                apply_qt(colours, mode, icon_theme)
            if check("enableWarp"):
                apply_warp(colours, mode)
            
            if status.get("enableChromium") == "Applied":
                apply_chromium(colours)
            
            if status.get("enableZed") == "Applied":
                apply_zed(colours, mode)
            if status.get("enableAlacritty") == "Applied":
                apply_alacritty(colours)
            if status.get("enableKitty") == "Applied":
                apply_kitty(colours)
            if status.get("enableNeovim") == "Applied":
                apply_neovim(colours)
            if status.get("enableVSCode") == "Applied":
                apply_vscode_like(colours, "Code")
                if (config_dir / "VSCodium").is_dir():
                    apply_vscode_like(colours, "VSCodium")
            if status.get("enableCursor") == "Applied":
                apply_vscode_like(colours, "Cursor")
            if status.get("enableAntigravity") == "Applied":
                apply_vscode_like(colours, "Antigravity")
                apply_vscode_like(colours, "Antigravity IDE")
            if status.get("enableFirefox") == "Applied":
                apply_firefox_like(colours, Path.home() / ".mozilla/firefox")
            if status.get("enableZen") == "Applied":
                apply_firefox_like(colours, Path.home() / ".zen")
            if status.get("enableCava") == "Applied":
                apply_cava(colours)
            apply_user_templates(colours, mode)

            # Save the final status map atomically
            status_path = c_state_dir / "theme_status.json"
            atomic_write(status_path, json.dumps(status, indent=4))

            if post_hook := cfg.get("postHook"):
                scheme = get_scheme()
                subprocess.run(
                    post_hook,
                    shell=True,
                    env={
                        **os.environ,
                        "SCHEME_NAME": scheme.name,
                        "SCHEME_FLAVOUR": scheme.flavour,
                        "SCHEME_MODE": scheme.mode,
                        "SCHEME_VARIANT": scheme.variant,
                        "SCHEME_COLOURS": json.dumps(scheme.colours),
                    },
                    stderr=subprocess.DEVNULL,
                )

    finally:
        try:
            lock_file.unlink()
        except FileNotFoundError:
            pass
