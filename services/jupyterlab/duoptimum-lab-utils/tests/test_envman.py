"""Env-store round-trip, quoting, atomicity, and a headless applet render check."""

import asyncio
from pathlib import Path

import pytest

pytest.importorskip("textual")

from duoptimum_lab_utils import envman  # noqa: E402


@pytest.fixture
def env_file(tmp_path):
    return tmp_path / "environment.env"


# --- parsing -----------------------------------------------------------------

def test_parse_recognises_plain_quoted_and_export_forms(env_file):
    env_file.write_text(
        "PLAIN=abc\n"
        "SINGLE='a b c'\n"
        'DOUBLE="d e f"\n'
        "export EXPORTED=xyz\n"
    )
    found = envman.parse_vars(envman.read_lines(env_file))
    assert found == {"PLAIN": "abc", "SINGLE": "a b c",
                     "DOUBLE": "d e f", "EXPORTED": "xyz"}


def test_parse_last_assignment_wins_like_shell(env_file):
    env_file.write_text("K=first\nK=second\n")
    assert envman.parse_vars(envman.read_lines(env_file)) == {"K": "second"}


def test_parse_ignores_comments_blanks_and_junk(env_file):
    env_file.write_text("# comment\n\nnot a var line\n1BAD=x\nGOOD=1\n")
    assert envman.parse_vars(envman.read_lines(env_file)) == {"GOOD": "1"}


def test_missing_file_reads_as_empty(env_file):
    assert envman.read_lines(env_file) == []
    assert envman.parse_vars([]) == {}


# --- writing -----------------------------------------------------------------

def test_set_var_creates_file_with_header(env_file):
    envman.set_var("MY_VAR", "hello world", env_file)
    text = env_file.read_text()
    assert "MY_VAR='hello world'" in text
    assert text.startswith("#")  # header comment written for a fresh file
    assert envman.parse_vars(envman.read_lines(env_file))["MY_VAR"] == "hello world"


def test_set_var_replaces_in_place_and_preserves_other_lines(env_file):
    env_file.write_text("# my comment\nA=1\nB=2\n")
    envman.set_var("A", "changed", env_file)
    lines = envman.read_lines(env_file)
    assert lines[0] == "# my comment"        # comment untouched
    assert lines[1] == "A='changed'"          # replaced at its original position
    assert lines[2] == "B=2"                  # untouched, original form kept


def test_set_var_collapses_duplicate_assignments(env_file):
    env_file.write_text("K=one\nK=two\n")
    envman.set_var("K", "final", env_file)
    lines = [l for l in envman.read_lines(env_file) if l.startswith("K")]
    assert lines == ["K='final'"]


def test_quoting_round_trips_spaces_quotes_and_dollars(env_file):
    tricky = """spa ced 'sin"gle' $HOME `cmd` !bang"""
    envman.set_var("TRICKY", tricky, env_file)
    assert envman.parse_vars(envman.read_lines(env_file))["TRICKY"] == tricky


def test_written_file_sources_cleanly_in_sh(env_file, tmp_path):
    import subprocess
    value = "with spaces and 'quotes' and $dollar"
    envman.set_var("SRC_TEST", value, env_file)
    out = subprocess.run(
        ["sh", "-c", f". '{env_file}' && printf %s \"$SRC_TEST\""],
        capture_output=True, text=True)
    assert out.returncode == 0
    assert out.stdout == value


def test_delete_var_removes_all_assignments_only(env_file):
    env_file.write_text("# keep\nGONE=1\nKEEP=2\nGONE=3\n")
    envman.delete_var("GONE", env_file)
    assert envman.read_lines(env_file) == ["# keep", "KEEP=2"]


def test_no_stray_tempfiles_after_operations(env_file):
    envman.set_var("A", "1", env_file)
    envman.delete_var("A", env_file)
    leftovers = [p for p in env_file.parent.iterdir()
                 if p.name.startswith(".environment.env.")]
    assert leftovers == []


