"""Environment Variables applet - manage user env vars in ~/.local/environment.env.

The file is the user's single central store with two independent readers:
start-platform.sh sources it directly (set -a) before launching the server, so
every notebook kernel and platform service inherits the variables; ~/.profile
sources the same file for login shells (fish via the bass bridge), which stays
a shell-only concern. New terminals see changes immediately; notebooks and
services only after a server restart - the applet says so on screen.

Round-trip safe: comments, blank lines and unrecognized lines are preserved
verbatim; only variable lines the user edits are rewritten (canonical
single-quoted form). Writes are atomic (tempfile + os.replace in the same
directory).
"""

import os
import re
import sys
import tempfile
from pathlib import Path

from textual.app import App, ComposeResult
from textual.binding import Binding
from textual.containers import Container, Horizontal
from textual.screen import ModalScreen
from textual.widgets import Footer, Input, OptionList, Static
from textual.widgets.option_list import Option

from .theme import DUO, HEADER_CSS, PASTEL, VERSION

ENV_FILE = Path.home() / ".local" / "environment.env"
APPLET_TITLE = "Environment Variables"
RESTART_NOTE = ("New terminals pick changes up automatically - restart the server "
                "to apply them to notebooks and services.")
FILE_HEADER = """# User environment variables - managed by lab-utils > Settings > Environment Variables.
# Sourced directly by the platform start (JupyterLab server, notebook kernels,
# services) and by ~/.profile for login shells.
"""

_VAR_RE = re.compile(r'^\s*(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)=(.*)$')
_NAME_RE = re.compile(r'^[A-Za-z_][A-Za-z0-9_]*$')

# names that can brick the platform start when overridden from the store
# (~/.profile sources it before start-platform.sh resolves conda/jupyter) or
# that belong to the deployment, not the user - refused by the applet.
# ALSO enforced where the SERVER consumes the store: start-platform.sh applies
# it via iter_store_exports (below), filtering these same sets - so a
# hand-edited store cannot override the server/hook env even without the applet.
# (Login shells source the store raw via ~/.profile - shell-only, never the
# server.)
# JUPYTERLAB_* covers the platform's own knobs (SERVER_TOKEN/IP/BASE_URL...) -
# start-platform.sh sources the store BEFORE consuming them, so a store value
# would silently override the compose/hub-provided one (token -> lockout);
# MLFLOW_HOST from the store would re-expose unauthenticated mlflow beyond loopback
PROTECTED_NAMES = {"PATH", "HOME", "USER", "SHELL", "LD_LIBRARY_PATH", "LD_PRELOAD",
                   "MLFLOW_HOST"}
PROTECTED_PREFIXES = ("JUPYTERHUB_", "JUPYTERLAB_")
# per-user knobs the platform deliberately reads FROM the store - exempt from
# the prefix guard (Settings > Default Shell writes JUPYTERLAB_TERMINAL_SHELL)
ALLOWED_NAMES = {"JUPYTERLAB_TERMINAL_SHELL"}

# deployment switch: 0 (whitespace-trimmed) locks the user env store - the
# env-writing Settings entries are hidden (lab-utils.yml enable_env), this
# applet and set-profile-var refuse to write, and start-platform.sh skips the
# store at boot so nothing in it can reach the server, kernels or services.
# ~/.profile stays the user's manual, shell-only channel. One predicate for the
# whole stack: menu.switch_off (bash sees the same via the start-platform.sh
# normalization).
ENABLE_ENV = "JUPYTERLAB_USER_ENV_ENABLE"
LOCKED_MESSAGE = (f"Environment variable management is disabled on this deployment "
                  f"({ENABLE_ENV}=0) - the user env store is not applied at platform "
                  f"start. Edit ~/.profile manually for shell-only variables.")


def store_locked() -> bool:
    from .menu import switch_off  # deferred: keep the applet import light
    return switch_off(ENABLE_ENV)


