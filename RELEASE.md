# Release Notes

## Version 3.3.32_cuda-13.0.2_jl-4.5.0 - JupyterLab 4.5.0 and Infrastructure Improvements

**Release Date:** 2025-11-23
**Docker Image:** `stellars/stellars-jupyterlab-ds:3.3.32_cuda-13.0.2_jl-4.5.0`

### Overview

Version 3.3.32 upgrades JupyterLab to 4.5.0 and includes critical infrastructure fixes for Docker CLI bash completion and CUDA repository configuration. The release also expands AI assistant support with Google Gemini CLI integration.

### Platform Updates

- **JupyterLab:** 4.5.0 (upgraded from 4.4.10)
- **CUDA:** 13.0.2 (maintained)
- **Python:** 3.12 (maintained)

### New Features

#### Google Gemini CLI Integration

Added Google Gemini CLI to the AI assistant installation menu, providing access to Google's generative AI capabilities from the command line.

**Installation:**
- Available via `lab-utils` > "Install AI Assistants" > "Google Gemini CLI"
- Installs `@google/generative-ai-cli` npm package
- Provides command-line access to Gemini models

**Usage:**
- Set API key: `export GOOGLE_API_KEY='your-api-key'`
- Run: `gemini` from any project directory
- Get API key from: https://aistudio.google.com/app/apikey

**Menu Options:**
- Anthropic Claude Code
- Anysphere Cursor
- Google Gemini CLI
- OpenAI Codex

### Bug Fixes

#### Docker CLI Bash Completion Directory

**Problem:**
Docker CLI bash completion was not working when installed via the `install-docker-cli.sh` script.

**Root Cause:**
The installation script was using `/usr/share/bash-completion/completions/` (modern standard location), but the project uses `/etc/bash_completion.d/` as its established convention for all completion files.

**Solution:**
Changed the completion directory in `install-docker-cli.sh` to `/etc/bash_completion.d/` to match the project's existing pattern (AWS completion already uses this location).

**Files Changed:**
- `services/jupyterlab/conf/utils/lab-utils.d/install-docker-cli.sh` (line 127)

#### CUDA GPG Key Deprecation Warning

**Problem:**
Build process showed warning: "Key is stored in legacy trusted.gpg keyring (/etc/apt/trusted.gpg), see the DEPRECATION section in apt-key(8) for details"

**Root Cause:**
NVIDIA CUDA repository GPG key was stored in the deprecated `/etc/apt/trusted.gpg` file instead of the modern `/etc/apt/trusted.gpg.d/` directory.

**Solution:**
Added key migration step in both builder and target stages of Dockerfile:
- Copy `/etc/apt/trusted.gpg` to `/etc/apt/trusted.gpg.d/cuda-keyring.gpg`
- Truncate legacy keyring file to prevent warning
- Migration happens before first apt operation in each stage

**Why This Approach:**
Initial attempt used `apt-key export` and `apt-key del` commands, but this removed the key before apt operations could use it, causing "NO_PUBKEY" errors. The copy-and-truncate approach preserves key functionality while eliminating the deprecation warning.

**Files Changed:**
- `services/jupyterlab/Dockerfile.jupyterlab` (lines 12-22, builder stage)
- `services/jupyterlab/Dockerfile.jupyterlab` (lines 112-123, target stage)

### Technical Details

#### CUDA Key Migration Implementation

**Builder Stage (lines 12-22):**
```dockerfile
RUN <<-EOF
    if [ -f /etc/apt/trusted.gpg ] && [ -s /etc/apt/trusted.gpg ]; then
        echo "Migrating CUDA GPG key from legacy keyring to trusted.gpg.d"
        cp /etc/apt/trusted.gpg /etc/apt/trusted.gpg.d/cuda-keyring.gpg
        echo "CUDA key migrated to /etc/apt/trusted.gpg.d/cuda-keyring.gpg"
        : > /etc/apt/trusted.gpg
    fi
EOF
```

**Target Stage (lines 112-123):**
Same migration logic applied to ensure both stages have proper key configuration.

**Verification:**
Build logs show "Migrating CUDA GPG key from legacy keyring to trusted.gpg.d" in both stages with no deprecation warnings during apt operations.

#### Bash Completion Configuration

