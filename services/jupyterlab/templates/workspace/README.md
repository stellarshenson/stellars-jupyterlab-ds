# Workspace

This is your JupyterLab workspace directory. Create your projects here and they will persist across container restarts.

## Getting Started

- **New Project** - Run `lab-utils` and select "New Project" to scaffold a data science project
- **Terminal** - Open File > New > Terminal for command-line access
- **Welcome Page** - Click the stellars logo in the launcher for environment info and links

## Documentation

Reference guides are available in the `docs/` folder:

- **[lab-utils.md](docs/lab-utils.md)** - Interactive utility framework for workspace management
- **[nbdime.md](docs/nbdime.md)** - Notebook diffing and merging with git
- **[conda.pdf](docs/conda.pdf)** - Conda package manager cheat sheet

## Quick Commands

```bash
lab-utils              # Interactive utilities menu
lab-utils --list       # List available scripts
new-project.sh         # Create new data science project
test-cuda.sh           # Verify GPU support
```

## Customization

- **Local scripts** - Add to `~/.local/lab-utils.d/` (run `lab-utils --create-local`)
- **Startup scripts** - Add to `~/.local/start-platform.d/` for auto-execution
- **Extra environments** - Add conda YAML files to `~/.local/extra-env.d/`
