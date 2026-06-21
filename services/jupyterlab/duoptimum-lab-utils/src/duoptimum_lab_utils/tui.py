"""Textual UI: the Duoptimum-styled menu and selector screens, plus the run loop
that executes a chosen item and re-shows the menu.

Item type is conveyed by colour and text, never pictographic glyphs: submenus in
cyan, attention tags (markers, selector values) in amber, leaf names in default
text, Back/Exit in muted text. The current row uses a subtle surface highlight.
"""

import subprocess

from rich.text import Text
from textual.app import App, ComposeResult
from textual.binding import Binding
from textual.containers import Container, Horizontal
from textual.widgets import Footer, OptionList, Static
from textual.widgets.option_list import Option

from . import cli, config, menu as menu_mod
from .resolver import resolve_script_path
from .selectors import apply_selector_choice, get_selector_current, get_selector_options
from .theme import APP_TITLE, DUO, HEADER_CSS, PASTEL, VERSION
from .util import flush_input_buffer


def _drop_theme_command(app, screen):
    """Yield the default system commands minus the Theme switcher (fixed brand theme)."""
    for cmd in super(type(app), app).get_system_commands(screen):
        if cmd.title != "Theme":
            yield cmd


class LabUtilsApp(App):
    """YAML-driven hierarchical menu."""

    TITLE = APP_TITLE
    CSS = f"""
    Screen {{ background: {DUO['bg_dim']}; }}
{HEADER_CSS}
    #breadcrumb {{
        height: 1;
        padding: 0 2;
        background: {DUO['bg_subtle']};
        color: {DUO['text_muted']};
        text-style: italic;
    }}
    #menu-container {{ width: 100%; height: 1fr; padding: 1 2; }}
    OptionList {{
        width: 100%;
        height: 100%;
        border: round {DUO['border']};
        background: {DUO['bg_dim']};
        color: {DUO['text']};
        padding: 0 1;
    }}
    OptionList:focus {{ border: round {DUO['cyan']}; }}
    OptionList > .option-list--option-highlighted {{
        background: {DUO['surface']};
        color: {DUO['text']};
        text-style: bold;
    }}
    OptionList:focus > .option-list--option-highlighted {{
        background: {DUO['surface']};
        color: {DUO['text']};
        text-style: bold;
    }}
    Footer {{ background: {DUO['bg_subtle']}; color: {DUO['text_muted']}; }}
    """

    BINDINGS = [
        Binding("escape", "quit", "Quit", show=True),
        Binding("ctrl+c", "quit", "Quit", show=False),
        Binding("left", "go_back", "Back", show=True),
        Binding("backspace", "go_back", "Back", show=False),
        Binding("right", "select_item", "Select", show=True),
    ]

    def __init__(self, root_menu: dict):
        super().__init__()
        self.root_menu = root_menu
        self.menu_stack = []  # (title, items)
        self.current_items = []
        self.pending_command = None

    def get_system_commands(self, screen):
        yield from _drop_theme_command(self, screen)

    def compose(self) -> ComposeResult:
        with Horizontal(id="app-header"):
            yield Static(APP_TITLE, id="hdr-title")
            yield Static(f"v{VERSION}", id="hdr-version")
        yield Static("", id="breadcrumb")
        with Container(id="menu-container"):
            yield OptionList(id="menu")
        yield Footer()

    def on_mount(self) -> None:
        self.push_menu(self.root_menu.get("title", "Lab Utils"),
                       self.root_menu.get("items", []))

    def push_menu(self, title: str, items: list) -> None:
        self.menu_stack.append((title, items))
        self.current_items = items
        self.refresh_menu()

    def pop_menu(self) -> bool:
        if len(self.menu_stack) <= 1:
            return False
        self.menu_stack.pop()
        _, items = self.menu_stack[-1]
        self.current_items = items
        self.refresh_menu()
        return True

    def get_breadcrumb(self) -> str:
        return " > ".join(t for t, _ in self.menu_stack)

    def _item_text(self, item: dict, index: int) -> Text:
        """Build a no-glyph option label, type conveyed by colour and text."""
        name = item.get("name", f"Item {index}")
        desc = item.get("description", "")

        if "submenu" in item or "scan_dir" in item or "menu_file" in item:
            # trailing "/" signals "descends" in text (not colour alone), matching
            # the CLI tree, so submenu vs leaf is distinguishable without hue
            return Text(f"{name}/", style=PASTEL["submenu"])

        if "selector" in item:
            current = get_selector_current(item["selector"])
            opts = get_selector_options(item["selector"])
            current_label = next(
                (o.get("label", o["value"]) for o in opts if o.get("value") == current),
                current,
            )
            line = Text()
            line.append(f"{name} ", style=PASTEL["name"])
            line.append(f"[{current_label or 'not set'}]", style=PASTEL["tag"])
            return line

        # Script / command leaf.
        line = Text()
        marker = item.get("marker", "")
        if marker:
            line.append(f"[{marker}] ", style=PASTEL["tag"])
        line.append(name, style=PASTEL["name"])
        if desc:
            line.append(f" - {desc}", style=PASTEL["desc"])
        return line

    def refresh_menu(self) -> None:
        menu = self.query_one("#menu", OptionList)
        breadcrumb = self.query_one("#breadcrumb", Static)

        menu.clear_options()
        breadcrumb.update(self.get_breadcrumb())

        if len(self.menu_stack) > 1:
            menu.add_option(Option(Text("Back", style=PASTEL["nav"]), id="__back__"))
        else:
            menu.add_option(Option(Text("Exit", style=PASTEL["nav"]), id="__exit__"))
        menu.add_option(None)

        for i, item in enumerate(self.current_items):
            menu.add_option(Option(self._item_text(item, i), id=str(i)))

        if self.current_items:
            menu.highlighted = 1

    def on_option_list_option_selected(self, event: OptionList.OptionSelected) -> None:
        option_id = event.option.id

        if option_id == "__exit__":
            self.exit()
            return
        if option_id == "__back__":
            self.pop_menu()
            return

        try:
            selected_item = self.current_items[int(option_id)]
        except (ValueError, IndexError):
            return

        item_name = selected_item.get("name", "")

        if "selector" in selected_item:
            self.pending_command = (selected_item["selector"], item_name, "selector")
            self.exit()
            return

        if "submenu" in selected_item or "scan_dir" in selected_item or "menu_file" in selected_item:
            submenu_items = list(selected_item.get("submenu", []))
            if "menu_file" in selected_item:
                submenu_items.extend(menu_mod.load_menu_file_items(selected_item["menu_file"]))
            if "scan_dir" in selected_item:
                submenu_items.extend(menu_mod.scan_directory_for_menu_items(selected_item["scan_dir"]))

            if submenu_items:
                self.push_menu(item_name, submenu_items)
            else:
                self.notify(f"No items found in {item_name}", severity="warning")

        elif "id" in selected_item:
            item_type = selected_item.get("type", "script")
            item_id = selected_item["id"]

            if selected_item.get("_conda_env"):
                self.pending_command = (item_id, item_name, "conda_env")
                self.exit()
            elif item_type == "command":
                self.pending_command = (item_id, item_name, "command")
                self.exit()
            else:
                script_path = resolve_script_path(item_id, selected_item.get("_full_path", False))
                if script_path is None:
                    self.notify(f"Script not found: {item_id}", severity="error")
                    return
                self.pending_command = (str(script_path), item_name, "script")
                self.exit()

    def action_go_back(self) -> None:
        if not self.pop_menu():
            self.exit()

    def action_select_item(self) -> None:
        menu = self.query_one("#menu", OptionList)
        if menu.highlighted is not None:
            menu.action_select()


