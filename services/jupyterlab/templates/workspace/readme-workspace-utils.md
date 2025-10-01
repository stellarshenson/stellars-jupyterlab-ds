# Workspace Utils

A collection of interactive, menu-driven utilities designed to streamline workspace management in your JupyterLab environment. The main launcher provides a dialog-based interface that automatically discovers and presents all available workspace tools with their descriptions.

## Core Features

The workspace utilities framework offers:

- **Interactive Dialog Interface** - Terminal-based menu system for easy utility selection
- **Auto-discovery** - Automatically detects and lists all executable scripts in workspace-utils.d/
- **Self-documenting** - Each utility includes an embedded description displayed in the selection menu
- **Centralized Management** - Single entry point for all workspace configuration and maintenance tasks

## Available Utilities

### Environment Configuration
- **default-aws-profile.sh** - Interactive AWS profile selector that updates ~/.profile with your chosen default profile, includes current selection display and confirmation dialogs
- **default-conda-env.sh** - Conda environment selector for setting default environment in ~/.profile, shows current default and available environments

### Git Repository Management
- **git-commit-repos.sh** - Batch commit across all git repositories in workspace with color-coded status output (excludes @archive and tutorials directories)
- **git-pull-repos.sh** - Synchronized pull operation for all workspace repositories
- **git-push-repos.sh** - Batch push operation for multiple workspace repositories
- **git-pull-submodules.sh** - Recursive update for all git submodules in workspace

### Development Tools
- **install-claude-code.sh** - Automated installation and update of Claude Code Assistant via npm in base conda environment
- **new-project.sh** - Project scaffolding using cookiecutter-data-science template for standardized project structure
- **test-cuda.sh** - CUDA installation verification and GPU availability testing

## Usage

Launch the interactive menu by running:

```bash
workspace-utils.sh
```

The menu displays all available utilities with descriptions. Select a utility using arrow keys and press Enter to execute.

## Technical Details

- Scripts location: `/opt/utils/workspace-utils.d/`
- Requirements: `dialog` package for terminal UI
- Script descriptions: Extracted from `##` comment in each utility file
- Backup creation: Profile modification scripts create automatic backups before changes
