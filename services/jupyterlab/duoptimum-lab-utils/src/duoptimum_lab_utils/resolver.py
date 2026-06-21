"""Script discovery and path resolution.

Resolves a script id (bare name, .sh, parent/child, or absolute path) to an
executable under the global, lib, or user-local script dirs, and walks those
dirs to build the listing used by the menu and the CLI.
"""

import os
from pathlib import Path

from . import config


def get_script_description(script_path: Path) -> str:
    """Description from a script's first line starting with ##."""
    try:
        with open(script_path) as f:
            for line in f:
                if line.startswith("##"):
                    return line[2:].strip()
        return "No description available"
    except Exception:
        return "No description available"


def resolve_script_path(script_id: str, is_full_path: bool = False) -> Path | None:
    """Resolve a script id to an existing executable file, or None.

    Supports "script", "script.sh", "parent/child", "parent.d/child.sh" relative
    to the global / lib / local script dirs, and absolute or ~ paths.
    """

    def is_valid_script(path: Path) -> bool:
        return path.exists() and path.is_file() and os.access(path, os.X_OK)

    # Absolute / home-relative paths.
    if is_full_path or script_id.startswith("/") or script_id.startswith("~"):
        full_path = Path(os.path.expanduser(script_id))
        return full_path if is_valid_script(full_path) else None

    paths_to_try = [script_id]
    if not script_id.endswith(".sh"):
        paths_to_try.append(f"{script_id}.sh")

    # parent/child -> parent.d/child(.sh)
    if "/" in script_id and ".d/" not in script_id:
        parent, child = script_id.split("/", 1)
        paths_to_try.append(f"{parent}.d/{child}")
        if not child.endswith(".sh"):
            paths_to_try.append(f"{parent}.d/{child}.sh")

    for base_dir in [config.global_scripts_dir(), config.lib_dir(), config.local_scripts_dir()]:
        for path in paths_to_try:
            full_path = base_dir / path
            if is_valid_script(full_path):
                return full_path

    return None


def get_all_scripts_from_dir(scripts_dir: Path, source_label: str) -> list:
    """All scripts in a directory, including one level of nested .d children."""
    scripts = []
    if not scripts_dir.exists():
        return scripts

    processed_subdirs = set()

    for script in sorted(scripts_dir.glob("*.sh")):
        if script.is_file() and os.access(script, os.X_OK):
            name = script.stem
            scripts.append({
                "name": name,
                "description": get_script_description(script),
                "source": source_label,
                "level": "top",
                "path": script,
            })

            subdir = scripts_dir / f"{name}.d"
            if subdir.is_dir():
                processed_subdirs.add(subdir.name)
                for child_script in sorted(subdir.glob("*.sh")):
                    if child_script.is_file() and os.access(child_script, os.X_OK):
                        scripts.append({
                            "name": f"{name}/{child_script.stem}",
                            "description": get_script_description(child_script),
                            "source": source_label,
                            "level": "child",
                            "path": child_script,
                        })

    for subdir in sorted(scripts_dir.glob("*.d")):
        if subdir.is_dir() and subdir.name not in processed_subdirs:
            parent_name = subdir.name[:-2]
            scripts.append({
                "name": parent_name,
                "description": f"Scripts in {subdir.name}/",
                "source": source_label,
                "level": "top",
                "path": None,
            })
            for child_script in sorted(subdir.glob("*.sh")):
                if child_script.is_file() and os.access(child_script, os.X_OK):
                    scripts.append({
                        "name": f"{parent_name}/{child_script.stem}",
                        "description": get_script_description(child_script),
                        "source": source_label,
                        "level": "child",
                        "path": child_script,
                    })

    return scripts


def get_all_scripts() -> tuple:
    """(global_scripts, local_scripts) from the deployment and user dirs."""
    global_scripts = get_all_scripts_from_dir(config.global_scripts_dir(), "global")
    local_scripts = get_all_scripts_from_dir(config.local_scripts_dir(), "local")
    return global_scripts, local_scripts