class SelectorApp(App):
    """Single-choice selector for a configured option list."""

    CSS = f"""
    Screen {{ background: {DUO['bg_dim']}; }}
{HEADER_CSS}
    #info {{
        height: 3;
        padding: 1 2;
        background: {DUO['bg_subtle']};
        color: {DUO['text']};
    }}
    #menu-container {{ width: 100%; height: 1fr; padding: 1 2; }}
    OptionList {{
        width: 100%;
        height: 100%;
        border: round {DUO['border']};
        background: {DUO['bg_dim']};
        color: {DUO['text']};
        padding: 0 1;
    }}
    OptionList:focus {{ border: round {DUO['cyan']}; }}
    OptionList > .option-list--option-highlighted {{
        background: {DUO['surface']};
        color: {DUO['text']};
        text-style: bold;
    }}
    OptionList:focus > .option-list--option-highlighted {{
        background: {DUO['surface']};
        color: {DUO['text']};
        text-style: bold;
    }}
    Footer {{ background: {DUO['bg_subtle']}; color: {DUO['text_muted']}; }}
    """

    BINDINGS = [
        Binding("escape", "quit", "Cancel", show=True),
        Binding("ctrl+c", "quit", "Cancel", show=False),
        Binding("left", "quit", "Cancel", show=False),
        Binding("right", "select_item", "Select", show=True),
    ]

    def __init__(self, options: list, selector_config: dict, title: str):
        super().__init__()
        self.title = title
        self.options = options
        self.selector_config = selector_config
        self.selected = None

    def get_system_commands(self, screen):
        yield from _drop_theme_command(self, screen)

    def compose(self) -> ComposeResult:
        current = next((o.get("label", o["value"]) for o in self.options if o.get("current")), "Not set")
        header_label = self.selector_config.get("current_header", "Current")
        with Horizontal(id="app-header"):
            yield Static(self.title, id="hdr-title")
            yield Static(f"v{VERSION}", id="hdr-version")
        info = Text()
        info.append(f"{header_label}: ", style=PASTEL["desc"])
        info.append(current, style=PASTEL["tag"])
        yield Static(info, id="info")
        with Container(id="menu-container"):
            yield OptionList(id="menu")
        yield Footer()

    def on_mount(self) -> None:
        menu = self.query_one("#menu", OptionList)
        current_marker = self.selector_config.get("current_marker", "(current)")
        for opt in self.options:
            label = Text()
            label.append(opt.get("label", opt["value"]), style=PASTEL["name"])
            if opt.get("current"):
                label.append(f" {current_marker}", style=PASTEL["tag"])
            menu.add_option(Option(label, id=opt["value"]))
        menu.add_option(None)
        menu.add_option(Option(Text("Cancel", style=PASTEL["nav"]), id="__cancel__"))
        if self.options:
            menu.highlighted = 0

    def on_option_list_option_selected(self, event: OptionList.OptionSelected) -> None:
        if event.option.id != "__cancel__":
            self.selected = event.option.id
        self.exit()

    def action_select_item(self) -> None:
        menu = self.query_one("#menu", OptionList)
        if menu.highlighted is not None:
            menu.action_select()


