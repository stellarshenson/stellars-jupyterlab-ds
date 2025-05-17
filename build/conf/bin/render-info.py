#!/usr/bin/env python3
import sys
import re

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
        .replace("@SERVER_TOKEN@", server_token)
    )

# ─────────────────────────────────────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────────────────────────────────────

if len(sys.argv) != 5:
    print("Usage: render_build_info.py <LAB_NAME> <BUILD_NAME> <BUILD_DATE> <SERVER_TOKEN>")
    sys.exit(1)

lab_name, build_name, build_date, server_token = sys.argv[1:]

# Raw content block
raw_info = """
Build @BUILD_NAME@ created on @BUILD_DATE@
--------------------------------------------------------------------------------
Running JupyterLab server on  \033[36mhttps://localhost/@LAB_NAME@/jupyterlab\033[0m
Connect VSCode to Jupyter on  \033[36mhttps://localhost/@LAB_NAME@/jupyterlab/lab/tree\033[0m
Running MLFlow server on      \033[36mhttps://localhost/@LAB_NAME@/mlflow\033[0m
Running Tensorboard server on \033[36mhttps://localhost/@LAB_NAME@/tensorboard\033[0m
Running Glances Web Monitor   \033[36mhttps://localhost/@LAB_NAME@/glances\033[0m
Using projects dir: \033[94m/home/lab/workspace\033[0m (mount)
Using certs (ssl) dir: \033[94m/mnt/certs\033[0m (mount)
Jupyterlab settings saved to: \033[94m/home/lab/.jupyter\033[0m
Jupyterlab server token: \033[95m@SERVER_TOKEN@\033[0m
--------------------------------------------------------------------------------
Visit: \033[36mhttps://github.com/stellarshenson/stellars-jupyterlab-ds\033[0m
""".strip().splitlines()

# Apply replacements
colored_lines = [substitute_vars(line) for line in raw_info]

# Wrap with box
banner = build_table_block(colored_lines)

# Output
print(banner)

