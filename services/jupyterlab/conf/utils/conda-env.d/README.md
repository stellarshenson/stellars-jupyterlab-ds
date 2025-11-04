# System Conda Environment Definitions

This directory contains conda environment YAML files that are available system-wide for installation through the Lab Utils menu.

## Usage

Environment files placed in this directory will automatically appear in the "Install Conda Environment" menu accessible via Lab Utils.

## Environment File Format

Each `.yml` file should follow standard conda environment format:

```yaml
## Description of the environment (shown in menu)
name: environment_name
channels:
  - conda-forge
dependencies:
  - package1
  - package2
```

**Important**: Add a description comment line starting with `##` at the top of the file - this will be displayed in the installation menu.

## Installation

When selected from the menu, environments are:
- Created if they don't exist: `conda env create -f <file>`
- Updated if they already exist: `conda env update -n <name> -f <file>`

## User Environments

Users can also add their own environment files in `~/.local/conda-env.d/` which will appear alongside system environments in the menu.
