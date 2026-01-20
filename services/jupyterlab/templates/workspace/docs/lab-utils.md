# Lab Utils

Interactive utility framework for managing your JupyterLab environment. Lab Utils provides a modern terminal-based interface built with Python's Textual TUI framework, offering menu-driven access to workspace configuration, environment management, and development tools.

## Features

- **Textual TUI Interface** - Modern styled terminal menu with keyboard navigation
- **YAML-Driven Configuration** - Menu structure defined in `/opt/utils/lab-utils.yml`
- **CLI Support** - Direct script execution via `lab-utils <script-name>`
- **Selectors** - Inline configuration dialogs with current value display
- **Local Scripts** - User-customizable scripts in `~/.local/lab-utils.d/`
- **Tab Completion** - Bash and Fish shell autocompletion

## Usage

**Interactive menu:**
```bash
lab-utils
```

**Direct script execution:**
```bash
lab-utils new-project
lab-utils test-cuda
lab-utils git-utils/git-pull-repos
```

**CLI options:**
```bash
lab-utils --help         # Show usage
lab-utils --list         # List all available scripts
lab-utils --json         # Output scripts as JSON
lab-utils --create-local # Create ~/.local/lab-utils.d/ with demo script
```

## Keyboard Navigation

| Key | Action |
|-----|--------|
| Up/Down | Navigate menu items |
| Enter or Right | Select item or enter submenu |
| Left or Backspace | Go back to parent menu |
| Escape or q | Quit |

## Customization

Add custom scripts to `~/.local/lab-utils.d/` and they appear automatically in the Local Scripts menu. Run `lab-utils --create-local` to scaffold the directory with a demo template.

Add custom conda environments as YAML files to `~/.local/extra-env.d/` for the Install Extra Environments menu.

