#!/usr/bin/env python3
import os
import sys
import re

system_name = os.environ.get('JUPYTERLAB_SYSTEM_NAME') or 'stellars-jupyterlab-ds'

# ─────────────────────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────────────────────

ansi_escape = re.compile(r'\x1b\[[0-9;]*m')

def visible_len(s):
    """Length of visible (non-ANSI) characters."""
    return len(ansi_escape.sub('', s))

def build_table_block(content_lines, pad=2):
    """Wrap content lines in ASCII-art box with separators."""
    # Determine box width (widest visible line + padding)
    max_len = max(visible_len(line) for line in content_lines if '---' not in line)
    width = max_len + pad * 2

    # Build table lines
    top =    "█" + "▀" * width + "█"
    bottom = "█" + "▄" * width + "█"
    separator = "█" + "─" * width + "█"

    boxed = [top]
    for line in content_lines:
        if '---' in line:
            boxed.append(separator)
        else:
            vlen = visible_len(line)
            spacing = width - vlen
            padded_line = " " * pad + line + " " * (spacing - pad)
            boxed.append("█" + padded_line + "█")
    boxed.append(bottom)
    return "\n".join(boxed)

def substitute_vars(text):
    return (
        text
        .replace("@BUILD_NAME@", f"\033[36m{build_name}\033[0m")
        .replace("@BUILD_DATE@", f"\033[36m{build_date}\033[0m")
        .replace("@LAB_NAME@", lab_name)
        .replace("@SYSTEM_NAME@", system_name)
    )

# ─────────────────────────────────────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────────────────────────────────────

if len(sys.argv) < 4:
    print("Usage: render_build_info.py <LAB_NAME> <BUILD_NAME> <BUILD_DATE>")
    sys.exit(1)

lab_name, build_name, build_date = "", "", ""
if len(sys.argv) >= 4:
    lab_name, build_name, build_date = sys.argv[1:4]


# Raw content block - the auth token itself is never rendered: this banner goes to
# the container log (docker logs), which must not hold the password
raw_info = """
Build @BUILD_NAME@ created on @BUILD_DATE@
Jupyterlab server token: \033[95mset at deployment (key JUPYTERLAB_SERVER_TOKEN in .env)\033[0m
--------------------------------------------------------------------------------
Visit: \033[36mhttps://github.com/stellarshenson/@SYSTEM_NAME@\033[0m
""".strip().splitlines()

# Apply replacements
colored_lines = [substitute_vars(line) for line in raw_info]

# Wrap with box
banner = build_table_block(colored_lines)

# Output
print(banner)