def test_non_utf8_store_survives_writes(env_file):
    # a single foreign byte (Windows-1252 paste) must never make read_lines
    # report "no file" - set_var would then rewrite the store from an empty
    # list and silently wipe every variable
    env_file.write_bytes(b"# caf\xe9 config\nA='1'\nB='2'\n")
    envman.set_var("NEW", "x", env_file)
    raw = env_file.read_bytes()
    assert b"caf\xe9 config" in raw          # foreign byte round-tripped
    assert b"A='1'" in raw and b"B='2'" in raw
    assert envman.parse_vars(envman.read_lines(env_file))["NEW"] == "x"


# --- applet ------------------------------------------------------------------

def test_name_validation_regex():
    assert envman._NAME_RE.match("GOOD_NAME1")
    assert not envman._NAME_RE.match("1BAD")
    assert not envman._NAME_RE.match("BAD-NAME")
    assert not envman._NAME_RE.match("")
    assert not envman._NAME_RE.match("SPA CED")


def test_protected_names_refused():
    for name in ["PATH", "HOME", "LD_LIBRARY_PATH", "JUPYTERHUB_USER", "JUPYTERHUB_API_TOKEN",
                 "JUPYTERLAB_SERVER_TOKEN", "JUPYTERLAB_SERVER_IP", "JUPYTERLAB_BASE_URL",
                 "MLFLOW_HOST"]:
        assert envman.is_protected(name)
    # JUPYTERLAB_TERMINAL_SHELL is the Settings > Default Shell knob - the
    # prefix guard must not block the platform's own selector
    for name in ["MY_VAR", "AWS_PROFILE", "CONDA_DEFAULT_ENV", "PATHLIKE", "MLFLOW_PORT",
                 "JUPYTERLAB_TERMINAL_SHELL"]:
        assert not envman.is_protected(name)


def test_applet_refuses_protected_variable(env_file):
    async def _go():
        app = envman.EnvManagerApp(env_path=env_file)
        async with app.run_test(size=(90, 24)) as pilot:
            await pilot.press("a")
            await pilot.press(*"PATH")
            await pilot.press("tab")
            await pilot.press(*"/evil")
            await pilot.press("enter")
            await pilot.pause()
            # modal stays open with the protection error; nothing written
            from textual.widgets import Static
            err = str(app.screen.query_one("#edit-error", Static).render())
            assert "protected" in err

    asyncio.run(_go())
    assert not env_file.exists()


def _option_texts(app):
    from textual.widgets import OptionList
    option_list = app.query_one("#env-list", OptionList)
    return [str(option_list.get_option_at_index(i).prompt)
            for i in range(option_list.option_count)]


def test_applet_lists_vars_and_restart_note(env_file):
    env_file.write_text("ZED=26\nALPHA='a value'\n")

    async def _go():
        app = envman.EnvManagerApp(env_path=env_file)
        async with app.run_test(size=(90, 24)):
            from textual.widgets import Static
            texts = _option_texts(app)
            assert texts == ["ALPHA = a value", "ZED = 26"]  # sorted, unquoted display
            note = str(app.query_one("#restart-note", Static).render())
            assert "restart the server" in note

    asyncio.run(_go())


def test_applet_empty_state(env_file):
    async def _go():
        app = envman.EnvManagerApp(env_path=env_file)
        async with app.run_test(size=(90, 24)):
            assert "press 'a' to add one" in _option_texts(app)[0]

    asyncio.run(_go())


def test_applet_add_flow_writes_file(env_file):
    async def _go():
        app = envman.EnvManagerApp(env_path=env_file)
        async with app.run_test(size=(90, 24)) as pilot:
            await pilot.press("a")
            await pilot.press(*"NEW", "underscore", *"VAR")  # '_' has no bare key name
            await pilot.press("tab")            # name -> value input
            await pilot.press(*"val", "space", "1")
            await pilot.press("enter")
            await pilot.pause()
            assert "NEW_VAR = val 1" in _option_texts(app)

    asyncio.run(_go())
    assert envman.parse_vars(envman.read_lines(env_file))["NEW_VAR"] == "val 1"


