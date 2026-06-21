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
