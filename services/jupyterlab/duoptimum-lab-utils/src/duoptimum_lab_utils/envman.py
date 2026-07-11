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
# Built-in fail-safe policy - a PERMANENT floor. The managed artefact
# (lab-utils.lib/env-var-policy.yml) can only EXTEND it (add protections,
# exemptions and selector-managed keys), never remove a built-in one, so a
# missing/unreadable/invalid/partial file can never drop a protection. The
# shipped artefact mirrors this net (drift-guarded by a test); removing a
# built-in protection is a code change here, not a config edit.
#   protected_names / protected_prefixes - refused everywhere (applet,
#     set-profile-var, and dropped from the store at boot before it reaches the
#     server); a value here can override deployment env or re-expose a service.
#   allowed_names - exempt from the prefix guard: per-user knobs the platform
#     reads FROM the store (Default Shell writes JUPYTERLAB_TERMINAL_SHELL, so it
#     must stay writable despite the JUPYTERLAB_ prefix).
#   selector_managed - owned by a Settings selector: the applet HIDES these and
#     refuses to add them, so the selector stays the single editor; value = where
#     to point the user.
_BUILTIN_POLICY = {
    "protected_names": ["PATH", "HOME", "USER", "SHELL", "LD_LIBRARY_PATH",
                        "LD_PRELOAD", "MLFLOW_HOST"],
    "protected_prefixes": ["JUPYTERHUB_", "JUPYTERLAB_"],
    "allowed_names": ["JUPYTERLAB_TERMINAL_SHELL"],
    "selector_managed": {"JUPYTERLAB_TERMINAL_SHELL": "Settings > Default Shell"},
}

POLICY_FILE = "env-var-policy.yml"


def _builtin_policy() -> dict:
    """A fresh copy of the strict fail-safe policy."""
    return {
        "protected_names": set(_BUILTIN_POLICY["protected_names"]),
        "protected_prefixes": tuple(_BUILTIN_POLICY["protected_prefixes"]),
        "allowed_names": set(_BUILTIN_POLICY["allowed_names"]),
        "selector_managed": dict(_BUILTIN_POLICY["selector_managed"]),
    }


def _str_list(value) -> list:
    """value if it is a non-empty list of non-empty strings, else None.

    Element typing keeps a stray int / nested list from either raising in
    set()/tuple() or surviving into is_protected() and crashing str.startswith()
    per key at boot; an empty-string prefix would make startswith() match every
    name, so blanks are rejected too. A rejected value simply contributes
    nothing to the union below - the built-in floor stays intact."""
    if isinstance(value, list) and value and all(
            isinstance(x, str) and x.strip() for x in value):
        return value
    return None


def env_policy() -> dict:
    """Effective env-var policy: the built-in fail-safe floor EXTENDED by the
    managed artefact. The built-in protections, exemptions and selector-managed
    keys are always present - the artefact can only ADD to them, never remove
    one - so a missing, partial, malformed or hand-broken file can never drop a
    protection, un-exempt the shell selector, or un-hide a selector-managed key
    (removing a built-in protection is a code change, not a config edit). Read
    fresh each call (the file is tiny, boot/applet call counts are low, and the
    file is image-baked so it cannot change within a process), so editing the
    artefact takes effect without reimport."""
    policy = _builtin_policy()
    try:
        from . import config  # deferred + inside the guard: an import failure
        import yaml            # here must fall back to the floor, not escape
        data = yaml.safe_load((config.lib_dir() / POLICY_FILE).read_text())
        if not isinstance(data, dict):
            return policy
        names = _str_list(data.get("protected_names"))
        if names:
            policy["protected_names"] |= set(names)
        prefixes = _str_list(data.get("protected_prefixes"))
        if prefixes:
            policy["protected_prefixes"] = tuple(
                dict.fromkeys(policy["protected_prefixes"] + tuple(prefixes)))
        allowed = _str_list(data.get("allowed_names"))
        if allowed:
            policy["allowed_names"] |= set(allowed)
        managed = data.get("selector_managed")
        if isinstance(managed, dict) and all(
                isinstance(k, str) and k for k in managed):
            policy["selector_managed"].update(
                {k: str(v) for k, v in managed.items()})
    except Exception:  # fail-safe: any load/parse failure keeps the strict built-in
        return _builtin_policy()
    return policy