def test_applet_delete_flow_requires_confirmation(env_file):
    env_file.write_text("DOOMED=1\n")

    async def _go():
        app = envman.EnvManagerApp(env_path=env_file)
        async with app.run_test(size=(90, 24)) as pilot:
            await pilot.press("d")
            await pilot.press("n")              # declined - still there
            await pilot.pause()
            assert envman.parse_vars(envman.read_lines(env_file)) == {"DOOMED": "1"}
            await pilot.press("d")
            await pilot.press("y")
            await pilot.pause()
            assert envman.parse_vars(envman.read_lines(env_file)) == {}

    asyncio.run(_go())


# --- deployment lock (JUPYTERLAB_USER_ENV_ENABLE) ------------------------------

def test_store_locked_only_on_literal_zero(monkeypatch):
    monkeypatch.delenv(envman.ENABLE_ENV, raising=False)
    assert envman.store_locked() is False
    for value in ("1", "", "yes", "00"):
        monkeypatch.setenv(envman.ENABLE_ENV, value)
        assert envman.store_locked() is False
    for value in ("0", " 0 "):
        monkeypatch.setenv(envman.ENABLE_ENV, value)
        assert envman.store_locked() is True


def test_main_refuses_when_locked(monkeypatch, capsys):
    monkeypatch.setenv(envman.ENABLE_ENV, "0")
    with pytest.raises(SystemExit) as exc:
        envman.main()
    assert exc.value.code == 1
    assert envman.ENABLE_ENV in capsys.readouterr().err


# --- consumption-point protection filter (iter_store_exports) -----------------

def test_iter_store_exports_drops_protected_keeps_user(env_file):
    env_file.write_text(
        "NORMAL='keep me'\n"
        "export ANOTHER=ok\n"
        "JUPYTERLAB_SUDO_ENABLE='1'\n"
        "export JUPYTERLAB_SERVER_TOKEN='steal'\n"
        "LD_PRELOAD='/tmp/evil.so'\n"
        "MLFLOW_HOST='0.0.0.0'\n"
        "JUPYTERHUB_API_TOKEN='x'\n"
        "PATH='/tmp/bad'\n"
        "JUPYTERLAB_TERMINAL_SHELL='/usr/bin/fish'\n")  # exempt
    got = dict(envman.iter_store_exports(env_file))
    assert got == {"NORMAL": "keep me", "ANOTHER": "ok",
                   "JUPYTERLAB_TERMINAL_SHELL": "/usr/bin/fish"}


def test_iter_store_exports_compound_line_cannot_smuggle(env_file):
    # a compound shell line is not a valid KEY=VALUE assignment - the parser
    # matches only the leading token, so the whole line is treated as one key
    # ("X" with a value) and no protected var is ever produced
    env_file.write_text(
        "X=1; export JUPYTERLAB_SUDO_ENABLE=1\n"
        "export DECOY=1 MLFLOW_HOST=0.0.0.0\n")
    keys = {k for k, _ in envman.iter_store_exports(env_file)}
    assert "JUPYTERLAB_SUDO_ENABLE" not in keys
    assert "MLFLOW_HOST" not in keys


def test_iter_store_exports_rejects_nul_in_value(env_file):
    # NUL is the caller's frame delimiter; splitlines() does not cut on NUL, so
    # an embedded-NUL value would parse as one unprotected key here and then
    # re-split into a protected assignment at the consumer. Drop such pairs.
    env_file.write_bytes(b"A=x\x00JUPYTERLAB_SUDO_ENABLE=1\nB=fine\n")
    got = dict(envman.iter_store_exports(env_file))
    assert "A" not in got            # the NUL-bearing pair is dropped whole
    assert got == {"B": "fine"}      # clean neighbour still flows


def test_iter_store_exports_preserves_non_utf8_value(env_file):
    # the store round-trips foreign bytes via surrogateescape (read/write);
    # the emitter must too, so a Windows-1252 value survives to the consumer
    # regardless of container locale rather than crashing the export loop
    env_file.write_bytes(b"FOREIGN=caf\xe9\nCLEAN=ok\n")
    got = dict(envman.iter_store_exports(env_file))
    assert got["CLEAN"] == "ok"
    # the hardened emitter re-encodes with surrogateescape - byte-exact recovery
    assert got["FOREIGN"].encode("utf-8", "surrogateescape") == b"caf\xe9"


