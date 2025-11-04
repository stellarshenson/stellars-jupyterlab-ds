# Conda Environment Definitions

This directory contains conda environment definitions that are available for installation through the Lab Utils menu.

- **System-wide**: `/opt/utils/conda-env.d/` (this directory)
- **User-specific**: `~/.local/conda-env.d/` (your personal environments)

## Usage

Environment definitions placed in either directory will automatically appear in the "Install Conda Environment" menu accessible via Lab Utils. User environments are labeled as "(user)" to distinguish them from system environments.

## Two Ways to Define Environments

### 1. YAML Environment Files (.yml)

The simplest approach - drop a conda environment YAML file and it will be automatically discovered.

**Format:**
```yaml
## Description of the environment (shown in menu)
name: my_environment
channels:
  - conda-forge
  - defaults
dependencies:
  - python=3.12
  - pip # package manager
  - ipykernel # for Jupyter kernel support
  - pip:
    - numpy
    - pandas
```

**Important**: Add a description comment starting with `##` at the top - this will be shown in the installation menu.

**Example - Data Science Environment:**
```yaml
## Data science environment with pandas, numpy, and visualization tools
name: datascience
channels:
  - conda-forge
dependencies:
  - python=3.12
  - pip
  - ipykernel
  - pip:
    - numpy
    - pandas
    - matplotlib
    - seaborn
    - scikit-learn
    - jupyter
```

**Example - NLP Environment:**
```yaml
## Natural language processing with transformers and spacy
name: nlp
channels:
  - conda-forge
dependencies:
  - python=3.12
  - pip
  - ipykernel
  - pip:
    - transformers
    - spacy
    - nltk
    - sentence-transformers
```

### 2. Shell Script (.sh)

For complex installations requiring custom logic or multiple steps.

**Format:**
```bash
#!/bin/bash
## Description shown in menu

set -e

ENV_NAME="my_environment"
CONDA_CMD=/opt/conda/bin/conda

echo "Creating conda environment: ${ENV_NAME}"

# Your custom installation logic here
${CONDA_CMD} create --name ${ENV_NAME} -y
${CONDA_CMD} env update -v --name ${ENV_NAME} --file=/path/to/environment.yml
${CONDA_CMD} clean -a -y

# Success announcement
clear
echo -e "\033[32mConda Environment Installation Successful\033[0m"
echo ""
echo -e "Environment: \033[36m$ENV_NAME\033[0m"
echo ""
echo -e "Typical Usage:"
echo -e "1. Activate the environment: '\033[36mconda activate $ENV_NAME\033[0m'"
echo -e "2. The environment is available as a Jupyter kernel"
echo ""

# EOF
```

**Example - Multi-stage Installation:**
```bash
#!/bin/bash
## Custom ML environment with specific CUDA packages

set -e

ENV_NAME="custom_ml"
CONDA_CMD=/opt/conda/bin/conda

echo "Creating conda environment: ${ENV_NAME}"

# Stage 1: Create base environment
${CONDA_CMD} create --name ${ENV_NAME} python=3.12 -y

# Stage 2: Install conda packages
${CONDA_CMD} install -n ${ENV_NAME} -y numpy scipy ipykernel

# Stage 3: Install pip packages with specific versions
${CONDA_CMD} run -n ${ENV_NAME} pip install torch==2.0.0+cu118 --index-url https://download.pytorch.org/whl/cu118

# Stage 4: Custom post-installation
${CONDA_CMD} run -n ${ENV_NAME} python -m ipykernel install --user --name=${ENV_NAME}

${CONDA_CMD} clean -a -y

clear
echo -e "\033[32mConda Environment Installation Successful\033[0m"
echo ""
echo -e "Environment: \033[36m$ENV_NAME\033[0m"
echo ""
echo -e "Typical Usage:"
echo -e "1. Activate the environment: '\033[36mconda activate $ENV_NAME\033[0m'"
echo -e "2. The environment is available as a Jupyter kernel"
echo ""

# EOF
```

**Important for scripts**: Make them executable with `chmod +x script.sh`

## When to Use Which Approach

**Use YAML files (.yml) when:**
- Simple package installation
- Standard conda/pip packages
- No custom post-installation steps
- Quick environment prototyping

**Use Shell scripts (.sh) when:**
- Complex multi-stage installation
- Custom logic or conditional steps
- Specific package versions from custom sources
- Post-installation configuration needed
- Cloning/modifying existing environments

## Tips

**For YAML files:**
- Use symlinks to reference environment files in your projects
- Keep environments focused and minimal
- Always include `ipykernel` for Jupyter support

**For Shell scripts:**
- Follow the script template structure above
- Include colored success announcements for consistency
- Use `set -e` to exit on errors
- Clean conda cache after installation

## Installation Behavior

When selected from the menu:
- **YAML files**: `conda env create -f <file>` (or update if exists)
- **Shell scripts**: Executes the script directly

Both methods will show a success announcement when complete.
