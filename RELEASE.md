# Release Notes

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