# --- legacy default-shell migration (migrate_legacy_shell) ---------------------

@pytest.fixture
def fake_shell(tmp_path):
    """An executable file standing in for /usr/bin/fish."""
    shell = tmp_path / "fish"
    shell.write_text("#!/bin/sh\n")
    shell.chmod(0o755)
    return shell


@pytest.fixture
def profile(tmp_path):
    return tmp_path / ".profile"


def test_migrate_seeds_store_from_legacy_profile_line(profile, env_file, fake_shell):
    # the exact format the pre-store selector (default-shell.sh) wrote
    profile.write_text(
        "# set default jupyterlab terminal shell\n"
        f'export JUPYTERLAB_TERMINAL_SHELL="{fake_shell}"\n')
    got = envman.migrate_legacy_shell(profile=profile, path=env_file)
    assert got == str(fake_shell)
    assert envman.parse_vars(envman.read_lines(env_file)) == {
        "JUPYTERLAB_TERMINAL_SHELL": str(fake_shell)}
    # the seeded value must actually reach the server: exempt from the
    # JUPYTERLAB_ prefix guard at the consumption point
    assert dict(envman.iter_store_exports(env_file)) == {
        "JUPYTERLAB_TERMINAL_SHELL": str(fake_shell)}


def test_migrate_accepts_unquoted_and_bare_forms_last_wins(profile, env_file, fake_shell):
    # shell semantics: the boot used to SOURCE .profile, so the last line won
    profile.write_text(
        "JUPYTERLAB_TERMINAL_SHELL=/nonexistent/zsh\n"
        f"export JUPYTERLAB_TERMINAL_SHELL={fake_shell}\n")
    assert envman.migrate_legacy_shell(profile=profile, path=env_file) == str(fake_shell)


def test_migrate_noop_when_store_already_has_key(profile, env_file, fake_shell):
    # the store is the source of truth once the key exists - a later .profile
    # edit must never override a selector-made choice
    envman.set_var("JUPYTERLAB_TERMINAL_SHELL", "/bin/bash", env_file)
    profile.write_text(f'export JUPYTERLAB_TERMINAL_SHELL="{fake_shell}"\n')
    assert envman.migrate_legacy_shell(profile=profile, path=env_file) is None
    assert envman.parse_vars(envman.read_lines(env_file)) == {
        "JUPYTERLAB_TERMINAL_SHELL": "/bin/bash"}


def test_migrate_noop_when_store_locked(profile, env_file, fake_shell, monkeypatch):
    monkeypatch.setenv(envman.ENABLE_ENV, "0")
    profile.write_text(f'export JUPYTERLAB_TERMINAL_SHELL="{fake_shell}"\n')
    assert envman.migrate_legacy_shell(profile=profile, path=env_file) is None
    assert not env_file.exists()


def test_migrate_noop_without_legacy_line(profile, env_file):
    profile.write_text("# plain profile, nothing to migrate\nexport EDITOR=vim\n")
    assert envman.migrate_legacy_shell(profile=profile, path=env_file) is None
    assert not env_file.exists()


def test_migrate_noop_when_profile_absent(profile, env_file):
    assert envman.migrate_legacy_shell(profile=profile, path=env_file) is None
    assert not env_file.exists()


def test_migrate_rejects_non_executable_and_bogus_paths(profile, env_file, tmp_path):
    plain = tmp_path / "not-a-shell"
    plain.write_text("data\n")  # exists but not executable
    for bogus in [str(plain), "/nonexistent/fish", str(tmp_path)]:
        profile.write_text(f'export JUPYTERLAB_TERMINAL_SHELL="{bogus}"\n')
        assert envman.migrate_legacy_shell(profile=profile, path=env_file) is None
    assert not env_file.exists()


def test_migrate_preserves_other_store_lines(profile, env_file, fake_shell):
    envman.set_var("MY_VAR", "keep", env_file)
    profile.write_text(f'export JUPYTERLAB_TERMINAL_SHELL="{fake_shell}"\n')
    envman.migrate_legacy_shell(profile=profile, path=env_file)
    got = envman.parse_vars(envman.read_lines(env_file))
    assert got == {"MY_VAR": "keep",
                   "JUPYTERLAB_TERMINAL_SHELL": str(fake_shell)}