def run_selector(selector_config: dict, title: str) -> None:
    """Show the selector, then apply the chosen value and report the result."""
    options = get_selector_options(selector_config)
    if not options:
        print(f"No options available for {title}")
        try:
            input("\nPress Enter to continue...")
        except KeyboardInterrupt:
            print()
        return

    app = SelectorApp(options, selector_config, title)
    app.run()
    flush_input_buffer()

    if app.selected:
        cli.print_section_header(title)
        try:
            result = apply_selector_choice(selector_config, app.selected)
            cli.print_result(result.returncode)
        except KeyboardInterrupt:
            cli.print_cancelled()
        try:
            input("\nPress Enter to continue...")
        except KeyboardInterrupt:
            print()


def run_interactive_menu() -> None:
    """Run the menu, then execute the chosen item and loop back to the menu.

    A loop, not tail recursion: a long session would otherwise grow the Python
    stack one frame per executed item and eventually overflow. Config reloads
    each pass so newly installed scripts/envs appear.
    """
    while True:
        config_data = menu_mod.load_menu_config()
        root_menu = config_data.get("menu", {})

        app = LabUtilsApp(root_menu)
        app.run()
        flush_input_buffer()

        if not app.pending_command:
            return

        cmd_or_path, title, cmd_type = app.pending_command

        if cmd_type == "selector":
            run_selector(cmd_or_path, title)
            continue

        cli.print_section_header(title)
        try:
            if cmd_type == "conda_env":
                print(f"Installing conda environment from: {cmd_or_path}")
                result = subprocess.run(["conda", "env", "create", "-f", cmd_or_path])
            elif cmd_type == "command":
                result = subprocess.run(cmd_or_path, shell=True)
            else:
                result = subprocess.run([cmd_or_path])
            cli.print_result(result.returncode)
        except KeyboardInterrupt:
            cli.print_cancelled()

        try:
            input("\nPress Enter to continue...")
        except KeyboardInterrupt:
            print()
