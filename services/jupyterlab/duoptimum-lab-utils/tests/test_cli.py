"""CLI dispatch, JSON listing, scaffolding, and exit codes."""

import json

import pytest

from duoptimum_lab_utils import cli


def _run_main(monkeypatch, argv):
    monkeypatch.setattr("sys.argv", ["lab-utils"] + argv)
    cli.main()


def test_json_listing_shape(data_home, capsys):
    cli.list_scripts_json()
    out = json.loads(capsys.readouterr().out)
    assert set(out) == {"global", "local"}
    names = {s["name"] for s in out["global"]["scripts"]}
    assert {"alpha", "beta", "tools"} <= names


def test_json_is_plain(data_home, capsys):
    cli.list_scripts_json()
    out = capsys.readouterr().out
    assert "\x1b[" not in out  # no ANSI escapes in machine-readable output


def test_main_help_returns(data_home, monkeypatch):
    _run_main(monkeypatch, ["--help"])  # no SystemExit


def test_main_unknown_option_exits_1(data_home, monkeypatch, capsys):
    with pytest.raises(SystemExit) as exc:
        _run_main(monkeypatch, ["--bogus"])
    assert exc.value.code == 1
    captured = capsys.readouterr()
    assert "Unknown option" in captured.err  # fatal errors go to stderr
    assert captured.out == ""


def test_main_unknown_script_exits_1(data_home, monkeypatch, capsys):
    with pytest.raises(SystemExit) as exc:
        _run_main(monkeypatch, ["does-not-exist"])
    assert exc.value.code == 1
    captured = capsys.readouterr()
    assert "not found" in captured.err  # fatal errors go to stderr
    assert captured.out == ""


def test_main_direct_run_exits_0(data_home, monkeypatch):
    with pytest.raises(SystemExit) as exc:
        _run_main(monkeypatch, ["alpha"])
    assert exc.value.code == 0


def test_create_local_scaffold(data_home, monkeypatch):
    cli.create_local_scripts()
    from duoptimum_lab_utils import config
    demo = config.local_scripts_dir() / "my-script.sh"
    assert demo.exists()
    import os
    assert os.access(demo, os.X_OK)


def test_create_local_idempotent(data_home, capsys):
    cli.create_local_scripts()
    capsys.readouterr()
    cli.create_local_scripts()
    assert "already exists" in capsys.readouterr().out
