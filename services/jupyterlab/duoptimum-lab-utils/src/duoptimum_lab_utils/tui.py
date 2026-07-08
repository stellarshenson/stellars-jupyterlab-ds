"""Textual UI: the Duoptimum-styled menu and selector screens, plus the run loop
that executes a chosen item and re-shows the menu.

Item type is conveyed by colour and text, never pictographic glyphs: submenus in
cyan, attention tags (markers, selector values) in amber, leaf names in default
text, Back/Exit in muted text. The current row uses a subtle surface highlight.

Type-to-filter: typing in the menu filters commands as-you-type across the whole
subtree (not just the current level), each match shown with its submenu ancestor
path and the typed substring highlighted. The standard Textual command palette is
disabled - the in-menu filter replaces it, so there is no confusing popup.
"""

import os
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


def _is_submenu(item: dict) -> bool:
    return "submenu" in item or "scan_dir" in item or "menu_file" in item


def _expand_submenu(item: dict) -> list:
    """Resolve a submenu item's children (inline + menu_file + scan_dir)."""
    children = list(item.get("submenu", []))
    if "menu_file" in item:
        children.extend(menu_mod.load_menu_file_items(item["menu_file"]))
    if "scan_dir" in item:
        children.extend(menu_mod.scan_directory_for_menu_items(item["scan_dir"]))
    return children


