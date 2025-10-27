# Release Notes

## Version 3.0_cuda-13.0.1_jl-4.4.10 - On-Demand Environment Installation

**Release Date:** 2025-10-27
**Docker Image:** `stellars/stellars-jupyterlab-ds:3.0_cuda-13.0.1_jl-4.4.10`

### Overview

Major version 3.0 release featuring architectural change to on-demand environment installation and JupyterLab 4.4.10 upgrade. Conda environments (tensorflow, torch, r_base, rust) are no longer pre-installed, transitioning to runtime installation via workspace utilities. This significantly reduces Docker image size and build time while providing greater flexibility for environment management.

### Platform Updates

- **JupyterLab:** 4.4.10 (upgraded from 4.4.9)
- **CUDA:** 13.0.1 (maintained)
- **Python:** 3.12 (maintained)

### Breaking Changes

- **Conda environments no longer pre-installed**: Previously, `tensorflow`, `torch`, and `r_base` environments were built into the Docker image. These are now installed on-demand by the user
- **Smaller base image**: Docker image size reduced significantly as only the `base` environment is pre-installed
- **Faster builds**: Docker build time reduced by removing multiple environment cloning and package installations

### New Features

#### On-Demand Environment Installation

- Added `install-conda-env.sh` utility accessible via `workspace-utils.sh` menu
- Environments available for installation:
  - `tensorflow` - TensorFlow with CUDA support
  - `torch` - PyTorch with CUDA support
  - `r_base` - R with IRKernel for statistical computing
  - `rust` - Rust with Jupyter kernel (evcxr)

#### Installation Scripts

Located in `conf/utils/workspace-utils.d/install-conda-env.d/`:
- `tensorflow.sh` - Clones base environment and installs TensorFlow packages
- `torch.sh` - Clones base environment and installs PyTorch packages
- `r.sh` - Creates fresh R environment with IRKernel
- `rust.sh` - Creates Rust environment with evcxr Jupyter kernel

#### Rust Environment Support

- New `environment_rust.yml` configuration file
- Includes evcxr Jupyter kernel for running Rust code in notebooks
- Rust compiler and toolchain installed via conda

#### Enhanced CUDA Testing

- `test-cuda.sh` now checks environment existence before running tests
- Provides helpful installation instructions if environments not found
- Graceful handling when tensorflow or torch environments are not installed

### Migration Guide

#### For New Installations

1. Build and run the Docker container as usual
2. Only `base` environment will be available initially
3. Run `workspace-utils.sh` and select "Install Conda Environments"
4. Choose which environments to install based on your needs

#### For Existing Users

If you rebuild your container:
1. Your existing environments in the old image will not be available
2. Use `workspace-utils.sh` > "Install Conda Environments" to reinstall needed environments
3. Environment configurations remain unchanged - same packages will be installed
4. Jupyter kernels will be registered automatically during installation

### Benefits

- **Reduced image size**: Smaller Docker images mean faster downloads and less storage usage
- **Faster builds**: Removing environment installations from Dockerfile significantly reduces build time
- **Flexibility**: Install only the environments you need
- **Easier maintenance**: Environment definitions remain in separate YAML files for easy updates
- **Resource efficiency**: Avoid installing unused frameworks

### Technical Details

#### Dockerfile Changes

- Commented out environment cloning and installation steps (lines 369-400)
- Commented out environment cleanup steps (lines 449-452)
- Added `environment_rust.yml` to copied configuration files
- Environment YAML files still copied to container root for runtime installation

#### Environment Files

All environment YAML files remain in `/` within the container:
- `/environment_tensorflow.yml`
- `/environment_torch.yml`
- `/environment_r.yml`
- `/environment_rust.yml` (new)

#### User Documentation Updates

- Updated `welcome-template.html` to reflect new installation workflow
- Updated `welcome-message.txt` to mention "ai assistants and extra environments"
- Clear instructions provided for environment installation via workspace-utils

### Testing

- Verified environment installation scripts work correctly
- Confirmed CUDA testing gracefully handles missing environments
- Validated Jupyter kernel registration after environment installation

---

## Version 2.55_cuda-13.0.1_jl-4.4.9

**Release Date:** 2025-10-05
**Docker Image:** `stellars/stellars-jupyterlab-ds:2.55_cuda-13.0.1_jl-4.4.9`

### Overview

Major release featuring platform upgrades, AI-assisted development tools, enhanced workspace utilities, and improved user experience.

### Platform Updates

