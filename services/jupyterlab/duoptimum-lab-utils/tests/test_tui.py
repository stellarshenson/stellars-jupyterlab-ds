"""Headless Textual render checks: Duoptimum palette present, no legacy glyphs."""

import asyncio

import pytest

pytest.importorskip("textual")

from duoptimum_lab_utils import tui  # noqa: E402
from duoptimum_lab_utils.theme import DUO  # noqa: E402

LEGACY_GLYPHS = "▶◆●◀✕"  # triangle diamond bullet back cross

ROOT = {
    "title": "Test",
    "items": [
        {"name": "Sub", "submenu": [{"id": "x", "name": "X"}]},
        {"id": "alpha.sh", "name": "Alpha", "description": "a script", "marker": "custom"},
    ],
}


def test_item_text_has_no_glyphs():
    app = tui.LabUtilsApp(ROOT)
    for i, item in enumerate(ROOT["items"]):
        rendered = str(app._item_text(item, i))
        assert not any(g in rendered for g in LEGACY_GLYPHS)


def test_submenu_type_signalled_by_text():
    # submenu distinguishable from a leaf without relying on colour
    app = tui.LabUtilsApp(ROOT)
    submenu = str(app._item_text(ROOT["items"][0], 0))
    leaf = str(app._item_text(ROOT["items"][1], 1))
    assert submenu.endswith("/")
    assert not leaf.endswith("/")


def test_header_renders_above_breadcrumb():
    async def _go():
        app = tui.LabUtilsApp(ROOT)
        async with app.run_test(size=(80, 24)):
            return (app.query_one("#app-header").region.y,
                    app.query_one("#breadcrumb").region.y)
    header_y, breadcrumb_y = asyncio.run(_go())
    assert header_y < breadcrumb_y


def _render_svg():
    async def _go():
        app = tui.LabUtilsApp(ROOT)
        async with app.run_test(size=(80, 24)):
            return app.export_screenshot()
    return asyncio.run(_go())


def test_render_uses_duoptimum_background():
    svg = _render_svg().lower()
    assert DUO["bg_dim"].lower() in svg


def test_render_has_no_legacy_glyphs():
    svg = _render_svg()
    assert not any(g in svg for g in LEGACY_GLYPHS)


# --- issue 2: the standard command palette is disabled (in-menu filter replaces it)

def test_command_palette_disabled():
    assert tui.LabUtilsApp.ENABLE_COMMAND_PALETTE is False


# --- issue 1: breadcrumb must not duplicate the header title at the root level

def test_breadcrumb_does_not_duplicate_title_at_root():
    async def _go():
        app = tui.LabUtilsApp(ROOT)
        async with app.run_test(size=(80, 24)):
            return str(app._breadcrumb_text())
    bc = asyncio.run(_go())
    assert bc.strip() != ROOT["title"]      # not the root title repeated
    assert "type to filter" in bc           # a useful hint instead


# --- issue 3: type-to-filter across the subtree, ancestor path + match highlight

NESTED = {
    "title": "Test",
    "items": [
        {"name": "Sub", "submenu": [
            {"id": "x", "name": "X"},
            {"id": "git-thing", "name": "git-commit", "description": "commit repos"},
        ]},
        {"id": "alpha.sh", "name": "Alpha"},
    ],
}


def test_filtered_text_shows_path_and_highlights_match():
    app = tui.LabUtilsApp(NESTED)
    item = {"id": "git-thing", "name": "git-commit"}
    t = app._filtered_text(("Sub",), item, "git")
    assert str(t).startswith("Sub / ")          # ancestor path shown
    assert "git-commit" in str(t)
    # the typed run carries a bold amber style span
    assert any("bold" in str(sp.style) and DUO["amber"].lower() in str(sp.style).lower()
               for sp in t.spans)


def test_typing_filters_nested_command_with_path():
    async def _go():
        app = tui.LabUtilsApp(NESTED)
        async with app.run_test(size=(80, 24)) as pilot:
            await pilot.press("g", "i", "t")
            menu = app.query_one("#menu", tui.OptionList)
            labels = [str(menu.get_option_at_index(i).prompt)
                      for i in range(menu.option_count)]
            names = [it.get("name") for _, it in app.filtered]
            return app.filter_query, labels, names
    query, labels, names = asyncio.run(_go())
    assert query == "git"
    assert "git-commit" in names                 # nested leaf found from the root
    assert "Alpha" not in names                  # non-matching leaf filtered out
    assert any("Sub" in lbl and "git-commit" in lbl for lbl in labels)


def test_escape_clears_the_filter():
    # escape must clear the filter only - not ALSO fire the Back/quit binding
    async def _go():
        app = tui.LabUtilsApp(NESTED)
        async with app.run_test(size=(80, 24)) as pilot:
            await pilot.press("g", "i", "t")
            during = app.filter_query
            await pilot.press("escape")
            return during, app.filter_query, app.is_running, len(app.menu_stack)
    during, after, running, stack = asyncio.run(_go())
    assert during == "git"
    assert after == ""
    assert running is True       # did not quit
    assert stack == 1            # did not pop the root menu


def test_press_enter_survives_closed_stdin(monkeypatch):
    # closed/redirected stdin (echo | lab-utils, CI) raises EOFError on input() - caught, no traceback
    monkeypatch.setattr(tui, "get_selector_options", lambda cfg: [])

    def _eof(*_a, **_k):
        raise EOFError

    monkeypatch.setattr("builtins.input", _eof)
    tui.run_selector({}, "Test")  # must return cleanly, not raise EOFError
