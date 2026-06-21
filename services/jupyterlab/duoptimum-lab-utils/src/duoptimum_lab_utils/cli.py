"""Command-line entry point: argument dispatch, the script listing and scaffold
commands, direct script execution, and the shared run banners.

Coloured output goes through rich Text segments (no inline markup, so dynamic
content with brackets is safe) and degrades to plain text without rich. The
interactive menu (textual) is imported lazily so the CLI works without textual.
"""

import json
import subprocess
import sys
from pathlib import Path

from . import config, theme
from .resolver import get_all_scripts, resolve_script_path

_RULE = "=" * 60


def _emit(segments) -> None:
    """Print a line of (text, style) segments, styled via rich or plain."""
    if theme.HAVE_RICH:
        from rich.text import Text
        line = Text()
        for text, style in segments:
            line.append(text, style=style or "")
        theme.console.print(line)
    else:
        print("".join(text for text, _ in segments))


def _die(*lines: str) -> None:
    """Print fatal-error lines to stderr and exit non-zero.

    Single canonical error-exit path, so every fatal error uses the same stream
    (stderr) and code - keeps `lab-utils <name> 2>/dev/null` and pipelines clean.
    """
    for line in lines:
        print(line, file=sys.stderr)
    sys.exit(1)


def print_section_header(title: str) -> None:
    """Banner shown before running a selected item."""
    print()
    _emit([(_RULE, theme.DUO["border"])])
    _emit([(f"  {title}", theme.PASTEL["title"])])
    _emit([(_RULE, theme.DUO["border"])])
    print()


def print_result(returncode: int) -> None:
    """Result banner after running an item."""
    print()
    _emit([(_RULE, theme.DUO["border"])])
    if returncode == 0:
        _emit([("  Completed successfully.", theme.PASTEL["ok"])])
    else:
        # warn (orange), not err (rose): a routine non-zero exit is not a crash
        _emit([(f"  Exited with code: {returncode}", theme.PASTEL["warn"])])
    _emit([(_RULE, theme.DUO["border"])])


def print_cancelled() -> None:
    """Banner shown when the user interrupts a running item."""
    print()
    print()
    _emit([(_RULE, theme.DUO["border"])])
    _emit([("  User cancelled action.", theme.PASTEL["warn"])])
    _emit([(_RULE, theme.DUO["border"])])


def show_help() -> None:
    print("Usage: lab-utils [OPTIONS] [SCRIPT_NAME]")
    print("")
    print("Lab utilities runner - execute platform utilities and scripts")
    print("")
    print("Options:")
    print("  --help, -h         Show this help message")
    print("  --list, -l         List available scripts with descriptions")
    print("  --json             List scripts in JSON format (machine-readable)")
    print("  --create-local     Create local scripts directory with demo script")
    print("")
    print("Arguments:")
    print("  SCRIPT_NAME        Execute the specified script directly")
    print("                     Use parent/child format for nested scripts")
    print("")
    print("When called without arguments, shows an interactive menu.")
    print("")
    print("Script locations:")
    print(f"  Global: {config.global_scripts_dir()}")
    print(f"  Local:  {config.local_scripts_dir()}")
    print("")
    print("Examples:")
    print("  lab-utils                              # Show interactive menu")
    print("  lab-utils --list                       # List all available scripts")
    print("  lab-utils --json                       # List scripts as JSON")
    print("  lab-utils --create-local               # Scaffold local scripts")
    print("  lab-utils test-cuda                    # Run top-level script")
    print("  lab-utils git-utils/git-pull-repos     # Run nested script directly")


def _print_tree(scripts: list, base_dir: Path, label: str) -> None:
    """Render a script list as a Duoptimum-coloured tree."""
    if not scripts:
        return

    desc = theme.PASTEL["desc"]
    _emit([(label, theme.PASTEL["title"]), (f" ({base_dir})", desc)])
    _emit([("│", desc)])

    i = 0
    while i < len(scripts):
        script = scripts[i]
        name = script["name"]
        remaining_top = sum(1 for s in scripts[i + 1:] if s["level"] == "top")

        if script["level"] == "top":
            children = []
            j = i + 1
            while j < len(scripts) and scripts[j]["level"] == "child":
                if scripts[j]["name"].startswith(name + "/"):
                    children.append(scripts[j])
                j += 1

            is_last_top = (remaining_top == 0 and len(children) == 0)
            connector = "└──" if is_last_top else "├──"

            if script["path"] is None:
                _emit([(connector, desc), (" ", None),
                       (f"{name}/", theme.PASTEL["submenu"]),
                       (f" {script['description']}", desc)])
            else:
                _emit([(connector, desc), (" ", None),
                       (f"{name:<22}", theme.PASTEL["name"]),
                       (f" {script['description']}", desc)])

            for k, child in enumerate(children):
                is_last_child = (k == len(children) - 1)
                prefix = "│   " if remaining_top > 0 else "    "
                child_connector = "└──" if is_last_child else "├──"
                child_name = child["name"].split("/")[-1]
                _emit([(prefix, desc), (child_connector, desc), (" ", None),
                       (f"{child_name:<18}", theme.PASTEL["name"]),
                       (f" {child['description']}", desc)])

            i = j
        else:
            i += 1

    print("")


