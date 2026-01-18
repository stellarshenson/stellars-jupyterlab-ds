# Release Notes: Version 3.5.38

**Release Date:** January 2026
**Docker Image:** `stellars/stellars-jupyterlab-ds:3.5.38_cuda-13.0.2_jl-4.5.1`
**Previous Version:** `3.0.30_cuda-13.0.1_jl-4.4.10`

## Overview

Version 3.5.38 is a major release representing significant platform evolution with 281 commits since version 3.0. Key highlights include JupyterLab 4.5.1, complete lab-utils rewrite with modern Textual TUI, fish shell support, Docker MCP Gateway integration, unified kernel management, and replacement of Glances with btop resources monitor.

## Platform Updates

| Component | Previous | Current |
|-----------|----------|---------|
| JupyterLab | 4.4.10 | 4.5.1 |
| CUDA | 13.0.1 | 13.0.2 |
| Python | 3.12 | 3.12 |

## Major New Features

### Docker CLI with MCP Gateway and Buildx

Integrated Docker CLI installation with pre-compiled plugins for AI-assisted Docker workflows.

- **Docker MCP Gateway:** Model Context Protocol integration for AI-assisted container operations
- **Docker Buildx:** Multi-platform image building support
- **On-demand installation:** Available via `lab-utils` > "Install Docker CLI"
- **Automatic plugin detection:** Plugins installed automatically when Docker CLI is installed
- **Environment variable:** `DOCKER_MCP_IN_CONTAINER=1` for MCP detection

### Fish Shell Support

Full fish shell integration with feature parity to bash.

- Fish shell available as alternative to bash
- Conda initialization for fish sessions
- Welcome message, MOTD, and gpustat display
- Configurable default shell via `JUPYTERLAB_TERMINAL_SHELL`
- Fish completions for lab-utils
- `LD_LIBRARY_PATH` configuration for conda libraries

### Lab-Utils Complete Rewrite

Replaced bash-based lab-utils with modern Python/Textual implementation.

**New Features:**
- Modern Textual TUI with styled interface and keyboard navigation
- YAML-driven menu configuration (`lab-utils.yml`)
- CLI mode: `--help`, `--list`, `--json`, `--create-local`
- Dynamic directory scanning for user scripts
- Selector type for inline configuration (shell, conda env, AWS profile)
- Breadcrumb navigation and icons
- Graceful CTRL-C handling

**Keyboard Navigation:**
- Arrow keys for navigation (Left=back, Right=select)
- Escape to quit, q to quit
- Enter to select

### Unified Kernel Management (nb_venv_kernels)

Integrated stellars nb_venv_kernels extension for automatic kernel discovery.

- Auto-discovers venv, uv, and conda environment kernels
- "Scan Kernels" launcher tile in JupyterLab
- Eliminates manual kernel registration
- Accessible via Kernel menu > Scan for Python Environments

### Resources Monitor (btop via ttyd)

Replaced Glances with btop served via ttyd web terminal.

- **URL:** `/rmonitor` (previously `/glances`)
- **Port:** 7681 (previously 61208)
- **Environment variable:** `ENABLE_SERVICE_RESOURCES_MONITOR`
- **Browser title:** "Resources Monitor"
- **On-demand:** Process starts only when browser connects (resource efficient)
- **UTF-8 support:** `--utf-force` flag for proper character rendering

### JupyterHub Notifications Integration

Integrated with stellars-jupyterhub-ds notification broadcast system.

- Hub-level notification delivery to all user sessions
- 5 notification types: info, success, warning, error, in-progress
- REST API endpoint for external systems
- Startup script status notifications

### AI Assistants Installation

Expanded AI assistant support via lab-utils menu.

**Available Assistants:**
- Anthropic Claude Code
- Anysphere Cursor
- Google Gemini CLI
- OpenAI Codex

### Session Culling Documentation

Added documentation and tooling for long-running jobs.

- `screen` terminal multiplexer added to apt packages
- Session Culling section in README
- Guidance for running persistent processes
- Culling timeout adjustable in JupyterLab Settings

## JupyterLab Extensions

New extensions added to enhance the editing and notebook experience:

- **Makefile syntax highlighting:** File type support for Makefiles
- **GitHub markdown alerts:** Note, tip, important, warning, caution syntax
- **Markdown TOC fix:** Table of contents and internal link navigation
- **Markdown tab scrolling fix:** Position preserved when switching tabs
- **Interactive widgets:** ipywidgets, jupyterlab_widgets, widgetsnbextension
- **Export markdown:** Full dependencies including Pango, Cairo, emoji fonts

## Shell & Terminal Improvements

### Ubuntu 24.04 bash.bashrc

Modernized bash configuration based on Ubuntu 24.04 standard.