**Project Convention:**
All bash completion files are installed to `/etc/bash_completion.d/` and loaded via `/etc/profile.d/bash_completion.sh` at shell startup.

**Existing Pattern:**
- AWS CLI completion: `/etc/bash_completion.d/aws`
- Docker completion (copied in Dockerfile): `/etc/bash_completion.d/docker`

**Fixed Script:**
```bash
completion_dir="/etc/bash_completion.d"
sudo cp "$temp_completion" "${completion_dir}/docker"
sudo chmod 644 "${completion_dir}/docker"
```

### Files Changed

**New Files:**
- `services/jupyterlab/conf/utils/lab-utils.d/install-ai-assistant.d/google-gemini-cli.sh`

**Modified Files:**
- `services/jupyterlab/Dockerfile.jupyterlab` - CUDA GPG key migration in builder and target stages
- `services/jupyterlab/conf/utils/lab-utils.d/install-docker-cli.sh` - Corrected bash completion directory
- `project.env` - Updated version to 3.3.32 and version comment
- `README.md` - Added current version badge and Google Gemini CLI to AI assistant list

### Testing

**Verified:**
- JupyterLab 4.5.0 builds and runs correctly
- Docker CLI bash completion installs to correct directory
- CUDA GPG key migration works in both builder and target stages
- No deprecation warnings during Docker build
- Google Gemini CLI installation script is executable and discoverable
- All AI assistant installers appear in menu

**Build Status:**
- Exit code: 0 (success)
- Image size: 7.8GB
- All components built successfully (llama-cpp-python with CUDA, Docker plugins, conda packages)

### Migration Guide

#### For Existing Users

**No action required** - this release includes bug fixes and feature additions without breaking changes.

**To leverage new features:**
1. Rebuild Docker image to get JupyterLab 4.5.0 and infrastructure fixes
2. Install Google Gemini CLI via `lab-utils` > "Install AI Assistants" if desired
3. Docker CLI bash completion will work correctly in new containers

**For Docker CLI users:**
If you previously installed Docker CLI via `install-docker-cli.sh` and bash completion wasn't working, it will work correctly after rebuilding with this version.

### Resources