def list_scripts() -> None:
    """List all available scripts with descriptions in tree format."""
    global_scripts, local_scripts = get_all_scripts()

    if global_scripts:
        _print_tree(global_scripts, config.global_scripts_dir(), "Global scripts")

    if local_scripts:
        _print_tree(local_scripts, config.local_scripts_dir(), "Local scripts")
    elif not config.local_scripts_dir().exists():
        _emit([("No local scripts directory. Run --create-local to create one.",
                theme.PASTEL["desc"])])
        print("")


def list_scripts_json() -> None:
    """List all scripts as JSON (machine-readable, never coloured)."""
    global_scripts, local_scripts = get_all_scripts()

    def serialise(scripts):
        return [{
            "name": s["name"],
            "description": s["description"],
            "level": s["level"],
            "path": str(s["path"]) if s["path"] else None,
        } for s in scripts]

    output = {
        "global": {"path": str(config.global_scripts_dir()), "scripts": serialise(global_scripts)},
        "local": {"path": str(config.local_scripts_dir()), "scripts": serialise(local_scripts)},
    }
    print(json.dumps(output, indent=2))


_DEMO_SCRIPT = '''#!/bin/bash
## My custom script - template for local utilities

# Colors for output
GREEN='\\033[0;32m'
BLUE='\\033[0;34m'
NC='\\033[0m' # No Color

echo -e "${GREEN}Hello from your local script!${NC}"
echo ""
echo -e "${BLUE}This is a template script in your local lab-utils directory.${NC}"
echo "Edit this file or create new .sh scripts in:"
echo "  ${HOME}/.local/lab-utils.d/"
echo ""
echo "Tips:"
echo "  - Add '## Description' as the second line for --list display"
echo "  - Make scripts executable: chmod +x script.sh"
echo "  - Create parent.d/ subdirectories for nested scripts"
echo ""
echo "Arguments received: $@"
'''


def create_local_scripts() -> None:
    """Create the local scripts directory with a demo script."""
    local_dir = config.local_scripts_dir()
    if local_dir.exists():
        _emit([("Local scripts directory already exists: ", theme.PASTEL["title"]),
               (str(local_dir), theme.PASTEL["name"])])
        print("")
        print("Use 'lab-utils --list' to see available scripts.")
        return

    _emit([("Creating local scripts directory...", theme.PASTEL["title"])])
    local_dir.mkdir(parents=True, exist_ok=True)

    demo_script = local_dir / "my-script.sh"
    demo_script.write_text(_DEMO_SCRIPT)
    demo_script.chmod(0o755)

    _emit([("Created local scripts directory: ", theme.PASTEL["ok"]), (str(local_dir), theme.PASTEL["name"])])
    _emit([("Created demo script: ", theme.PASTEL["ok"]), (str(demo_script), theme.PASTEL["name"])])
    print("")
    print("Next steps:")
    print(f"  1. Edit {demo_script} for your needs")
    print(f"  2. Create additional .sh scripts in {local_dir}")
    print("  3. Run 'lab-utils --list' to see your scripts")


def execute_script(name: str, args: list = None) -> None:
    """Execute a script by name with optional arguments, then exit with its code."""
    script_path = resolve_script_path(name)
    if script_path is None:
        _die(f"Error: Script '{name}' not found",
             "",
             "Use 'lab-utils --list' to see available scripts")

    print(f"Executing: {script_path}")
    result = subprocess.run([str(script_path)] + (args or []))
    sys.exit(result.returncode)


def main() -> None:
    """Entry point for the lab-utils console script."""
    args = sys.argv[1:]

    if not args:
        try:
            from .tui import run_interactive_menu
        except ImportError:
            _die("Error: Textual not installed. Install with: pip install textual")
        run_interactive_menu()
        return

    if args[0] in ("--help", "-h"):
        show_help()
    elif args[0] in ("--list", "-l"):
        list_scripts()
    elif args[0] == "--json":
        list_scripts_json()
    elif args[0] == "--create-local":
        create_local_scripts()
    elif args[0].startswith("-"):
        _die(f"Unknown option: {args[0]}", "Use --help for usage information")
    else:
        execute_script(args[0], args[1:])


if __name__ == "__main__":
    main()
