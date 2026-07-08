"""Run on Start applet - flag standard lab-utils scripts to run at platform start.

Toggling a script ON drops a symlink into ~/.local/start-platform.d, where the
platform's user-script runner (58_user_scripts.sh, ENABLE_LOCAL_SCRIPTS=1)
executes every entry at each start - output lands in
~/.local/start-platform.out and a JupyterLab notification reports the result.
Toggling OFF removes the symlink. The user's own files in that directory are
never touched: only symlinks pointing into the managed source groups are ours.

This spares users from writing wrapper scripts just to re-run a standard
action (e.g. install an extra conda environment) on every start.
"""

from pathlib import Path

from rich.text import Text
from textual.app import App, ComposeResult
from textual.binding import Binding
from textual.containers import Container, Horizontal
from textual.widgets import Footer, OptionList, Static
from textual.widgets.option_list import Option

from . import config, menu as menu_mod
from .theme import DUO, HEADER_CSS, PASTEL, VERSION

APPLET_TITLE = "Run on Start"
TARGET_DIR = Path.home() / ".local" / "start-platform.d"
NOTE = ("Flagged scripts run at EVERY platform start (output: "
        "~/.local/start-platform.out) - changes apply from the next start.")


def source_groups() -> list:
    """Standard script groups offered for run-on-start, resolved from the
    package's data root at call time (config.py owns the path authority, and
    DUOPTIMUM_LAB_UTILS_HOME must redirect this applet like the rest of the
    tool). list_scripts applies the executable filter - the runner
    (58_user_scripts.sh) executes entries directly, so ~/.local/conda-env.d
    YAML recipes are out (they need the menu's yml wrapper)."""
    base = config.global_scripts_dir()
    return [
        ("conda env", base / "install-conda-env.d"),
        ("ai assistant", base / "install-ai-assistant.d"),
        ("infrastructure", base / "install-infrastructure.d"),
    ]


def menu_display_names() -> dict:
    """script filename -> the product name the menu shows for it (e.g. torch.sh ->
    "PyTorch"), so the applet speaks the same vocabulary as the menu. Empty on any
    config trouble - callers fall back to a title-cased stem."""
    try:
        # existence pre-check: load_menu_config sys.exit(1)s on a missing file
        # (correct for the menu CLI, fatal for a cosmetic name lookup)
        if not config.menu_config_path().exists():
            return {}
        cfg = menu_mod.load_menu_config().get("menu", {})
    except (Exception, SystemExit):
        return {}
    names = {}

    def walk(items):
        for item in items:
            if "submenu" in item:
                walk(item.get("submenu") or [])
            elif item.get("id") and item.get("name"):
                names[Path(item["id"]).name] = item["name"]

    walk(cfg.get("items", []))
    return names


def display_name(script: Path, names: dict) -> str:
    return names.get(script.name) or script.stem.replace("-", " ").replace("_", " ").title()


def list_scripts(groups=None) -> list:
    """(group, script_path) for every executable in the source groups, sorted."""
    entries = []
    for group, directory in (groups or source_groups()):
        try:
            candidates = sorted(directory.iterdir())
        except OSError:
            continue
        for path in candidates:
            if path.is_file() and not path.is_symlink() and path.stat().st_mode & 0o111:
                entries.append((group, path))
    return entries


def link_path(script: Path, target_dir: Path = TARGET_DIR) -> Path:
    return target_dir / script.name


def is_enabled(script: Path, target_dir: Path = TARGET_DIR) -> bool:
    link = link_path(script, target_dir)
    try:
        return link.is_symlink() and link.resolve() == script.resolve()
    except OSError:
        return False


def enable(script: Path, target_dir: Path = TARGET_DIR) -> None:
    target_dir.mkdir(parents=True, exist_ok=True)
    link = link_path(script, target_dir)
    if link.is_symlink():
        link.unlink()
    elif link.exists():
        # a real user file of the same name lives there - never overwrite it
        raise FileExistsError(f"{link} exists and is not a managed symlink")
    link.symlink_to(script)


