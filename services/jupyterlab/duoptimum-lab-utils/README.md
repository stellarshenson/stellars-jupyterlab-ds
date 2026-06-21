# duoptimum-lab-utils

Duoptimum-themed lab utilities menu and runner for the Stellars JupyterLab DS platform.

Provides the `lab-utils` command: a YAML-driven menu with a Duoptimum-styled Textual TUI plus a scriptable CLI for listing and running platform utilities.

## Install

```bash
pip install .
```

Installs the `lab-utils` console script. On the platform image the package is built as a wheel in the Dockerfile builder stage and installed into the conda base environment, so `lab-utils` is reachable from any active conda environment.

## Usage

```
lab-utils                 # interactive menu
lab-utils --list          # list available scripts
lab-utils --json          # machine-readable script listing
lab-utils --create-local  # scaffold ~/.local/lab-utils.d
lab-utils <name>          # run a script directly (supports parent/child)
```

## Data root

Menu config and script directories are read from a deployment data root, default `/opt/utils`. Override with `DUOPTIMUM_LAB_UTILS_HOME` (used by the test suite and non-image installs).

## Development

```bash
pip install -e .
pytest
```