def test_migrate_never_executes_the_candidate(profile, env_file, tmp_path):
    # the security boundary: the value is DATA - validation must never run it.
    # A canary executable records any invocation; migration must leave no trace.
    canary = tmp_path / "canary-shell"
    sentinel = tmp_path / "executed"
    canary.write_text(f"#!/bin/sh\ntouch {sentinel}\n")
    canary.chmod(0o755)
    profile.write_text(f'export JUPYTERLAB_TERMINAL_SHELL="{canary}"\n')
    assert envman.migrate_legacy_shell(profile=profile, path=env_file) == str(canary)
    assert not sentinel.exists()


def test_migrate_rejects_relative_and_bare_names(profile, env_file, tmp_path, monkeypatch):
    # a bare `fish` would resolve against the process's incidental CWD, not the
    # PATH the old sourced-.profile regime used - absolute paths only
    trap = tmp_path / "fish"
    trap.write_text("#!/bin/sh\n")
    trap.chmod(0o755)
    monkeypatch.chdir(tmp_path)  # make the relative name resolvable on purpose
    for sneaky in ["fish", "./fish", "bin/../fish"]:
        profile.write_text(f"export JUPYTERLAB_TERMINAL_SHELL={sneaky}\n")
        assert envman.migrate_legacy_shell(profile=profile, path=env_file) is None
    assert not env_file.exists()


def test_migrate_is_move_not_copy_no_resurrection_after_delete(profile, env_file, fake_shell):
    # round-2 adversarial find: a COPY would resurrect a deleted key from
    # ~/.profile on every boot - deleting a shell preference must stick
    profile.write_text(
        "# set default jupyterlab terminal shell\n"
        f'export JUPYTERLAB_TERMINAL_SHELL="{fake_shell}"\n')
    assert envman.migrate_legacy_shell(profile=profile, path=env_file) == str(fake_shell)
    # the legacy line AND its marker comment are gone from ~/.profile
    assert "JUPYTERLAB_TERMINAL_SHELL" not in profile.read_text()
    assert "set default jupyterlab terminal shell" not in profile.read_text()
    # user resets their choice - it must stay deleted across the next boot
    envman.delete_var("JUPYTERLAB_TERMINAL_SHELL", env_file)
    assert envman.migrate_legacy_shell(profile=profile, path=env_file) is None
    assert "JUPYTERLAB_TERMINAL_SHELL" not in envman.parse_vars(envman.read_lines(env_file))


def test_migrate_scrubs_stale_line_when_store_already_governs(profile, env_file, fake_shell):
    # store has the key (user re-selected): the stale ~/.profile line is
    # dropped so a later delete cannot be resurrected either
    envman.set_var("JUPYTERLAB_TERMINAL_SHELL", "/bin/bash", env_file)
    profile.write_text(f'export JUPYTERLAB_TERMINAL_SHELL="{fake_shell}"\n')
    assert envman.migrate_legacy_shell(profile=profile, path=env_file) is None
    assert "JUPYTERLAB_TERMINAL_SHELL" not in profile.read_text()
    envman.delete_var("JUPYTERLAB_TERMINAL_SHELL", env_file)
    assert envman.migrate_legacy_shell(profile=profile, path=env_file) is None


def test_migrate_keeps_rejected_line_and_reports(profile, env_file, capsys):
    # a refused value stays visible in ~/.profile and lands a stderr notice
    # (the boot logs it) - rejection must be distinguishable from not-found
    profile.write_text('export JUPYTERLAB_TERMINAL_SHELL="/nonexistent/fish"\n')
    assert envman.migrate_legacy_shell(profile=profile, path=env_file) is None
    assert "JUPYTERLAB_TERMINAL_SHELL" in profile.read_text()
    assert "not migrated" in capsys.readouterr().err