def is_protected(name: str) -> bool:
    if name in ALLOWED_NAMES:
        return False
    return name in PROTECTED_NAMES or name.startswith(PROTECTED_PREFIXES)


def _quote(value: str) -> str:
    """Canonical shell-safe single-quoted form."""
    return "'" + value.replace("'", "'\\''") + "'"


def _unquote(raw: str) -> str:
    """Best-effort display value for a raw right-hand side."""
    raw = raw.strip()
    if len(raw) >= 2 and raw[0] == raw[-1] and raw[0] in "'\"":
        inner = raw[1:-1]
        if raw[0] == "'":
            inner = inner.replace("'\\''", "'")
        return inner
    return raw


def read_lines(path: Path = ENV_FILE) -> list:
    """File lines without trailing newlines; [] when the file is absent.

    Non-UTF-8 bytes (a Windows-1252 paste, a latin-1 editor) round-trip via
    surrogateescape - treating them as "no file" would make the next set_var
    rewrite the store from an empty list and silently wipe every variable."""
    try:
        return path.read_text(errors="surrogateescape").splitlines()
    except OSError:
        return []


def parse_vars(lines: list) -> dict:
    """KEY -> display value; the LAST assignment of a key wins (shell semantics)."""
    found = {}
    for line in lines:
        m = _VAR_RE.match(line)
        if m:
            found[m.group(1)] = _unquote(m.group(2))
    return found


def iter_store_exports(path: Path = ENV_FILE) -> list:
    """(KEY, VALUE) for every NON-protected assignment in the store, last-wins.

    The platform start consumes this instead of sourcing the store as shell:
    `. file` runs arbitrary shell grammar, so a compound line
    (`X=1; export JUPYTERLAB_SUDO_ENABLE=1`) would smuggle a protected
    assignment past any per-line text filter. Parsing to (key, value) pairs and
    filtering on the PARSED key closes that - a value is only ever assigned as
    literal data, never evaluated.

    A pair containing a NUL byte is dropped: the caller streams these
    NUL-delimited, and str.splitlines() (read_lines) does not split on NUL, so
    an embedded-NUL value (`A=x\\0JUPYTERLAB_SUDO_ENABLE=1`) would parse as one
    unprotected key here yet re-split into a protected assignment at the
    consumer's frame boundary. NUL can never appear in a real env value
    (execve forbids it), so rejecting it costs nothing and closes the last
    in-band-delimiter smuggle."""
    return [(k, v) for k, v in parse_vars(read_lines(path)).items()
            if not is_protected(k) and "\x00" not in k and "\x00" not in v]


def _write_atomic(path: Path, lines: list) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp = tempfile.mkstemp(dir=path.parent, prefix=".environment.env.")
    try:
        # surrogateescape mirrors read_lines: foreign bytes in preserved lines
        # are written back verbatim instead of raising mid-write
        with os.fdopen(fd, "w", errors="surrogateescape") as fh:
            fh.write("\n".join(lines) + "\n" if lines else "")
        os.replace(tmp, path)
    except BaseException:
        try:
            os.unlink(tmp)
        except OSError:
            pass
        raise


def set_var(key: str, value: str, path: Path = ENV_FILE) -> None:
    """Set/replace a variable, preserving every other line. New keys append."""
    lines = read_lines(path)
    if not lines and not path.exists():
        lines = FILE_HEADER.splitlines()
    new_line = f"{key}={_quote(value)}"
    replaced = False
    out = []
    for line in lines:
        m = _VAR_RE.match(line)
        if m and m.group(1) == key:
            if not replaced:  # rewrite the first assignment, drop duplicates
                out.append(new_line)
                replaced = True
            continue
        out.append(line)
    if not replaced:
        out.append(new_line)
    _write_atomic(path, out)


def delete_var(key: str, path: Path = ENV_FILE) -> None:
    """Remove every assignment of the key, preserving all other lines."""
    lines = read_lines(path)
    out = [line for line in lines
           if not (_VAR_RE.match(line) and _VAR_RE.match(line).group(1) == key)]
    _write_atomic(path, out)


