"""Run-on-start symlink management and applet toggle flow."""

import asyncio
import os

import pytest

pytest.importorskip("textual")

from duoptimum_lab_utils import onstart  # noqa: E402


@pytest.fixture
def dirs(tmp_path):
    source = tmp_path / "install-conda-env.d"
    source.mkdir()
    target = tmp_path / "start-platform.d"
    return source, target


def _script(source, name, executable=True):
    path = source / name
    path.write_text("#!/bin/bash\necho hi\n")
    if executable:
        os.chmod(path, 0o755)
    return path


# --- core ----------------------------------------------------------------

def test_list_scripts_only_executables(dirs):
    source, _ = dirs
    exe = _script(source, "a.sh")
    _script(source, "not-executable.sh", executable=False)
    (source / "subdir").mkdir()
    assert onstart.list_scripts([("g", source)]) == [("g", exe)]


def test_list_scripts_missing_dir_is_empty(tmp_path):
    assert onstart.list_scripts([("g", tmp_path / "absent")]) == []


def test_enable_disable_round_trip(dirs):
    source, target = dirs
    script = _script(source, "env.sh")
    assert not onstart.is_enabled(script, target)
    onstart.enable(script, target)
    assert onstart.is_enabled(script, target)
    assert (target / "env.sh").resolve() == script
    onstart.disable(script, target)
    assert not onstart.is_enabled(script, target)
    assert not (target / "env.sh").exists()


def test_enable_never_overwrites_real_user_file(dirs):
    source, target = dirs
    script = _script(source, "env.sh")
    target.mkdir()
    (target / "env.sh").write_text("user's own script")
    with pytest.raises(FileExistsError):
        onstart.enable(script, target)
    assert (target / "env.sh").read_text() == "user's own script"


def test_disable_leaves_real_user_file_alone(dirs):
    source, target = dirs
    script = _script(source, "env.sh")
    target.mkdir()
    (target / "env.sh").write_text("user's own script")
    onstart.disable(script, target)
    assert (target / "env.sh").exists()


def test_stale_symlink_to_other_target_not_enabled_and_replaceable(dirs):
    source, target = dirs
    script = _script(source, "env.sh")
    target.mkdir()
    (target / "env.sh").symlink_to(source / "gone.sh")
    assert not onstart.is_enabled(script, target)
    onstart.enable(script, target)  # stale symlink replaced
    assert onstart.is_enabled(script, target)


# --- applet ----------------------------------------------------------------

def _option_texts(app):
    from textual.widgets import OptionList
    option_list = app.query_one("#script-list", OptionList)
    return [str(option_list.get_option_at_index(i).prompt)
            for i in range(option_list.option_count)]


def test_applet_lists_and_toggles(dirs, tmp_path, monkeypatch):
    source, target = dirs
    _script(source, "tensorflow.sh")
    # hermetic: on a platform install /opt/utils/lab-utils.yml exists and maps
    # tensorflow.sh -> "TensorFlow", which would beat the fallback asserted below
    monkeypatch.setattr(onstart.config, "menu_config_path",
                        lambda: tmp_path / "absent-menu.yml")

    async def _go():
        app = onstart.OnStartApp(groups=[("conda env", source)], target_dir=target)
        async with app.run_test(size=(90, 24)) as pilot:
            # rows show display names (title-cased stem, or the menu's own name)
            assert any("[off]" in t and "Tensorflow" in t for t in _option_texts(app))
            await pilot.press("space")
            await pilot.pause()
            assert any("[ on]" in t for t in _option_texts(app))
            assert (target / "tensorflow.sh").is_symlink()
            await pilot.press("space")
            await pilot.pause()
            assert any("[off]" in t for t in _option_texts(app))
            assert not (target / "tensorflow.sh").exists()

    asyncio.run(_go())


def test_applet_empty_state(tmp_path):
    async def _go():
        app = onstart.OnStartApp(groups=[("g", tmp_path / "absent")],
                                 target_dir=tmp_path / "t")
        async with app.run_test(size=(90, 24)):
            assert "no standard scripts found" in _option_texts(app)[0]

    asyncio.run(_go())
