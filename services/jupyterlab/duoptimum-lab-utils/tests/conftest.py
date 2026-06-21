"""Shared fixtures: an isolated deployment data root copied from tests/fixtures."""

import shutil
import stat
from pathlib import Path

import pytest

FIXTURES = Path(__file__).parent / "fixtures"


def _make_executable(path: Path) -> None:
    path.chmod(path.stat().st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)


@pytest.fixture
def data_home(tmp_path, monkeypatch):
    """Copy the fixture tree to a temp dir, mark scripts executable, point the
    tool at it, and isolate HOME so user-local scripts do not leak in."""
    dest = tmp_path / "data"
    shutil.copytree(FIXTURES, dest)
    for script in dest.rglob("*.sh"):
        _make_executable(script)

    home = tmp_path / "home"
    home.mkdir()

    monkeypatch.setenv("DUOPTIMUM_LAB_UTILS_HOME", str(dest))
    monkeypatch.setenv("HOME", str(home))
    monkeypatch.delenv("JUPYTERLAB_AUX_MENU_PATH", raising=False)
    return dest
