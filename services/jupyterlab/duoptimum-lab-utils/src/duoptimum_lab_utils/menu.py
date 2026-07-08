"""YAML menu loading: root config, directory scans, external menu files, and
injection of the admin-provisioned auxiliary menu from a shared volume.
"""

import os
import sys
from pathlib import Path

import yaml

from . import config
from .resolver import get_script_description

AUX_MENU_ENV = "JUPYTERLAB_AUX_MENU_PATH"
_EXCLUDED = {"README.md", "readme.md"}


def switch_off(var: str) -> bool:
    """True when the named platform switch is 0 after whitespace trim.

    THE lock predicate - envman.store_locked() delegates here, and the bash
    consumers see the same contract because start-platform.sh normalizes the
    switch value once at boot. Unset or any other value = on (the platform
    switch convention, matching e.g. JUPYTERLAB_SUDO_ENABLE)."""
    return os.environ.get(var, "1").strip() == "0"


def prune_disabled(items: list) -> list:
    """Drop items whose `enable_env` switch is off, recursing into submenus.

    An item carrying `enable_env: VAR` is hidden when switch_off(VAR). Used by
    the env Settings entries so a deployment with JUPYTERLAB_USER_ENV_ENABLE=0
    shows no dead menu items for the locked user env store."""
    kept = []
    for item in items:
        if isinstance(item, dict):
            switch = item.get("enable_env")
            if switch and switch_off(switch):
                continue
            if isinstance(item.get("submenu"), list):
                item["submenu"] = prune_disabled(item["submenu"])
        kept.append(item)
    return kept


def load_menu_config() -> dict:
    """Load the root menu YAML.

    When JUPYTERLAB_AUX_MENU_PATH is set, scan it and inject an "Auxiliary Menu"
    submenu before the last root item (Local Scripts). Executable scripts become
    direct items, YAML files become submenus.
    """
    menu_config = config.menu_config_path()
    if not menu_config.exists():
        print(f"Error: Menu configuration not found: {menu_config}", file=sys.stderr)
        sys.exit(1)

    with open(menu_config) as f:
        data = yaml.safe_load(f)

    menu = data.get("menu") if isinstance(data, dict) else None
    if isinstance(menu, dict) and isinstance(menu.get("items"), list):
        menu["items"] = prune_disabled(menu["items"])

    aux_menu_path = os.environ.get(AUX_MENU_ENV, "")
    if aux_menu_path:
        aux_dir = Path(os.path.expanduser(aux_menu_path))
        if aux_dir.is_dir():
            aux_children = []
            for entry in sorted(aux_dir.iterdir()):
                if entry.name in _EXCLUDED or not entry.is_file():
                    continue

                if entry.suffix.lower() in {".yml", ".yaml"}:
                    submenu_name = entry.stem
                    try:
                        with open(entry) as f:
                            peek = yaml.safe_load(f)
                        if isinstance(peek, dict) and peek.get("name"):
                            submenu_name = peek["name"]
                    except Exception:
                        pass
                    aux_children.append({
                        "name": submenu_name,
                        "menu_file": str(entry),
                    })
                elif os.access(entry, os.X_OK):
                    aux_children.append({
                        "id": str(entry),
                        "name": entry.stem,
                        "description": get_script_description(entry),
                        "marker": "aux",
                        "_full_path": True,
                    })

            if aux_children:
                aux_item = {
                    "name": "Auxiliary Menu",
                    "description": "Admin-provisioned tools from shared volume",
                    "submenu": aux_children,
                }
                items = data.get("menu", {}).get("items", [])
                if items:
                    items.insert(-1, aux_item)
                else:
                    items.append(aux_item)

    return data


def scan_directory_for_menu_items(scan_dir: str) -> list:
    """Scan a directory for executables and conda-env YAML files -> menu items."""
    dir_path = Path(os.path.expanduser(scan_dir))
    if not dir_path.exists() or not dir_path.is_dir():
        return []

    items = []
    for item in sorted(dir_path.iterdir()):
        if item.name in _EXCLUDED or not item.is_file():
            continue

        if item.suffix.lower() in {".yml", ".yaml"}:
            items.append({
                "id": str(item),
                "name": item.stem,
                "description": "Conda environment file",
                "marker": "conda",
                "_full_path": True,
                "_conda_env": True,
            })
        elif os.access(item, os.X_OK):
            items.append({
                "id": str(item),
                "name": item.stem,
                "description": get_script_description(item),
                "marker": "custom",
                "_full_path": True,
            })

    return items


def load_menu_file_items(menu_file_path: str) -> list:
    """Load menu items from an external YAML file (dict-with-items or bare list)."""
    path = Path(os.path.expandvars(os.path.expanduser(menu_file_path)))
    if not path.exists() or not path.is_file():
        return []

    try:
        with open(path) as f:
            data = yaml.safe_load(f)
    except Exception:
        return []

    if data is None:
        return []

    if isinstance(data, dict) and "items" in data:
        items = data["items"]
        return prune_disabled(items) if isinstance(items, list) else []

    if isinstance(data, list):
        return prune_disabled(data)

    return []
