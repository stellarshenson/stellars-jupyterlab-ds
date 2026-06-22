"""Version resolution and the platform-sync contract.

The package version is dynamic from src/duoptimum_lab_utils/_version.txt, which
`make increment_version` keeps in sync with the platform pyproject version (the
Dockerfile builder also stamps it from the PKG_VERSION build arg). These tests
guard that the file holds a real semver - not a stale 0.0.0 placeholder - and
that __version__ resolves, falling back to the file when no dist metadata exists.
"""

import re
from importlib import metadata
from pathlib import Path

import duoptimum_lab_utils as pkg

SEMVER = re.compile(r"^\d+\.\d+\.\d+$")


def _version_file() -> Path:
    return Path(pkg.__file__).with_name("_version.txt")


def test_version_file_holds_a_real_semver():
    # synced to the platform version by make increment_version, never left at 0.0.0
    text = _version_file().read_text(encoding="utf-8").strip()
    assert SEMVER.match(text), f"_version.txt should be X.Y.Z, got {text!r}"
    assert text != "0.0.0", "_version.txt must be synced to the platform version, not the placeholder"


def test_package_version_resolves():
    assert pkg.__version__
    assert pkg.__version__ != "dev"


def test_version_fallback_reads_version_file(monkeypatch):
    # with no installed dist metadata, _resolve_version returns the bundled file
    def _not_found(name):
        raise metadata.PackageNotFoundError(name)

    monkeypatch.setattr(pkg.metadata, "version", _not_found)
    assert pkg._resolve_version() == _version_file().read_text(encoding="utf-8").strip()
