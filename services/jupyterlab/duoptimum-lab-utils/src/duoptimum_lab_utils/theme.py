"""Duoptimum palette, role mapping and shared styling.

Cyan + orange on dark blue-grey, low saturation. Used by the Textual TUI (CSS
fragments + colour roles) and by the rich-themed CLI console. No textual import
here, so this module loads anywhere; rich degrades to a plain console if absent.
"""

# Importing the package (done implicitly here) runs its __init__, which sets
# COLORTERM=truecolor before rich/textual resolve the colour system.
from . import __version__

APP_TITLE = "Lab Utils"
VERSION = __version__

# Duoptimum palette (from the platform theme tokens, DARK).
DUO = {
    "cyan":          "#21a8e4",
    "cyan_bright":   "#46bcf0",
    "cyan_deep":     "#0e93cf",
    "cyan_dark":     "#0096d1",
    "orange":        "#da8230",
    "orange_bright": "#f0a050",
    "orange_dark":   "#a86420",
    "amber":         "#e6c660",
    "mint":          "#3fb950",
    "rose":          "#ef4444",
    "bg_dim":        "#1a1f25",
    "bg":            "#252b32",
    "bg_subtle":     "#2a313a",
    "surface":       "#303841",
    "surface_hi":    "#374049",
    "border":        "#404b54",
    "border_hi":     "#4d5a65",
    "text":          "#c3c3c3",
    "text_muted":    "#a5a5a5",
    "text_subtle":   "#7d8791",
}

# Role mapping - colours carry meaning, kept consistent across screens.
PASTEL = {
    "title":   DUO["cyan_bright"],   # section headers / app title
    "submenu": DUO["cyan"],          # navigable into a deeper menu
    "tag":     DUO["amber"],         # attention tag, e.g. [aux] / [base]
    "name":    DUO["text"],          # leaf item name
    "desc":    DUO["text_subtle"],   # descriptions
    "nav":     DUO["text_muted"],    # Back / Exit rows
    "ok":      DUO["mint"],          # success
    "warn":    DUO["orange"],        # warning
    "err":     DUO["rose"],          # error
    "info":    DUO["cyan"],          # info text (cyan_dark fails WCAG AA on bg_subtle)
}

# Shared one-row top header: app name left, version pinned to the right corner.
# Interpolated into each App's CSS via {HEADER_CSS}.
HEADER_CSS = f"""
        #app-header {{ height: 1; background: {DUO['bg_subtle']}; }}
        #hdr-title {{ width: 1fr; padding: 0 2; color: {PASTEL['title']}; text-style: bold; }}
        #hdr-version {{ width: auto; padding: 0 2; color: {DUO['text_subtle']}; }}
"""

# rich console for the CLI. Remap rich's named colours to the Duoptimum palette so
# styled output renders soft. Falls back to a plain console when rich is absent.
try:
    from rich.console import Console
    from rich.theme import Theme

    PASTEL_THEME = Theme({
        "red":     PASTEL["err"],
        "green":   PASTEL["ok"],
        "blue":    PASTEL["info"],
        "yellow":  PASTEL["warn"],
        "cyan":    PASTEL["title"],
        "magenta": PASTEL["submenu"],
    })
    console = Console(theme=PASTEL_THEME)
    HAVE_RICH = True
except ImportError:  # pragma: no cover - rich is a declared dependency
    PASTEL_THEME = None
    HAVE_RICH = False

    class _PlainConsole:
        """Minimal stand-in so the CLI degrades to plain text without rich."""

        def print(self, *args, **kwargs):
            print(*(str(a) for a in args))

    console = _PlainConsole()