class EditVarScreen(ModalScreen):
    """Add or edit one variable. Enter saves, Esc cancels."""

    CSS = f"""
    EditVarScreen {{ align: center middle; background: {DUO['bg_dim']} 60%; }}
    #edit-box {{
        width: 70; max-width: 100%; height: auto; padding: 1 2;
        background: {DUO['bg']}; border: round {DUO['cyan']};
    }}
    #edit-title {{ color: {PASTEL['title']}; text-style: bold; }}
    #edit-hint {{ color: {DUO['text_muted']}; }}  /* instructional text - AA on the modal bg */
    #edit-error {{ color: {PASTEL['err']}; height: auto; }}
    Input {{ background: {DUO['surface']}; border: tall {DUO['border']}; }}
    Input:focus {{ border: tall {DUO['cyan']}; }}
    """

    # Enter is handled via Input.Submitted (a priority binding would consume the
    # key before the focused Input without reliably resolving the screen action)
    BINDINGS = [
        Binding("escape", "cancel", "Cancel", show=True),
    ]

    def __init__(self, name: str = "", value: str = ""):
        super().__init__()
        self.var_name = name
        self.var_value = value
        self.editing = bool(name)

    def compose(self) -> ComposeResult:
        with Container(id="edit-box"):
            yield Static("Edit variable" if self.editing else "Add variable", id="edit-title")
            yield Static("Name:")
            name_input = Input(value=self.var_name, id="name-input", select_on_focus=False)
            name_input.disabled = self.editing  # renaming = delete + add, keeps semantics obvious
            yield name_input
            yield Static("Value:")
            yield Input(value=self.var_value, id="value-input", select_on_focus=False)
            # modals render no Footer, so the commit key must be stated inline -
            # first-time users should not have to guess that Enter saves
            yield Static("Enter saves - Esc cancels", id="edit-hint")
            yield Static("", id="edit-error")

    def on_mount(self) -> None:
        target = "#value-input" if self.editing else "#name-input"
        field = self.query_one(target, Input)
        field.focus()
        field.cursor_position = len(field.value)

    def action_cancel(self) -> None:
        self.dismiss(None)

    def on_input_submitted(self, event: Input.Submitted) -> None:
        # Enter inside either Input submits - the focused Input consumes the key
        # before screen bindings, so the binding alone is not enough
        self.action_save()

    def action_save(self) -> None:
        name = self.query_one("#name-input", Input).value.strip()
        value = self.query_one("#value-input", Input).value
        if not _NAME_RE.match(name):
            self.query_one("#edit-error", Static).update(
                "Invalid name - letters, digits and _ only; cannot start with a digit.")
            return
        if is_protected(name):
            self.query_one("#edit-error", Static).update(
                f"{name} is protected - overriding it can break the platform start.")
            return
        self.dismiss((name, value))


class ConfirmScreen(ModalScreen):
    """y confirms, n / Esc cancels."""

    CSS = f"""
    ConfirmScreen {{ align: center middle; background: {DUO['bg_dim']} 60%; }}
    #confirm-box {{
        width: auto; height: auto; padding: 1 2;
        background: {DUO['bg']}; border: round {DUO['rose']};
        color: {DUO['text']};
    }}
    """

    BINDINGS = [
        Binding("y", "yes", "Yes", show=True),
        Binding("n", "no", "No", show=True),
        Binding("escape", "no", "No", show=False),
    ]

    def __init__(self, message: str):
        super().__init__()
        self.message = message

    def compose(self) -> ComposeResult:
        yield Static(f"{self.message}  [y/n]", id="confirm-box")

    def action_yes(self) -> None:
        self.dismiss(True)

    def action_no(self) -> None:
        self.dismiss(False)


