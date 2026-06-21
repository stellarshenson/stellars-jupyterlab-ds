"""Selector current value, option resolution, and apply."""

from duoptimum_lab_utils import selectors


def test_current_literal(data_home):
    assert selectors.get_selector_current({"current": "x"}) == "x"


def test_current_from_script(data_home):
    assert selectors.get_selector_current({"current_script": "cur"}) == "two"


def test_current_from_command(data_home):
    assert selectors.get_selector_current({"current_cmd": "echo zzz"}) == "zzz"


def test_options_inline_with_current_marking(data_home):
    cfg = {
        "current": "two",
        "options": [{"value": "one"}, {"value": "two"}],
    }
    opts = selectors.get_selector_options(cfg)
    marked = {o["value"]: o.get("current", False) for o in opts}
    assert marked == {"one": False, "two": True}


def test_options_from_script(data_home):
    opts = selectors.get_selector_options({"options_script": "opts"})
    assert [o["value"] for o in opts] == ["one", "two"]


def test_apply_via_command(data_home):
    result = selectors.apply_selector_choice({"apply_cmd": "true"}, "one")
    assert result.returncode == 0


def test_apply_via_script(data_home):
    result = selectors.apply_selector_choice({"apply_script": "alpha"}, "one")
    assert result.returncode == 0


def test_apply_no_action(data_home):
    result = selectors.apply_selector_choice({}, "one")
    assert result.returncode == 1