def test_migrate_scrub_preserves_other_profile_content(profile, env_file, fake_shell):
    before = ("# my precious profile\n"
              "export EDITOR=vim\n"
              "# set default jupyterlab terminal shell\n"
              f'export JUPYTERLAB_TERMINAL_SHELL="{fake_shell}"\n'
              "alias ll='ls -la'\n")
    profile.write_text(before)
    envman.migrate_legacy_shell(profile=profile, path=env_file)
    after = profile.read_text()
    assert "# my precious profile" in after
    assert "export EDITOR=vim" in after
    assert "alias ll='ls -la'" in after
    assert "JUPYTERLAB_TERMINAL_SHELL" not in after


# --- managed env-var policy artefact (env_policy / selector_managed) ----------

@pytest.fixture
def policy_home(tmp_path, monkeypatch):
    """A data root whose lab-utils.lib holds a writable env-var-policy.yml."""
    lib = tmp_path / "lab-utils.lib"
    lib.mkdir(parents=True)
    monkeypatch.setenv("DUOPTIMUM_LAB_UTILS_HOME", str(tmp_path))
    return lib / "env-var-policy.yml"


def test_policy_falls_back_to_builtin_without_artefact(tmp_path, monkeypatch):
    # data root with no policy file -> strict built-in, protections intact
    monkeypatch.setenv("DUOPTIMUM_LAB_UTILS_HOME", str(tmp_path))
    assert envman.is_protected("PATH")
    assert envman.is_protected("MLFLOW_HOST")
    assert envman.is_protected("JUPYTERHUB_API_TOKEN")
    assert not envman.is_protected("JUPYTERLAB_TERMINAL_SHELL")  # allowed exemption
    assert "JUPYTERLAB_TERMINAL_SHELL" in envman.selector_managed()


def test_policy_artefact_extends_builtin_floor(policy_home):
    # the artefact ADDS to the built-in floor, never replaces it: a partial file
    # cannot drop a built-in protection or un-hide the shell key
    policy_home.write_text(
        "protected_names: [SECRET]\n"
        "protected_prefixes: [ACME_]\n"
        "allowed_names: [MY_KNOB]\n"
        "selector_managed:\n"
        "  CONDA_DEFAULT_ENV: 'Settings > Default Conda Env'\n")
    assert envman.is_protected("SECRET")          # added by the file
    assert envman.is_protected("ACME_X")          # prefix added by the file
    assert envman.is_protected("MLFLOW_HOST")     # built-in floor kept, not dropped
    assert envman.is_protected("JUPYTERHUB_X")    # built-in prefix kept
    assert envman.is_protected("JUPYTERLAB_X")
    assert not envman.is_protected("MY_KNOB")     # exemption added by the file
    assert not envman.is_protected("JUPYTERLAB_TERMINAL_SHELL")  # built-in exemption kept
    assert set(envman.selector_managed()) == {
        "JUPYTERLAB_TERMINAL_SHELL", "CONDA_DEFAULT_ENV"}  # shell floor + added key


def test_policy_partial_file_cannot_drop_builtin_protection(policy_home):
    # the round-2 fail-open: a well-typed, non-empty but PARTIAL list must not
    # replace the floor and re-expose MLFLOW_HOST / JUPYTERHUB_* / the shell key
    policy_home.write_text(
        "protected_names: [ONLY_THIS]\n"
        "protected_prefixes: [ONLY_PREFIX_]\n"
        "allowed_names: [ONLY_KNOB]\n"
        "selector_managed: {ONLY_SELECTOR: 'Settings > X'}\n")
    assert envman.is_protected("MLFLOW_HOST")     # not dropped
    assert envman.is_protected("PATH")
    assert envman.is_protected("LD_PRELOAD")
    assert envman.is_protected("JUPYTERHUB_API_TOKEN")   # prefix floor kept
    assert not envman.is_protected("JUPYTERLAB_TERMINAL_SHELL")  # exemption kept
    assert "JUPYTERLAB_TERMINAL_SHELL" in envman.selector_managed()  # still hidden