- **Documentation:** [README.md](./README.md)
- **Docker Hub:** [stellars/stellars-jupyterlab-ds](https://hub.docker.com/repository/docker/stellars/stellars-jupyterlab-ds/general)
- **GitHub:** [stellarshenson/stellars-jupyterlab-ds](https://github.com/stellarshenson/stellars-jupyterlab-ds)
- **Author:** Konrad Jelen (Stellars Henson) - konrad.jelen+github@gmail.com
- **LinkedIn:** [Konrad Jelen](https://www.linkedin.com/in/konradjelen/)

---

## Version 3.2.2_cuda-13.0.2_jl-4.4.10 - JupyterHub Notification System Integration

**Release Date:** 2025-11-04
**Docker Image:** `stellars/stellars-jupyterlab-ds:3.2.2_cuda-13.0.2_jl-4.4.10`

### Overview

Version 3.2.2 integrates with the stellars-jupyterhub-ds notifications broadcast system, enabling hub-level notification delivery to all user JupyterLab sessions. This integration allows administrators and automated systems to send notifications that appear in the native JupyterLab notification center across all active user sessions.

### Platform Updates

- **JupyterLab:** 4.4.10 (maintained)
- **CUDA:** 13.0.2 (upgraded from 13.0.1)
- **Python:** 3.12 (maintained)

### New Features

#### JupyterHub Notification System Integration

**Integration Component:**
Added `jupyterlab_notifications_extension` to base environment, enabling REST API-based notification delivery from external systems.

**Key Capabilities:**
- **Hub-level broadcast** - Notifications sent from JupyterHub reach all active user sessions
- **REST API endpoint** - External systems can POST notifications with token authentication
- **5 notification types** - info, success, warning, error, in-progress with distinct visual styling
- **Configurable auto-dismiss** - Set millisecond timeout or manual dismissal
- **Command palette integration** - Manual notification sending via interactive dialog
- **Action buttons** - Optional buttons for enhanced user interaction
- **Programmatic API** - Extensions can send notifications programmatically

**Use Cases:**
- System-wide announcements to all users
- Maintenance notifications
- Job completion alerts from external systems
- Integration with CI/CD pipelines
- Custom workflow notifications

**Integration Architecture:**

The notification system integrates with stellars-jupyterhub-ds through:
1. JupyterHub sends notifications to REST API endpoint
2. Extension broadcasts to all connected JupyterLab sessions via 30-second polling
3. Notifications appear in native JupyterLab notification center
4. Users can dismiss or interact with notifications

**Extension Repository:**
[jupyterlab_notifications_extension](https://github.com/stellarshenson/jupyterlab_notifications_extension)

### Files Changed

**Modified Files:**
- `services/jupyterlab/conf/environment_base_jupyterlab.yml` - Added jupyterlab_notifications_extension to pip dependencies
- `project.env` - Updated version to 3.2.2 and version comment
- `.claude/JOURNAL.md` - Session documentation

### Migration Guide

#### For Existing Users

**No action required** - The extension is automatically installed when rebuilding the base environment.

**To leverage notification system:**
1. Rebuild Docker image to install extension
2. Configure notification tokens (if using REST API)
3. External systems can POST to `/jupyterlab_notifications/notify` endpoint
4. See extension documentation for API details

#### For JupyterHub Deployments

This integration is designed to work seamlessly with [stellars-jupyterhub-ds](https://github.com/stellarshenson/stellars-jupyterhub-ds). The hub can broadcast notifications to all user sessions for:
- System announcements
- Scheduled maintenance alerts
- Resource quota warnings
- Custom administrative notifications

### Testing

**Verified:**
- Extension installs correctly in base environment
- Notification center accessible in JupyterLab UI
- Command palette integration functional
- REST API endpoint available (when configured)

### Resources

- **Extension Documentation:** [jupyterlab_notifications_extension](https://github.com/stellarshenson/jupyterlab_notifications_extension)
- **JupyterHub Integration:** [stellars-jupyterhub-ds](https://github.com/stellarshenson/stellars-jupyterhub-ds)
- **Docker Hub:** [stellars/stellars-jupyterlab-ds](https://hub.docker.com/repository/docker/stellars/stellars-jupyterlab-ds/general)
- **GitHub:** [stellarshenson/stellars-jupyterlab-ds](https://github.com/stellarshenson/stellars-jupyterlab-ds)
- **Author:** Konrad Jelen (Stellars Henson) - konrad.jelen+github@gmail.com
- **LinkedIn:** [Konrad Jelen](https://www.linkedin.com/in/konradjelen/)

---

## Version 3.1.19_cuda-13.0.1_jl-4.4.10 - MLflow DNS Rebinding Protection Fix

**Release Date:** 2025-11-04
**Docker Image:** `stellars/stellars-jupyterlab-ds:3.1.19_cuda-13.0.1_jl-4.4.10`

### Overview

Version 3.1.19 resolves a critical issue where MLflow tracking server rejected connections from external hosts with "Invalid Host header - possible DNS rebinding attack detected" error. This fix enables MLflow to properly accept requests forwarded through JupyterHub ServerProxy while maintaining security through the containerized architecture with Traefik and ServerProxy proxy layers.

### Platform Updates

- **JupyterLab:** 4.4.10 (maintained)
- **CUDA:** 13.0.1 (maintained)
- **Python:** 3.12 (maintained)
- **MLflow:** 3.5.0+ (DNS rebinding protection support)

### Bug Fixes

#### MLflow External Access Issue

**Problem:**
MLflow 3.5.0+ introduced DNS rebinding protection that validates the Host header in incoming requests. When accessing MLflow from external hosts (outside localhost), the server rejected requests with error message: "Invalid Host header - possible DNS rebinding attack detected"

**Root Cause:**
- Traffic routing: Browser → Traefik → JupyterLab → ServerProxy → MLflow
- ServerProxy preserves the Host header (external domain) when forwarding to MLflow
- MLflow sees external domain in Host header but connection from 127.0.0.1
- Default security settings triggered DNS rebinding protection

**Solution:**
Configured two environment variables in MLflow launch script to disable DNS rebinding checks in the containerized environment:

- `MLFLOW_SERVER_ALLOWED_HOSTS='*'` - MLflow 3.5.0+ setting to allow all Host headers
- `FORWARDED_ALLOW_IPS='*'` - Gunicorn setting to trust all proxy IP addresses for forwarded headers

**Why This Is Safe:**
- MLflow runs inside Docker container, completely isolated from external network
- All external traffic must pass through: Traefik → JupyterLab → ServerProxy
- MLflow only receives connections from localhost (ServerProxy)
- Setting these to `*` is safe since MLflow is firewalled from direct external access

### Technical Details

#### Configuration Changes

Modified `services/jupyterlab/conf/bin/start-platform.d/13_start_mlflow.sh`:

**Environment Variables Added (lines 43-44):**
```bash
FORWARDED_ALLOW_IPS=${FORWARDED_ALLOW_IPS:-*}
MLFLOW_SERVER_ALLOWED_HOSTS=${MLFLOW_SERVER_ALLOWED_HOSTS:-*}
```

**Export to MLflow Process (lines 48-49):**
```bash
export FORWARDED_ALLOW_IPS='$FORWARDED_ALLOW_IPS'
export MLFLOW_SERVER_ALLOWED_HOSTS='$MLFLOW_SERVER_ALLOWED_HOSTS'
```

**Documentation Updated:**
- Added `MLFLOW_SERVER_ALLOWED_HOSTS` to environment variables list
- Added `FORWARDED_ALLOW_IPS` to environment variables list
- Clarified default values and purpose

#### Script Simplification

Removed experimental configurations from previous troubleshooting attempts:
- Cleaned up heredoc variable expansion
- Removed wildcard-to-IP conversion logic
- Simplified launch announcement
- Maintained `MLFLOW_HOST` environment variable support

### Architecture Context

**MLflow Deployment Architecture:**
```
Browser (external host)
    ↓ HTTPS
Traefik Reverse Proxy (port 443)
    ↓ HTTP (Host: external-domain.com)
JupyterLab (port 8888)
    ↓ HTTP (Host: external-domain.com preserved)
ServerProxy (JupyterHub extension)
    ↓ HTTP to localhost:5000 (Host: external-domain.com preserved)
MLflow Tracking Server (Gunicorn/Flask)
    ↓ validates Host header
    ✓ Now accepts all hosts
```

### Files Changed

**Modified Files:**
- `services/jupyterlab/conf/bin/start-platform.d/13_start_mlflow.sh` - Added environment variables for DNS rebinding protection
- `project.env` - Updated version and comment
- `.claude/JOURNAL.md` - Session documentation

### Testing

**Verified:**
- MLflow accessible from localhost - ✓
- MLflow accessible from same Docker host - ✓
- MLflow accessible from external hosts - ✓ (fixed)
- Host header validation disabled - ✓
- Gunicorn proxy trust configured - ✓
- Environment variables properly exported - ✓

**Environment Variables Can Be Overridden:**
```bash
# In compose.yml or Dockerfile
MLFLOW_SERVER_ALLOWED_HOSTS=domain1.com,domain2.com  # Specific domains
FORWARDED_ALLOW_IPS=172.0.0.0/8,10.0.0.0/8          # Specific networks
```

### Migration Guide

#### For Existing Users

**No action required** - this is a bug fix that enables previously broken functionality.

If you were working around this issue by accessing MLflow only from localhost, you can now access it from external hosts as originally intended.

#### For Security-Conscious Deployments

If you prefer stricter Host header validation:

1. Set `MLFLOW_SERVER_ALLOWED_HOSTS` to comma-separated list of allowed domains:
   ```yaml
   # In compose.yml
   environment:
     - MLFLOW_SERVER_ALLOWED_HOSTS=mlflow.example.com,localhost
   ```

2. Set `FORWARDED_ALLOW_IPS` to specific Docker network ranges:
   ```yaml
   # In compose.yml
   environment:
     - FORWARDED_ALLOW_IPS=127.0.0.1,::1,172.0.0.0/8
   ```

### Resources

- **MLflow Documentation:** [Network Security](https://mlflow.org/docs/latest/self-hosting/security/network/)
- **Gunicorn Documentation:** [Settings - forwarded-allow-ips](https://docs.gunicorn.org/en/stable/settings.html#forwarded-allow-ips)
- **Docker Hub:** [stellars/stellars-jupyterlab-ds](https://hub.docker.com/repository/docker/stellars/stellars-jupyterlab-ds/general)
- **GitHub:** [stellarshenson/stellars-jupyterlab-ds](https://github.com/stellarshenson/stellars-jupyterlab-ds)
- **Author:** Konrad Jelen (Stellars Henson) - konrad.jelen+github@gmail.com
- **LinkedIn:** [Konrad Jelen](https://www.linkedin.com/in/konradjelen/)

---

## Version 3.1.10_cuda-13.0.1_jl-4.4.10 - User-Defined Conda Environments

**Release Date:** 2025-11-04
**Docker Image:** `stellars/stellars-jupyterlab-ds:3.1.10_cuda-13.0.1_jl-4.4.10`

### Overview

Version 3.1 introduces a powerful extensible conda environment management system that allows users to define custom environments by simply dropping YAML files or shell scripts into designated directories. This release transforms environment management from a fixed set of built-in options to a flexible, user-controlled system with comprehensive documentation and examples.

### Platform Updates

- **JupyterLab:** 4.4.10 (maintained)
- **CUDA:** 13.0.1 (maintained)
- **Python:** 3.12 (maintained)

### Major Features

#### User-Defined Conda Environments

Users can now create custom conda environments by placing files in three discoverable locations:

- **`/opt/utils/lab-utils.d/install-conda-env.d/`** - Built-in environment scripts (system-managed)
- **`/opt/utils/conda-env.d/`** - System-wide environment definitions (YAML or shell scripts)
- **`~/.local/conda-env.d/`** - User-specific environment definitions (YAML or shell scripts)

**Supported formats:**
- **`.yml` files** - Simple declarative conda environment definitions
- **`.sh` scripts** - Complex multi-stage installations with custom logic

All files are automatically discovered and appear in the "Install Conda Environment" menu with user environments labeled as "(user)".

#### Pre-Defined Scraping Environment

New declarative `scraping.yml` environment includes comprehensive web scraping and browser automation tools:

**Browser Automation:**
- selenium - Web browser automation framework
- playwright - Modern browser automation (Chromium, Firefox, WebKit)
- webdriver-manager - Automatic webdriver management
- pyppeteer - Headless Chrome/Chromium automation

**Web Scraping Frameworks:**
- scrapy - Comprehensive web scraping framework
- beautifulsoup4 - HTML/XML parser
- lxml - XML and HTML parser library

**HTTP Clients:**
- httpx - Modern async HTTP client
- aiohttp - Async HTTP client/server
- cloudscraper - Bypass anti-bot protections
- requests - HTTP library for Python

**Parsing & Extraction:**
- html2text - Convert HTML to markdown
- extruct - Extract structured data from HTML
- newspaper3k - Article scraping
- trafilatura - Web scraping and text extraction

**Utilities:**
- fake-useragent - Random user agent generation
- python-dotenv - Environment variable management

#### Comprehensive Documentation

Created detailed `README.md` in conda-env.d directories with:

**YAML Examples:**
- Basic format template with pip section
- Data science environment (pandas, numpy, visualization)
- NLP environment (transformers, spacy, nltk)

**Shell Script Examples:**
- Basic template with colored announcements
- Multi-stage installation with custom CUDA packages
- Post-installation configuration examples

**Package Purpose Comments:**
All examples include inline comments explaining each package's purpose for educational clarity.

**Usage Guidelines:**
- When to use YAML vs shell scripts
- Tips for both approaches
- Installation behavior details

#### Enhanced User Experience

**Colored Success Announcements:**
- Consistent green "Conda Environment Installation Successful" message
- Bold blue environment names for high visibility
- Formatted usage instructions with cyan-colored commands
- Matches AI assistant installation style

**Lab Utils Launcher Improvements:**
- Renamed launcher icon from `wrench.svg` to `lab-utils.svg`
- Added magenta-colored tab closure notice
- Improved terminal behavior with `exec` to prevent shell prompt return
- Updated welcome-template.html with distinct code text colors (red in light/dark modes)

**Automatic Directory Setup:**
- New `05_user_directories.sh` startup script ensures `~/.local/conda-env.d/` exists
- Automatically creates symlink to README.md from system directory
- User-friendly environment discovery on first launch

### Build System Enhancements

#### Makefile Improvements

**Git Tagging Integration:**
- `make tag` now creates both git and docker tags
- Skip-if-exists logic prevents duplicate tagging
- Automatic git tag push with `make push`

**Inline Version Increment:**
- Replaced Python script with inline awk implementation
- Simplified dependency chain
- Direct .env file manipulation
- Faster execution

### Technical Details

#### Environment Discovery Algorithm

The `install-conda-env.sh` script scans all three locations for both `.yml` and `.sh` files:

1. Extracts descriptions from `##` comment lines
2. Validates shell scripts are executable
3. Presents unified menu with clear type and source indicators
4. Handles both script execution and YAML-based conda env create/update

#### Installation Behavior

**For YAML files:**
- Extracts environment name from `name:` field
- Creates if new: `conda env create -f <file>`
- Updates if existing: `conda env update -n <name> -f <file>`
- Colored success announcement with environment name

**For Shell scripts:**
- Direct execution with full control
- Script handles its own conda commands and announcements
- Supports complex multi-stage installations
- Custom post-installation configuration

### Migration Guide

#### For Existing Users

No breaking changes. This release is fully backward compatible with version 3.0.

**To leverage new features:**

1. Create `~/.local/conda-env.d/` if you want custom environments
2. Drop `.yml` files for simple environments or `.sh` scripts for complex ones
3. Make shell scripts executable: `chmod +x script.sh`
4. Access via Lab Utils > Install Conda Environments

#### Example: Creating Custom Environment

**Simple YAML approach:**
```yaml
## My custom data analysis environment
name: myanalysis
channels:
  - conda-forge
dependencies:
  - python=3.12
  - pip
  - ipykernel
  - pip:
    - pandas
    - plotly
    - statsmodels
```

Save as `~/.local/conda-env.d/myanalysis.yml` and it appears in the menu automatically.

### Benefits

- **Extensibility**: No longer limited to built-in environments
- **Flexibility**: Mix YAML and shell scripts based on complexity needs
- **Shareability**: Use symlinks to reference project environment files
- **Documentation**: Comprehensive examples for both approaches
- **Consistency**: Standardized success announcements across all installations
- **User Control**: Personal environments completely isolated from system definitions

### Files Changed

**New Files:**
- `services/jupyterlab/conf/utils/conda-env.d/README.md` - Comprehensive documentation
- `services/jupyterlab/conf/utils/conda-env.d/scraping.yml` - Web scraping environment
- `services/jupyterlab/conf/bin/start-platform.d/05_user_directories.sh` - Auto-setup script
- `services/jupyterlab/templates/home/.local/conda-env.d/README.md` - Symlink to global README

**Modified Files:**
- `services/jupyterlab/conf/utils/lab-utils.d/install-conda-env.sh` - Extended discovery
- `services/jupyterlab/conf/utils/lab-utils.d/install-conda-env.d/*.sh` - Colored announcements
- `services/jupyterlab/conf/misc/welcome-template.html` - Updated documentation
- `services/jupyterlab/conf/share/jupyter/jupyter_app_launcher/lab-utils.svg` - Renamed icon
- `Makefile` - Git tagging and inline version increment
- `.claude/JOURNAL.md` - Session documentation

### Renamed Files

- `wrench.svg` → `lab-utils.svg` (launcher icon)
- Removed `scripts/increment_version.py` (replaced with Makefile awk)

### Testing

- Verified YAML environment discovery and installation
- Confirmed shell script discovery and execution
- Validated colored announcements consistency
- Tested symlink creation on startup
- Verified README accessibility from user directory

### Resources

- **Documentation:** [README.md](./README.md)
- **Docker Hub:** [stellars/stellars-jupyterlab-ds](https://hub.docker.com/repository/docker/stellars/stellars-jupyterlab-ds/general)
- **GitHub:** [stellarshenson/stellars-jupyterlab-ds](https://github.com/stellarshenson/stellars-jupyterlab-ds)
- **Author:** Konrad Jelen (Stellars Henson) - konrad.jelen+github@gmail.com
- **LinkedIn:** [Konrad Jelen](https://www.linkedin.com/in/konradjelen/)

---

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