def disable(script: Path, target_dir: Path = TARGET_DIR) -> None:
    link = link_path(script, target_dir)
    if link.is_symlink():
        link.unlink()


class OnStartApp(App):
    """Toggle standard lab-utils scripts to run at every platform start."""

    TITLE = APPLET_TITLE
    ENABLE_COMMAND_PALETTE = False
    CSS = f"""
    Screen {{ background: {DUO['bg_dim']}; }}
{HEADER_CSS}
    #onstart-note {{
        height: auto; padding: 0 2;
        background: {DUO['bg_subtle']}; color: {PASTEL['info']};
    }}
    #onstart-container {{ width: 100%; height: 1fr; padding: 1 2; }}
    OptionList {{
        width: 100%; height: 100%;
        border: round {DUO['border']};
        background: {DUO['bg_dim']}; color: {DUO['text']};
        padding: 0 1;
    }}
    OptionList:focus {{ border: round {DUO['cyan']}; }}
    OptionList > .option-list--option-highlighted {{
        background: {DUO['surface']}; color: {DUO['text']}; text-style: bold;
    }}
    OptionList:focus > .option-list--option-highlighted {{
        background: {DUO['surface']}; color: {DUO['text']}; text-style: bold;
    }}
    Footer {{ background: {DUO['bg_subtle']}; color: {DUO['text_muted']}; }}
    """

    # priority: the focused OptionList consumes plain space before app bindings
    BINDINGS = [
        Binding("space", "toggle", "Toggle", show=True, priority=True),
        Binding("escape", "quit", "Quit", show=True),
        Binding("q", "quit", "Quit", show=False),
        Binding("ctrl+c", "quit", "Quit", show=False),
    ]

    def __init__(self, groups=None, target_dir: Path = TARGET_DIR):
        super().__init__()
        self.groups = groups or source_groups()
        self.target_dir = target_dir
        self.scripts = []

    def compose(self) -> ComposeResult:
        with Horizontal(id="app-header"):
            yield Static(APPLET_TITLE, id="hdr-title")
            yield Static(f"v{VERSION}", id="hdr-version")
        yield Static(NOTE, id="onstart-note")
        with Container(id="onstart-container"):
            yield OptionList(id="script-list")
        yield Footer()

    def on_mount(self) -> None:
        self.refresh_list()
        self.query_one("#script-list", OptionList).focus()

    def refresh_list(self) -> None:
        option_list = self.query_one("#script-list", OptionList)
        highlighted = option_list.highlighted
        option_list.clear_options()
        self.scripts = list_scripts(self.groups)
        if not self.scripts:
            option_list.add_option(Option("(no standard scripts found)", disabled=True))
            return
        names = menu_display_names()
        for group, script in self.scripts:
            enabled = is_enabled(script, self.target_dir)
            # state = text mark AND colour (mint when on), never colour alone -
            # "[ on]" vs "[off]" at uniform weight has zero scanning salience
            row = Text()
            if enabled:
                row.append("[ on]", style=PASTEL["ok"])
            else:
                row.append("[off]", style=PASTEL["nav"])
            row.append(f" {group:<14} ")
            row.append(display_name(script, names),
                       style=PASTEL["ok"] if enabled else PASTEL["name"])
            option_list.add_option(Option(row, id=str(script)))
        if highlighted is not None and highlighted < len(self.scripts):
            option_list.highlighted = highlighted
        else:
            option_list.highlighted = 0

    def action_toggle(self) -> None:
        option_list = self.query_one("#script-list", OptionList)
        if option_list.highlighted is None or not self.scripts:
            return
        script = Path(option_list.get_option_at_index(option_list.highlighted).id)
        try:
            if is_enabled(script, self.target_dir):
                disable(script, self.target_dir)
            else:
                enable(script, self.target_dir)
        except (OSError, FileExistsError) as err:
            self.notify(str(err), severity="error")
        self.refresh_list()

    def on_option_list_option_selected(self, event: OptionList.OptionSelected) -> None:
        # Enter toggles too
        self.action_toggle()


def main() -> None:
    OnStartApp().run()


if __name__ == "__main__":
    main()