def test_policy_allowed_names_cannot_exempt_a_protected_name(policy_home):
    # explicit protection is an absolute floor: listing a protected_name under
    # allowed_names must NOT re-expose it (allowed_names lifts the prefix guard
    # only). A crafted file adding PATH/MLFLOW_HOST as exemptions stays refused.
    policy_home.write_text("allowed_names: [PATH, MLFLOW_HOST, LD_PRELOAD]\n")
    assert envman.is_protected("PATH")
    assert envman.is_protected("MLFLOW_HOST")
    assert envman.is_protected("LD_PRELOAD")
    # but a prefix-only match can still be exempted (the shell selector's channel)
    assert not envman.is_protected("JUPYTERLAB_TERMINAL_SHELL")


def test_policy_cannot_protect_the_shell_exemption_out_of_existence(policy_home):
    # a crafted file adding the shell key to protected_names must NOT un-exempt
    # it - the built-in exemption is absolute, so the Default Shell selector's
    # set-profile-var write stays allowed (invariant: never un-exempt the shell)
    policy_home.write_text(
        "protected_names: [JUPYTERLAB_TERMINAL_SHELL]\n"
        "protected_prefixes: [JUPYTERLAB_TERMINAL_]\n")
    assert not envman.is_protected("JUPYTERLAB_TERMINAL_SHELL")
    # and a fresh prefix-only selector var can still be exempted via the artefact
    policy_home.write_text(
        "allowed_names: [JUPYTERLAB_FUTURE_KNOB]\n")
    assert not envman.is_protected("JUPYTERLAB_FUTURE_KNOB")   # artefact lifts prefix guard
    assert envman.is_protected("JUPYTERLAB_OTHER")             # guard otherwise intact


def test_policy_missing_key_uses_builtin_for_that_key(policy_home):
    # only selector_managed given - the protective sets keep the built-in floor,
    # and the given key is added on top of (not in place of) the built-in
    policy_home.write_text("selector_managed: {FOO: 'somewhere'}\n")
    assert envman.is_protected("PATH")        # built-in protected_names survives
    assert envman.is_protected("MLFLOW_HOST")
    assert envman.selector_managed() == {
        "JUPYTERLAB_TERMINAL_SHELL": "Settings > Default Shell", "FOO": "somewhere"}


def test_policy_malformed_file_fails_safe_to_builtin(policy_home):
    policy_home.write_text(":::not: valid: yaml: [\n")
    assert envman.is_protected("PATH")
    assert envman.is_protected("MLFLOW_HOST")
    assert "JUPYTERLAB_TERMINAL_SHELL" in envman.selector_managed()


def test_policy_non_dict_file_fails_safe(policy_home):
    policy_home.write_text("- just\n- a\n- list\n")
    assert envman.is_protected("PATH")
    assert envman.selector_managed() == {"JUPYTERLAB_TERMINAL_SHELL": "Settings > Default Shell"}


def test_policy_empty_list_keeps_builtin_not_wipe(policy_home):
    # an explicit empty list is a typo / half-edit, never "drop all protection":
    # each key keeps the built-in floor instead of failing open
    policy_home.write_text(
        "protected_names: []\n"
        "protected_prefixes: []\n"
        "allowed_names: []\n"
        "selector_managed: {}\n")
    assert envman.is_protected("PATH")                    # names not wiped
    assert envman.is_protected("JUPYTERHUB_API_TOKEN")     # prefix guard not wiped
    assert not envman.is_protected("JUPYTERLAB_TERMINAL_SHELL")  # exemption kept
    assert "JUPYTERLAB_TERMINAL_SHELL" in envman.selector_managed()  # still hidden


def test_policy_unhashable_element_fails_safe(policy_home):
    # a nested list under protected_names would raise TypeError in set() - the
    # loader must fall back to the built-in, not crash the per-key boot export
    policy_home.write_text("protected_names: [PATH, [nested, list]]\n")
    assert envman.is_protected("PATH")
    assert envman.is_protected("MLFLOW_HOST")


def test_policy_non_string_prefix_element_does_not_crash_is_protected(policy_home):
    # an int in protected_prefixes survives tuple() but detonates later in
    # name.startswith(tuple) - reject the whole key so is_protected stays total
    policy_home.write_text("protected_prefixes: [JUPYTERLAB_, 5]\n")
    assert envman.is_protected("JUPYTERLAB_X")     # built-in prefixes kept
    assert envman.is_protected("JUPYTERHUB_X")
    assert not envman.is_protected("MY_VAR")       # and still returns for normal names