def selector_managed() -> dict:
    """Keys owned by a Settings selector -> where to send the user. The applet
    hides these and refuses to add them; the selector is the single editor."""
    return env_policy()["selector_managed"]

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
    # Precedence resolves every contradiction a crafted artefact could introduce
    # in favour of the BUILT-IN floor, in both directions:
    #  1. a built-in exemption is absolute - the artefact cannot protect the
    #     shell selector's key out of existence (`protected_names:
    #     [JUPYTERLAB_TERMINAL_SHELL]` must not un-exempt it);
    #  2. an explicitly protected name (built-in OR artefact-added) then wins -
    #     allowed_names lifts only the coarse PREFIX guard, so a crafted
    #     `allowed_names: [PATH]` cannot re-expose a protected name;
    #  3. artefact allowed_names then lifts the prefix guard for its own keys
    #     (how a future prefixed selector var gets exempted), else the guard.
    policy = env_policy()
    if name in set(_BUILTIN_POLICY["allowed_names"]):
        return False
    if name in policy["protected_names"]:
        return True
    if name in policy["allowed_names"]:
        return False
    return name.startswith(policy["protected_prefixes"])


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


# the exact marker comment the pre-store selector (default-shell.sh) wrote
# above its export line - scrubbed together with the line on migration
_LEGACY_SHELL_COMMENT = "# set default jupyterlab terminal shell"


def migrate_legacy_shell(profile: Path = None, path: Path = ENV_FILE):
    """MOVE a pre-store Default Shell choice from ~/.profile into the store.

    The original selector (default-shell.sh) wrote
    `export JUPYTERLAB_TERMINAL_SHELL="..."` straight into ~/.profile and the
    platform start sourced ~/.profile, so the choice reached terminado. The
    hardened start reads ONLY this store - a choice stranded in ~/.profile
    never reaches the server and the boot silently falls back to bash.
    Called by start-platform.sh BEFORE the store is applied, so the first boot
    after the upgrade already spawns the selected shell.

    Move, not copy: once the store governs the key, the machine-written legacy
    line (and its marker comment) is removed from ~/.profile - otherwise a
    user deleting the key via the applet would see it silently resurrected
    from ~/.profile on the next boot. A value that is not an absolute path to
    an executable is refused with a stderr notice and LEFT in ~/.profile for
    the user to see. No-op when the store is locked or no legacy line exists.
    Returns the migrated value, or None when nothing was migrated."""
    if store_locked():
        return None
    if profile is None:
        profile = Path.home() / ".profile"
    lines = read_lines(profile)
    value = None
    found = False
    for line in lines:
        m = _VAR_RE.match(line)
        if m and m.group(1) == "JUPYTERLAB_TERMINAL_SHELL":
            found = True
            value = _unquote(m.group(2))  # last assignment wins, like a shell
    if not found:
        return None

    def _scrub_profile():
        keep = [l for l in lines
                if l.strip() != _LEGACY_SHELL_COMMENT
                and not (_VAR_RE.match(l)
                         and _VAR_RE.match(l).group(1) == "JUPYTERLAB_TERMINAL_SHELL")]
        _write_atomic(profile, keep)

    if "JUPYTERLAB_TERMINAL_SHELL" in parse_vars(read_lines(path)):
        # store governs already - drop the stale legacy line so a later
        # delete_var cannot be resurrected from ~/.profile on the next boot
        _scrub_profile()
        return None
    # absolute paths only - the legacy selector's picklist never wrote anything
    # else, and a bare name would resolve against this process's incidental CWD
    # rather than the PATH the old sourced-.profile regime would have used
    if (not value or not os.path.isabs(value)
            or not os.path.isfile(value) or not os.access(value, os.X_OK)):
        print(f"legacy JUPYTERLAB_TERMINAL_SHELL={value!r} in ~/.profile not "
              f"migrated: not an absolute path to an executable",
              file=sys.stderr)
        return None
    set_var("JUPYTERLAB_TERMINAL_SHELL", value, path)
    _scrub_profile()
    return value


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
        managed = selector_managed()
        if name in managed:
            self.query_one("#edit-error", Static).update(
                f"{name} is managed via {managed[name]} - change it there.")
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
        # hide selector-managed keys (e.g. JUPYTERLAB_TERMINAL_SHELL) - they live
        # in the store but are owned by a Settings selector, not this applet, so
        # they must not be listed, edited or deleted here
        managed = selector_managed()
        return {k: v for k, v in parse_vars(read_lines(self.env_path)).items()
                if k not in managed}

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