- **CUDA:** 13.0.1 (upgraded from 12.9.1)
- **JupyterLab:** 4.4.9 (upgraded from 4.4.6)
- **Python:** 3.12
- **TensorFlow:** 2.18+ with GPU support
- **PyTorch:** 2.4+ with GPU support
- **Docker Image:** Optimized size and performance
- **System:** Added libgl1 for computer vision tasks, improved CUDA integration, enhanced security

### New Features

#### AI-Assisted Development
- Claude Code installer with enhanced UX
- OpenAI Codex integration
- GitHub Copilot via notebook-intelligence plugin

#### JupyterLab Extensions
- Jupytext - version control notebooks as .py files
- Archive management - zip/unzip support
- Enhanced code formatting with Black
- Real-time resource monitoring (CPU, memory, GPU)
- Cell execution time tracking
- Favorites sidebar

#### Workspace Utilities
- Reengineered dialog-based interface
- Default conda environment selector
- AWS profile switcher with enhanced management
- Automated git operations (pull, commit, push for repos and submodules)
- Cookiecutter project templates
- CUDA testing utility
- Code assistant installer - unified menu for Claude Code, Cursor, and OpenAI Codex

#### Themes
- Sublime theme - IntelliJ-inspired with fixed scrollbar rendering
- Darcula theme - gray IntelliJ Darcula variant

### Configuration Improvements

- Pre-configured JupyterLab settings in `/opt/conda/share/jupyter/lab/settings/overrides.json`
- Default environment set to 'base'
- Enhanced conda environment management
- MLFlow available across all environments
- Optional kernel startup scripts

### Conda Environments

- **Base:** Python 3.12, data science stack, JupyterLab extensions, monitoring tools
- **TensorFlow:** TensorFlow 2.18+ with CUDA GPU, TensorBoard
- **PyTorch:** PyTorch 2.4+ with GPU, YOLO-optimized
- **R:** R language kernel

### Documentation & UX

- Comprehensive README updates
- Detailed package and build documentation
- Enhanced welcome page with utility links
- Workspace utilities guide
- AWS CLI autocomplete documentation

### Bug Fixes & Optimizations

- Fixed script runner, bash completion, CUDNN_PATH configuration
- Reduced image size with optimized builds
- Removed unnecessary extensions and scripts
- Improved workspace initialization
- Cache purging for cleaner builds

### Installation

**Pull latest image:**
```bash
docker pull stellars/stellars-jupyterlab-ds:2.55_cuda-13.0.1_jl-4.4.9
```

**Using Make:**
```bash
make pull && make start
```

**Using Docker Compose:**
```bash
# Without GPU
docker compose pull && docker compose up

# With GPU support
docker compose -f compose.yml -f compose-gpu.yml up
```

### Access URLs

- **JupyterLab:** https://localhost/stellars-jupyterlab-ds/jupyterlab
- **MLFlow:** https://localhost/stellars-jupyterlab-ds/mlflow
- **TensorBoard:** https://localhost/stellars-jupyterlab-ds/tensorboard
- **Glances:** https://localhost/stellars-jupyterlab-ds/glances
- **Traefik Dashboard:** http://localhost:8080/dashboard

### Upgrade Notes

1. Pull latest image
2. Review new workspace utilities via `workspace-utils.sh`
3. Check configuration in `/opt/conda/share/jupyter/lab/settings/overrides.json`
4. Default environment is 'base' - update `CONDA_DEFAULT_ENV` if needed
5. Explore AI tools (Claude Code, OpenAI Codex) via workspace utilities

### Resources

- **Documentation:** [README.md](./README.md)
- **Docker Hub:** [stellars/stellars-jupyterlab-ds](https://hub.docker.com/repository/docker/stellars/stellars-jupyterlab-ds/general)
- **Author:** Konrad Jelen (Stellars Henson) - konrad.jelen+github@gmail.com
- **LinkedIn:** [Konrad Jelen](https://www.linkedin.com/in/konradjelen/)

---

## Previous Releases

**Version History:**
- **2.55** - Current release with theme fixes and AI tools
- **2.54** - Package optimizations
- **2.52** - OpenAI Codex integration
- **2.48** - Massive documentation update
- **2.42** - JupyterLab configuration improvements
- **2.40** - Preconfigured user settings
- **2.36-2.32** - Documentation and build optimizations
- **2.30** - JupyterLab 4.4.9 upgrade
- **2.28** - CUDA 13.0.1 upgrade
- **2.25-2.22** - Initial 2.x series releases

For complete history: `git tag --sort=-version:refname`
