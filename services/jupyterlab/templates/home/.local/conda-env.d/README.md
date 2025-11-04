# User Conda Environment Definitions

This directory (`~/.local/conda-env.d/`) is for your personal conda environment YAML files.

## Usage

Place your conda environment `.yml` files here and they will automatically appear in the "Install Conda Environment" menu accessible via Lab Utils, labeled as "(user)" to distinguish them from system environments.

## Environment File Format

```yaml
## Description of your environment (shown in menu)
name: my_environment
channels:
  - conda-forge
  - defaults
dependencies:
  - python=3.11
  - numpy
  - pandas
```

**Tip**: Add a description comment starting with `##` at the top - this will be shown in the installation menu.

## Examples

You can:
- Drop custom environment files directly here
- Create symlinks to environment files in your projects
- Share environments across projects

## Installation

Environments from this directory are installed the same way as system environments:
- Created if new: `conda env create -f <file>`
- Updated if existing: `conda env update -n <name> -f <file>`

## System Environments

System-wide environment definitions are available in `/opt/utils/conda-env.d/`