- `checkwinsize` for automatic terminal size adjustment
- `command_not_found_handle` for package suggestions
- Standard PS1 prompt with sudo user handling
- Clear separation of standard and custom functionality

### Configurable Default Shell

- `DEFAULT_SHELL` build argument for custom default shell
- `JUPYTERLAB_TERMINAL_SHELL` environment variable
- Interactive selection via lab-utils > Set Defaults > Default Shell
- Requires JupyterLab restart to take effect

### Default Kernel Configuration

- `conda-base-py` set as default kernel for new notebooks
- Eliminates manual kernel selection for new notebooks

## Server Proxy Additions

New services accessible through JupyterLab reverse proxy:

| Service | Path | Port | Notes |
|---------|------|------|-------|
| Streamlit | /streamlit | 8501 | Must start server first |
| MkDocs | /mkdocs | 8000 | Must start server first |
| Resources Monitor | /rmonitor | 7681 | Starts on connect |

## Build & Development

### Makefile Improvements

- `BUILD_OPTS` variable for custom docker build options
- `make rebuild` target for fast iterative development
- Preserves builder stage cache when rebuilding target stage

### Project Scaffolding

- **cookiecutter-data-science:** `ccds` command with custom template URL
- **copier:** Alternative templating engine with update support
- `COOKIECUTTER_DATASCIENCE_TEMPLATE_URL` environment variable

## Bug Fixes

### CUDA GPG Key Deprecation

Migrated CUDA GPG key from legacy `/etc/apt/trusted.gpg` to modern `/etc/apt/trusted.gpg.d/cuda-keyring.gpg` format, eliminating apt deprecation warnings.

### LD_LIBRARY_PATH for libmamba Solver

Added `/opt/conda/lib` to `LD_LIBRARY_PATH` in platform.env and fish config to fix "libxml2.so.16: cannot open shared object file" error.

### Docker Bash Completion

Fixed Docker CLI bash completion installation path to use project standard `/etc/bash_completion.d/`.

### SHLVL Threshold

Adjusted shell level check from 2 to 3 to account for `conda run` wrapper adding extra shell level.

### Textual 7.0 Compatibility

Updated lab-utils to use `None` for separators instead of removed `Separator` class.

## Removed Features

### Multi-User Folder

Removed deprecated `multi-user/` folder. JupyterHub via stellars-jupyterhub-ds is now the recommended multi-user deployment method.

### Glances

Replaced with btop resources monitor. Update any automation using `/glances` endpoint to use `/rmonitor`.

## Migration Guide

### From Version 3.0.x

1. **Update compose.yml:**
   - Change `ENABLE_SERVICE_GLANCES` to `ENABLE_SERVICE_RESOURCES_MONITOR`

2. **Update bookmarks/scripts:**
   - Change `/glances` URLs to `/rmonitor`

3. **Fish shell users:**
   - Remove existing `~/.config/fish/config.fish` stellars section (will be regenerated)
   - Or manually add `LD_LIBRARY_PATH` if needed

4. **Lab-utils customizations:**
   - Local scripts in `~/.local/lab-utils.d/` continue to work
   - Menu now YAML-driven via `lab-utils.yml`

## Environment Variables

### New Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `ENABLE_SERVICE_RESOURCES_MONITOR` | Enable btop monitor | `1` |
| `JUPYTERLAB_TERMINAL_SHELL` | Default terminal shell | `/bin/bash` |
| `DOCKER_MCP_IN_CONTAINER` | MCP Gateway detection | `1` |
| `COOKIECUTTER_DATASCIENCE_TEMPLATE_URL` | Project template URL | stellars fork |
| `UV_LINK_MODE` | uv package manager mode | `copy` |

### Deprecated Variables

| Variable | Replacement |
|----------|-------------|
| `ENABLE_SERVICE_GLANCES` | `ENABLE_SERVICE_RESOURCES_MONITOR` |

## Package Changes

### Added to apt-packages.yml

- `screen` - terminal multiplexer for persistent sessions
- `fish` - modern extended shell
- `btop` - resources monitor
- `ttyd` - web terminal server
- `libpangoft2-1.0-0`, `libpango-1.0-0`, `libcairo2` - markdown export support
- `fonts-noto-color-emoji` - emoji support

### Added to conda environment

- `ipywidgets`, `jupyterlab_widgets`, `widgetsnbextension` - interactive widgets
- `textual` - TUI framework for lab-utils
- `copier` - project templating
- `cookiecutter-data-science` - project scaffolding

## Links

- **GitHub Repository:** https://github.com/stellarshenson/stellars-jupyterlab-ds
- **Docker Hub:** https://hub.docker.com/r/stellars/stellars-jupyterlab-ds
- **JupyterHub Integration:** https://github.com/stellarshenson/stellars-jupyterhub-ds
- **Kernel Management:** https://github.com/stellarshenson/nb_venv_kernels