class EnvManagerApp(App):
    """List, add, edit and delete user environment variables."""

    TITLE = APPLET_TITLE
    ENABLE_COMMAND_PALETTE = False
    CSS = f"""
    Screen {{ background: {DUO['bg_dim']}; }}
{HEADER_CSS}
    #restart-note {{
        height: auto; padding: 0 2;
        background: {DUO['bg_subtle']}; color: {PASTEL['info']};
    }}
    #env-container {{ width: 100%; height: 1fr; padding: 1 2; }}
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

    # Enter-to-edit arrives as OptionList.OptionSelected (see handler below) - an
    # app-level priority binding would also swallow Enter inside the edit modal
    BINDINGS = [
        Binding("a", "add_var", "Add", show=True),
        Binding("e", "edit_var", "Edit", show=True),
        Binding("d", "delete_var", "Delete", show=True),
        Binding("escape", "quit", "Quit", show=True),
        Binding("q", "quit", "Quit", show=False),
        Binding("ctrl+c", "quit", "Quit", show=False),
    ]

    def __init__(self, env_path: Path = ENV_FILE):
        super().__init__()
        self.env_path = env_path

    def compose(self) -> ComposeResult:
        with Horizontal(id="app-header"):
            yield Static(APPLET_TITLE, id="hdr-title")
            yield Static(f"v{VERSION}", id="hdr-version")
        yield Static(RESTART_NOTE, id="restart-note")
        with Container(id="env-container"):
            yield OptionList(id="env-list")
        yield Footer()

    def on_mount(self) -> None:
        self.refresh_list()
        self.query_one("#env-list", OptionList).focus()

    # --- state -------------------------------------------------------------

    def current_vars(self) -> dict:
        return parse_vars(read_lines(self.env_path))

    def refresh_list(self, select_key: str = None) -> None:
        option_list = self.query_one("#env-list", OptionList)
        option_list.clear_options()
        env_vars = self.current_vars()
        if not env_vars:
            option_list.add_option(
                Option("(no variables defined - press 'a' to add one)", disabled=True))
            return
        keys = sorted(env_vars)
        for key in keys:
            option_list.add_option(Option(f"{key} = {env_vars[key]}", id=key))
        highlight = select_key if select_key in keys else keys[0]
        option_list.highlighted = keys.index(highlight)

    def selected_key(self):
        option_list = self.query_one("#env-list", OptionList)
        if option_list.highlighted is None:
            return None
        option = option_list.get_option_at_index(option_list.highlighted)
        return option.id  # None for the empty-state placeholder

    # --- actions -----------------------------------------------------------

    def on_option_list_option_selected(self, event: OptionList.OptionSelected) -> None:
        # Enter on a row edits it
        self.action_edit_var()

    def action_add_var(self) -> None:
        def done(result):
            if result:
                name, value = result
                set_var(name, value, self.env_path)
                self.refresh_list(select_key=name)
        self.push_screen(EditVarScreen(), done)

    def action_edit_var(self) -> None:
        key = self.selected_key()
        if key is None:
            return
        def done(result):
            if result:
                name, value = result
                set_var(name, value, self.env_path)
                self.refresh_list(select_key=name)
        self.push_screen(EditVarScreen(key, self.current_vars().get(key, "")), done)

    def action_delete_var(self) -> None:
        key = self.selected_key()
        if key is None:
            return
        # keep the cursor on the deleted row's neighbour instead of teleporting
        # to the top of the list
        keys = sorted(self.current_vars())
        idx = keys.index(key)
        neighbor = keys[idx + 1] if idx + 1 < len(keys) else (keys[idx - 1] if idx else None)
        def done(confirmed):
            if confirmed:
                delete_var(key, self.env_path)
                self.refresh_list(select_key=neighbor)
        self.push_screen(ConfirmScreen(f"Delete {key}?"), done)


def main() -> None:
    if store_locked():
        print(LOCKED_MESSAGE, file=sys.stderr)
        sys.exit(1)
    EnvManagerApp().run()


if __name__ == "__main__":
    main()