def test_policy_empty_string_prefix_does_not_lock_everything(policy_home):
    # "" in protected_prefixes makes startswith match every name - reject it so
    # a stray blank entry cannot silently protect/hide the entire environment
    policy_home.write_text('protected_prefixes: [JUPYTERLAB_, ""]\n')
    assert not envman.is_protected("MY_VAR")
    assert not envman.is_protected("AWS_PROFILE")
    assert envman.is_protected("JUPYTERLAB_X")     # built-in prefixes kept


def test_applet_edits_preserve_hidden_selector_managed_key(env_file):
    # the applet hides the shell key; add / edit / delete of a NORMAL var must
    # leave the hidden key intact in the store (set_var/delete_var are surgical,
    # never a rewrite of the filtered current_vars() - this locks that in)
    env_file.write_text(
        "MY_VAR='keep'\n"
        "JUPYTERLAB_TERMINAL_SHELL='/usr/bin/fish'\n")

    async def _go():
        app = envman.EnvManagerApp(env_path=env_file)
        async with app.run_test(size=(90, 24)) as pilot:
            await pilot.press("a")                       # add a new var
            await pilot.press(*"OTHER")
            await pilot.press("tab")
            await pilot.press(*"two")
            await pilot.press("enter")
            await pilot.pause()
            await pilot.press("d")                       # delete the highlighted var
            await pilot.press("y")
            await pilot.pause()

    asyncio.run(_go())
    stored = envman.parse_vars(envman.read_lines(env_file))
    # the selector-owned key rode through every applet write untouched
    assert stored["JUPYTERLAB_TERMINAL_SHELL"] == "/usr/bin/fish"


def test_shipped_artefact_matches_builtin_fallback():
    # drift guard: the shipped artefact must agree with the built-in net so a
    # missing file degrades to the SAME policy, not a surprise. Skipped when the
    # repo layout is absent (standalone package runs).
    import yaml
    artefact = (Path(__file__).resolve().parents[2]
                / "conf" / "utils" / "lab-utils.lib" / "env-var-policy.yml")
    if not artefact.is_file():
        pytest.skip("repo conf/utils layout not present")
    data = yaml.safe_load(artefact.read_text())
    assert set(data["protected_names"]) == set(envman._BUILTIN_POLICY["protected_names"])
    assert list(data["protected_prefixes"]) == list(envman._BUILTIN_POLICY["protected_prefixes"])
    assert set(data["allowed_names"]) == set(envman._BUILTIN_POLICY["allowed_names"])
    assert data["selector_managed"] == envman._BUILTIN_POLICY["selector_managed"]


# --- applet hides / refuses selector-managed keys -----------------------------

def test_applet_hides_selector_managed_key(env_file):
    env_file.write_text(
        "MY_VAR='keep'\n"
        "JUPYTERLAB_TERMINAL_SHELL='/usr/bin/fish'\n")

    async def _go():
        app = envman.EnvManagerApp(env_path=env_file)
        async with app.run_test(size=(90, 24)):
            texts = _option_texts(app)
            assert any("MY_VAR" in t for t in texts)
            assert not any("JUPYTERLAB_TERMINAL_SHELL" in t for t in texts)

    asyncio.run(_go())
    # the key is only hidden from the applet - it stays in the store file
    assert "JUPYTERLAB_TERMINAL_SHELL" in env_file.read_text()


def test_applet_refuses_adding_selector_managed_key(env_file):
    async def _go():
        app = envman.EnvManagerApp(env_path=env_file)
        async with app.run_test(size=(90, 24)) as pilot:
            await pilot.press("a")
            await pilot.press(*"JUPYTERLAB_TERMINAL_SHELL")
            await pilot.press("tab")
            await pilot.press(*"/bin/zsh")
            await pilot.press("enter")
            await pilot.pause()
            from textual.widgets import Static
            err = str(app.screen.query_one("#edit-error", Static).render())
            assert "managed via" in err and "Default Shell" in err

    asyncio.run(_go())
    assert not env_file.exists()
