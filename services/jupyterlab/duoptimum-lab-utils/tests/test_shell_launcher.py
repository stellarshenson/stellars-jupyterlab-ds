"""launch-shell.sh - spawn-time Default Shell resolution for terminado.

Runs the REAL script from conf/utils with a controlled HOME and canary shells
that record how they were invoked. Skipped when the repo layout is absent
(standalone package test runs)."""

import os
import subprocess
from pathlib import Path

import pytest

LAUNCHER = (Path(__file__).resolve().parents[2]
            / "conf" / "utils" / "launch-shell.sh")

pytestmark = pytest.mark.skipif(
    not LAUNCHER.is_file(), reason="repo conf/utils layout not present")


@pytest.fixture
def home(tmp_path):
    (tmp_path / ".local").mkdir()
    return tmp_path


def canary(tmp_path, name):
    """Executable that prints a marker + its argv, ignoring stdin."""
    c = tmp_path / name
    c.write_text(f"#!/bin/sh\necho CANARY:{name} \"$@\"\n")
    c.chmod(0o755)
    return c


def launch(home, env=None, stdin=""):
    e = {"HOME": str(home), "PATH": os.environ["PATH"]}
    e.update(env or {})
    return subprocess.run(["bash", str(LAUNCHER)], env=e, input=stdin,
                          capture_output=True, text=True, timeout=15)


def store(home, line):
    (home / ".local" / "environment.env").write_text(line)


def test_store_value_wins_and_gets_login_flag(home, tmp_path):
    fish = canary(tmp_path, "fish")
    store(home, f"JUPYTERLAB_TERMINAL_SHELL='{fish}'\n")
    out = launch(home, env={"JUPYTERLAB_TERMINAL_SHELL": "/bin/bash"}).stdout
    assert f"CANARY:fish --login" in out


def test_env_default_when_store_lacks_key(home, tmp_path):
    zsh = canary(tmp_path, "zsh")
    store(home, "OTHER_VAR='x'\n")
    out = launch(home, env={"JUPYTERLAB_TERMINAL_SHELL": str(zsh)}).stdout
    assert "CANARY:zsh --login" in out


def test_bash_fallback_when_nothing_configured(home):
    # no store key, no env - /bin/bash --login runs the piped command
    r = launch(home, stdin="echo RUNNING_IN=$0\n")
    assert "RUNNING_IN=/bin/bash" in r.stdout


def test_locked_store_is_ignored(home, tmp_path):
    fish = canary(tmp_path, "fish")
    store(home, f"JUPYTERLAB_TERMINAL_SHELL='{fish}'\n")
    r = launch(home, env={"JUPYTERLAB_USER_ENV_ENABLE": "0"},
               stdin="echo RUNNING_IN=$0\n")
    assert "CANARY" not in r.stdout
    assert "RUNNING_IN=/bin/bash" in r.stdout


def test_locked_store_whitespace_padded_switch(home, tmp_path):
    # "0 " from a hand-edited .env must still lock - same trim as switch_off
    fish = canary(tmp_path, "fish")
    store(home, f"JUPYTERLAB_TERMINAL_SHELL='{fish}'\n")
    r = launch(home, env={"JUPYTERLAB_USER_ENV_ENABLE": "0 "},
               stdin="echo RUNNING_IN=$0\n")
    assert "CANARY" not in r.stdout


def test_bogus_store_value_falls_back_not_dead_terminal(home):
    for bogus in ["/nonexistent/fish", "fish", "''", ""]:
        store(home, f"JUPYTERLAB_TERMINAL_SHELL={bogus}\n")
        r = launch(home, stdin="echo RUNNING_IN=$0\n")
        assert "RUNNING_IN=/bin/bash" in r.stdout, f"bogus={bogus!r}"


def test_quote_styles_and_last_wins(home, tmp_path):
    fish = canary(tmp_path, "fish")
    zsh = canary(tmp_path, "zsh")
    for form in [f'"{fish}"', f"'{fish}'", f"{fish}"]:
        store(home, f"JUPYTERLAB_TERMINAL_SHELL={zsh}\n"
                    f"export JUPYTERLAB_TERMINAL_SHELL={form}\n")
        out = launch(home).stdout
        assert "CANARY:fish" in out, f"form={form}"
        assert "CANARY:zsh" not in out


def test_config_points_at_the_launcher():
    # drift guard: jupyter_lab_config.py must reference the shipped launcher
    config = (Path(__file__).resolve().parents[2]
              / "conf" / "etc" / "jupyter" / "jupyter_lab_config.py")
    assert "/opt/utils/launch-shell.sh" in config.read_text()


def test_parser_parity_with_envman_canonical_form(home, tmp_path):
    # tripwire for the dual-parser risk: values written by envman.set_var (the
    # ONLY writer the selector uses) must always resolve in the launcher. If
    # set_var's quoting convention ever changes, this breaks loudly in CI
    # instead of terminals silently falling back to bash.
    from duoptimum_lab_utils import envman
    plain = canary(tmp_path, "fish")
    spaced_dir = tmp_path / "my shells"
    spaced_dir.mkdir()
    spaced = canary(spaced_dir, "zsh")
    store_file = home / ".local" / "environment.env"
    for shell, marker in [(plain, "CANARY:fish"), (spaced, "CANARY:zsh")]:
        envman.set_var("JUPYTERLAB_TERMINAL_SHELL", str(shell), store_file)
        out = launch(home).stdout
        assert f"{marker} --login" in out, f"launcher failed canonical form for {shell}"


def test_embedded_quote_path_fails_safe_to_bash(home, tmp_path):
    # a path containing a single quote is stored shell-escaped ('\'' form) -
    # the launcher's one-layer strip refuses it and MUST fall back to bash,
    # never spawn a mangled path (documented limitation, fail-safe direction)
    from duoptimum_lab_utils import envman
    qdir = tmp_path / "it's"
    qdir.mkdir()
    shell = canary(qdir, "fish")
    envman.set_var("JUPYTERLAB_TERMINAL_SHELL", str(shell), home / ".local" / "environment.env")
    r = launch(home, stdin="echo RUNNING_IN=$0\n")
    assert "CANARY" not in r.stdout
    assert "RUNNING_IN=/bin/bash" in r.stdout


def test_unreadable_store_falls_back(home, tmp_path):
    fish = canary(tmp_path, "fish")
    store(home, f"JUPYTERLAB_TERMINAL_SHELL='{fish}'\n")
    sf = home / ".local" / "environment.env"
    sf.chmod(0o000)
    try:
        if os.access(sf, os.R_OK):  # running as root - the gate can't trigger
            pytest.skip("cannot make file unreadable for this uid")
        r = launch(home, stdin="echo RUNNING_IN=$0\n")
        assert "CANARY" not in r.stdout
        assert "RUNNING_IN=/bin/bash" in r.stdout
    finally:
        sf.chmod(0o644)


def test_empty_store_file_falls_back(home):
    store(home, "")
    r = launch(home, stdin="echo RUNNING_IN=$0\n")
    assert "RUNNING_IN=/bin/bash" in r.stdout


def test_symlinked_home_resolves_store(home, tmp_path_factory):
    fish = canary(home, "fish")
    store(home, f"JUPYTERLAB_TERMINAL_SHELL='{fish}'\n")
    linkhome = tmp_path_factory.mktemp("link") / "home-link"
    linkhome.symlink_to(home)
    out = launch(linkhome).stdout
    assert "CANARY:fish --login" in out
