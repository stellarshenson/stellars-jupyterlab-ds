"""Selector logic: resolve the current value and the option list for a selector
item from a literal, a script, or a shell command, and apply the chosen value.

Pure logic, no textual - the selector UI lives in tui.py.
"""

import json
import subprocess

from .resolver import resolve_script_path


def get_selector_current(selector_config: dict) -> str:
    """Current value from a literal, a script's stdout, or a command's stdout."""
    if "current" in selector_config:
        return selector_config["current"]

    if "current_script" in selector_config:
        script_path = resolve_script_path(selector_config["current_script"])
        if script_path:
            result = subprocess.run([str(script_path)], capture_output=True, text=True)
            if result.returncode == 0:
                return result.stdout.strip()
        return ""

    if "current_cmd" in selector_config:
        result = subprocess.run(
            selector_config["current_cmd"], shell=True, capture_output=True, text=True
        )
        if result.returncode == 0:
            return result.stdout.strip()
        return ""

    return ""


def get_selector_options(selector_config: dict) -> list:
    """Option dicts [{"value", "label", "current"}, ...] from inline list, script,
    or command (JSON), with the current option marked."""
    options = []

    if "options" in selector_config:
        options = [dict(o) for o in selector_config["options"]]  # copy, avoid mutation
    elif "options_script" in selector_config:
        script_path = resolve_script_path(selector_config["options_script"])
        if script_path:
            result = subprocess.run([str(script_path)], capture_output=True, text=True)
            if result.returncode == 0:
                try:
                    options = json.loads(result.stdout)
                except json.JSONDecodeError:
                    pass
    elif "options_cmd" in selector_config:
        result = subprocess.run(
            selector_config["options_cmd"], shell=True, capture_output=True, text=True
        )
        if result.returncode == 0:
            try:
                options = json.loads(result.stdout)
            except json.JSONDecodeError:
                pass

    current_value = get_selector_current(selector_config)
    if current_value and options:
        for opt in options:
            if opt.get("value") == current_value:
                opt["current"] = True
            elif "current" in opt and opt.get("value") != current_value:
                opt["current"] = False

    return options


def apply_selector_choice(selector_config: dict, value: str) -> subprocess.CompletedProcess:
    """Apply the chosen value via the configured apply_script or apply_cmd."""
    args = selector_config.get("apply_args", "").split() if selector_config.get("apply_args") else []
    args.append(value)

    if "apply_script" in selector_config:
        script_path = resolve_script_path(selector_config["apply_script"])
        if script_path:
            return subprocess.run([str(script_path)] + args)
        return subprocess.CompletedProcess(args=[], returncode=1)

    if "apply_cmd" in selector_config:
        cmd = f"{selector_config['apply_cmd']} {' '.join(args)}"
        return subprocess.run(cmd, shell=True)

    return subprocess.CompletedProcess(args=[], returncode=1)
