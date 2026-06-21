"""Duoptimum-themed lab utilities menu and runner.

The lab-utils tool, refactored from a single script into a proper package:
YAML-driven menu, CLI, and a Duoptimum-styled Textual TUI.
"""

import os as _os

# Set truecolor before ANY submodule imports rich/textual and resolves the colour
# system. WSL/ttyd leave COLORTERM unset, which downsamples the dark slate palette;
# doing it here (package init) guarantees it runs ahead of every submodule import.
_os.environ.setdefault("COLORTERM", "truecolor")

from importlib import metadata
from pathlib import Path


def _resolve_version() -> str:
    """Installed dist version, falling back to the bundled _version.txt."""
    try:
        return metadata.version("duoptimum-lab-utils")
    except metadata.PackageNotFoundError:
        version_file = Path(__file__).with_name("_version.txt")
        try:
            return version_file.read_text(encoding="utf-8").strip() or "dev"
        except OSError:
            return "dev"


__version__ = _resolve_version()