class LabUtilsApp(App):
    """YAML-driven hierarchical menu with type-to-filter."""

    TITLE = APP_TITLE
    ENABLE_COMMAND_PALETTE = False  # in-menu filter replaces the standard palette
    CSS = f"""
    Screen {{ background: {DUO['bg_dim']}; }}
{HEADER_CSS}
    #breadcrumb {{
        height: 1;
        padding: 0 2;
        background: {DUO['bg_subtle']};
        color: {DUO['text_muted']};
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

    # escape carries THREE bindings: check_action gates which one is live (and
    # thus which label the Footer shows) - "Clear filter" while a filter is
    # typed, "Back" inside a submenu, "Quit" at the root. left mirrors escape's
    # clear-vs-back split so it keeps working under a filter
    BINDINGS = [
        Binding("escape", "clear_filter", "Clear filter", show=True),
        Binding("escape", "go_back", "Back", show=True),
        Binding("escape", "quit_app", "Quit", show=True),
        Binding("ctrl+c", "quit", "Quit", show=False),
        Binding("left", "clear_filter", "Clear filter", show=False),
        Binding("left", "go_back", "Back", show=False),
        Binding("right", "select_item", "Select", show=True),
    ]

    def __init__(self, root_menu: dict, initial_path: list = None,
                 initial_highlight: int = None):
        super().__init__()
        self.root_menu = root_menu
        self.menu_stack = []  # (title, items)
        self.current_items = []
        self.pending_command = None
        self.filter_query = ""
        self._flat_index = None   # lazily built per menu level
        self.filtered = []        # (path, item) currently shown under a filter
        # position restore: the run loop recreates the app after every executed
        # item - without this, running two items in one submenu means re-navigating
        # from the root each time
        self.initial_path = initial_path or []      # submenu titles to re-descend
        self.initial_highlight = initial_highlight  # row to re-highlight
        self.exit_path = []                         # position captured at execution
        self.exit_highlight = None
        self._highlight_stack = []                  # parent rows to restore on Back
        self._selector_row_cache = {}               # id(item) -> current value

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
        # restore the pre-execution position: re-descend the recorded submenu path
        # (pointing each parent row at the submenu it descends into, so Back lands
        # right), then re-highlight the row that was executed
        for title in self.initial_path:
            match = next((it for it in self.current_items
                          if it.get("name") == title and _is_submenu(it)), None)
            if match is None:
                break
            try:
                children = _expand_submenu(match)
            except Exception:
                break
            if not children:
                break
            self.query_one("#menu", OptionList).highlighted = \
                self.current_items.index(match) + 1
            self.push_menu(title, children)
        if self.initial_highlight is not None:
            menu = self.query_one("#menu", OptionList)
            if 0 <= self.initial_highlight < menu.option_count:
                menu.highlighted = self.initial_highlight

    # --- navigation state -------------------------------------------------

    def push_menu(self, title: str, items: list) -> None:
        if self.menu_stack:  # remember the parent row so Back restores it
            try:
                self._highlight_stack.append(
                    self.query_one("#menu", OptionList).highlighted)
            except Exception:
                self._highlight_stack.append(None)
        self.menu_stack.append((title, items))
        self.current_items = items
        self.filter_query = ""
        self._flat_index = None
        self.refresh_menu()

    def pop_menu(self) -> bool:
        if len(self.menu_stack) <= 1:
            return False
        self.menu_stack.pop()
        _, items = self.menu_stack[-1]
        self.current_items = items
        self.filter_query = ""
        self._flat_index = None
        self.refresh_menu()
        saved = self._highlight_stack.pop() if self._highlight_stack else None
        if saved is not None:
            menu = self.query_one("#menu", OptionList)
            if 0 <= saved < menu.option_count:
                menu.highlighted = saved
        return True

    def _flatten(self) -> list:
        """Flatten the current subtree to leaf commands, each with its ancestor path.

        Built once per menu level (lazily, on the first filter keystroke) so a
        command nested in a submenu is findable from here and shown with the path
        it lives under. Submenu expansion can touch the filesystem - guarded.
        """
        out = []

        def walk(items, path):
            for item in items:
                name = item.get("name", "")
                if _is_submenu(item):
                    try:
                        children = _expand_submenu(item)
                    except Exception:
                        children = []
                    walk(children, path + [name])
                else:
                    out.append((tuple(path), item))

        walk(self.current_items, [])
        return out

    def _ensure_flat_index(self) -> list:
        if self._flat_index is None:
            self._flat_index = self._flatten()
        return self._flat_index

    # --- rendering --------------------------------------------------------

    def _item_text(self, item: dict, index: int) -> Text:
        """Build a no-glyph option label, type conveyed by colour and text."""
        name = item.get("name", f"Item {index}")
        desc = item.get("description", "")

        if _is_submenu(item):
            # trailing "/" signals "descends" in text (not colour alone), matching
            # the CLI tree, so submenu vs leaf is distinguishable without hue
            return Text(f"{name}/", style=PASTEL["submenu"])

        if "selector" in item:
            # rendering runs on the UI thread: resolve the current value once per
            # app instance (the run loop recreates the app after every executed
            # item, so an applied change still shows fresh) and NEVER run the
            # options script here - conda env list / aws lookups cost seconds and
            # would freeze every entry into the submenu. Labels resolve from the
            # inline options list only; script-fed selectors emit value==label
            key = id(item)
            if key not in self._selector_row_cache:
                self._selector_row_cache[key] = get_selector_current(item["selector"])
            current = self._selector_row_cache[key]
            inline_opts = item["selector"].get("options") or []
            current_label = next(
                (o.get("label", o["value"]) for o in inline_opts if o.get("value") == current),
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

    def _filtered_text(self, path: tuple, item: dict, query: str) -> Text:
        """Match label: muted ancestor path + leaf name with the typed run boldened."""
        line = Text()
        prefix = ""
        if path:
            prefix = " / ".join(path) + " / "
            line.append(prefix, style=PASTEL["submenu"])
        name = item.get("name", "")
        line.append(name, style=PASTEL["name"])
        start = name.lower().find(query.lower())
        if start >= 0:
            s = len(prefix) + start
            line.stylize(f"bold {DUO['amber']}", s, s + len(query))
        desc = item.get("description", "")
        if desc:
            line.append(f" - {desc}", style=PASTEL["desc"])
        return line

    def _breadcrumb_text(self) -> Text:
        """Path within the menu (root excluded - it is the header title), or, while
        filtering, the live query and match count. No root duplication of the header."""
        # hints are instructional text on the bg_subtle breadcrumb strip -
        # PASTEL["nav"] (text_muted) holds WCAG AA there, text_subtle does not
        bc = Text()
        if self.filter_query:
            matches = len(self.filtered)
            bc.append("filter: ", style=PASTEL["nav"])
            bc.append(self.filter_query, style=PASTEL["tag"])
            bc.append(f"   {matches} match{'' if matches == 1 else 'es'}", style=PASTEL["nav"])
            return bc
        sub = [t for t, _ in self.menu_stack[1:]]
        if sub:
            bc.append(" > ".join(sub), style=PASTEL["nav"])
            # the filter works from any level - keep its one discoverability hint
            # visible where lists get long, not only at the root
            bc.append("   type to filter", style=PASTEL["nav"])
        else:
            bc.append("type to filter", style=PASTEL["nav"])
        return bc

    def refresh_menu(self) -> None:
        menu = self.query_one("#menu", OptionList)
        breadcrumb = self.query_one("#breadcrumb", Static)
        menu.clear_options()

        if self.filter_query:
            self._render_filtered(menu)
        else:
            self._render_navigation(menu)

        breadcrumb.update(self._breadcrumb_text())
        self.refresh_bindings()  # esc label (Back vs Quit) depends on menu depth

    def _render_navigation(self, menu: OptionList) -> None:
        if len(self.menu_stack) > 1:
            menu.add_option(Option(Text("Back", style=PASTEL["nav"]), id="__back__"))
        else:
            menu.add_option(Option(Text("Exit", style=PASTEL["nav"]), id="__exit__"))
        menu.add_option(None)

        for i, item in enumerate(self.current_items):
            menu.add_option(Option(self._item_text(item, i), id=str(i)))

        if self.current_items:
            menu.highlighted = 1

    def _render_filtered(self, menu: OptionList) -> None:
        query = self.filter_query
        self.filtered = [
            (path, item) for (path, item) in self._ensure_flat_index()
            if query.lower() in item.get("name", "").lower()
        ]
        if not self.filtered:
            menu.add_option(Option(Text("no matches - esc to clear", style=PASTEL["nav"]),
                                   id="__none__"))
            return
        for idx, (path, item) in enumerate(self.filtered):
            menu.add_option(Option(self._filtered_text(path, item, query), id=f"f{idx}"))
        menu.highlighted = 0

    # --- input ------------------------------------------------------------

    def on_key(self, event) -> None:
        char = event.character
        if char and len(char) == 1 and char.isprintable():
            if char == " " and not self.filter_query:
                # a leading space would start an invisible filter (breadcrumb
                # shows "filter: " + a blank) - and space means Toggle in the
                # sibling applets, so it must never silently mutate this view
                event.stop()
                event.prevent_default()
                return
            self.filter_query += char
            self.refresh_menu()
            event.stop()
            event.prevent_default()
            return
        if event.key == "backspace":
            if self.filter_query:
                self.filter_query = self.filter_query[:-1]
                self.refresh_menu()
            elif len(self.menu_stack) > 1:
                self.action_go_back()
            # at the root with no filter: no-op - a backspace overshoot after
            # clearing a filter must not close the app (esc "Quit" is the only
            # labeled quit path)
            event.stop()
            event.prevent_default()
            return
        if event.key == "escape" and self.filter_query:
            # esc clears the filter first; only quits when there is no filter
            self.filter_query = ""
            self.refresh_menu()
            event.stop()
            event.prevent_default()

    def on_option_list_option_selected(self, event: OptionList.OptionSelected) -> None:
        option_id = event.option.id

        if option_id == "__exit__":
            self.exit()
            return
        if option_id == "__back__":
            self.pop_menu()
            return
        if option_id == "__none__":
            return

        if option_id and option_id.startswith("f"):
            try:
                _, item = self.filtered[int(option_id[1:])]
            except (ValueError, IndexError):
                return
        else:
            try:
                item = self.current_items[int(option_id)]
            except (ValueError, IndexError):
                return

        self._activate_item(item)

    def _record_exit_position(self) -> None:
        """Capture where the user is, so the next app instance can restore it."""
        self.exit_path = [t for t, _ in self.menu_stack[1:]]
        if self.filter_query:
            # a filtered row's index is meaningless for navigation - restore the
            # browsing level only
            self.exit_highlight = None
            return
        try:
            self.exit_highlight = self.query_one("#menu", OptionList).highlighted
        except Exception:
            self.exit_highlight = None

    def _activate_item(self, item: dict) -> None:
        item_name = item.get("name", "")

        if "selector" in item:
            self._record_exit_position()
            self.pending_command = (item["selector"], item_name, "selector")
            self.exit()
            return

        if _is_submenu(item):
            submenu_items = _expand_submenu(item)
            if submenu_items:
                self.push_menu(item_name, submenu_items)
            else:
                self.notify(f"No items found in {item_name}", severity="warning")
            return

        if "id" in item:
            item_type = item.get("type", "script")
            item_id = item["id"]

            if item.get("_conda_env"):
                self._record_exit_position()
                self.pending_command = (item_id, item_name, "conda_env")
                self.exit()
            elif item_type == "command":
                # interactive: the command runs its own full screen (the applets) -
                # the run loop skips the section header, result banner and pause
                kind = "command_interactive" if item.get("interactive") else "command"
                self._record_exit_position()
                self.pending_command = (item_id, item_name, kind)
                self.exit()
            else:
                script_path = resolve_script_path(item_id, item.get("_full_path", False))
                if script_path is None:
                    self.notify(f"Script not found: {item_id}", severity="error")
                    return
                self._record_exit_position()
                self.pending_command = (str(script_path), item_name, "script")
                self.exit()

    def check_action(self, action: str, parameters) -> bool:
        # gate the stacked escape bindings - only the true one is live and footed
        if action == "clear_filter":
            return bool(self.filter_query)
        if action == "go_back":
            return not self.filter_query and len(self.menu_stack) > 1
        if action == "quit_app":
            return not self.filter_query and len(self.menu_stack) <= 1
        return True

    def action_clear_filter(self) -> None:
        self.filter_query = ""
        self.refresh_menu()

    def action_quit_app(self) -> None:
        self.exit()

    def action_go_back(self) -> None:
        if self.filter_query:
            self.filter_query = ""
            self.refresh_menu()
            return
        if not self.pop_menu():
            self.exit()

    def action_select_item(self) -> None:
        menu = self.query_one("#menu", OptionList)
        if menu.highlighted is not None:
            menu.action_select()


class SelectorApp(App):
    """Single-choice selector for a configured option list."""

    ENABLE_COMMAND_PALETTE = False
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

    def __init__(self, options: list, selector_config: dict, title: str,
                 raw_current: str = ""):
        super().__init__()
        self.title = title
        self.options = options
        self.selector_config = selector_config
        self.raw_current = raw_current
        self.selected = None

    def compose(self) -> ComposeResult:
        current = next((o.get("label", o["value"]) for o in self.options if o.get("current")), None)
        if current is None:
            # a stored value no option matches (e.g. a deleted conda env) must
            # agree with the menu row, which shows the stale raw value - "Not
            # set" here would contradict it
            current = f"{self.raw_current} (missing)" if self.raw_current else "Not set"
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
            # radio semantics: the cursor belongs on the CURRENT choice - starting
            # at row 0 invites an accidental Enter that re-sets the default to
            # whatever sorts first
            menu.highlighted = next(
                (i for i, o in enumerate(self.options) if o.get("current")), 0)

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
        # per-selector remedy beats a dead-end ("no options" says what, not how)
        print(selector_config.get("empty_message")
              or f"No options available for {title}")
        try:
            input("\nPress Enter to continue...")
        except (KeyboardInterrupt, EOFError):
            # EOFError: stdin closed/redirected (echo | lab-utils, CI, ttyd detach)
            print()
        return

    app = SelectorApp(options, selector_config, title,
                      raw_current=get_selector_current(selector_config))
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
        except (KeyboardInterrupt, EOFError):
            # EOFError: stdin closed/redirected (echo | lab-utils, CI, ttyd detach)
            print()


def run_interactive_menu() -> None:
    """Run the menu, then execute the chosen item and loop back to the menu.

    A loop, not tail recursion: a long session would otherwise grow the Python
    stack one frame per executed item and eventually overflow. Config reloads
    each pass so newly installed scripts/envs appear. The menu position carries
    across passes - sequential tasks (pull then push, two installs) must not
    re-navigate from the root every time.
    """
    last_path, last_highlight = [], None
    while True:
        config_data = menu_mod.load_menu_config()
        root_menu = config_data.get("menu", {})

        app = LabUtilsApp(root_menu, initial_path=last_path,
                          initial_highlight=last_highlight)
        app.run()
        flush_input_buffer()

        if not app.pending_command:
            return

        last_path, last_highlight = app.exit_path, app.exit_highlight
        cmd_or_path, title, cmd_type = app.pending_command

        if cmd_type == "selector":
            run_selector(cmd_or_path, title)
            continue

        if cmd_type == "command_interactive":
            # the applets run their own full screen and were just closed by the
            # user - a "Completed successfully" banner + Enter pause would be a
            # false report and a wasted keystroke
            subprocess.run(cmd_or_path, shell=True)
            continue

        cli.print_section_header(title)
        try:
            if cmd_type == "conda_env":
                print(f"Installing conda environment from: {cmd_or_path}")
                # image ENV wins when set - same idiom as conda-env-options and
                # the install scripts, never a bare PATH-resolved conda
                conda_cmd = os.environ.get("CONDA_CMD") or "/opt/conda/bin/conda"
                result = subprocess.run([conda_cmd, "env", "create", "-f", cmd_or_path])
            elif cmd_type == "command":
                result = subprocess.run(cmd_or_path, shell=True)
            else:
                result = subprocess.run([cmd_or_path])
            cli.print_result(result.returncode)
        except KeyboardInterrupt:
            cli.print_cancelled()

        try:
            input("\nPress Enter to continue...")
        except (KeyboardInterrupt, EOFError):
            # EOFError: stdin closed/redirected (echo | lab-utils, CI, ttyd detach)
            print()
