<!-- Extends global configuration -->
<!-- See ~/.claude/CLAUDE.md for complete rules -->

# Project-Specific Configuration

This file holds rules specific to `stellars-jupyterlab-ds` - the JupyterLab platform
image and its build.

## Dockerfile Conventions

**MANDATORY**: Every `RUN` instruction in any Dockerfile in this repo
(`services/jupyterlab/Dockerfile.jupyterlab` and others) MUST use the heredoc form and
open with an `echo` that states what the step does.

**Rules**:
- Use `RUN <<-EOF` (tab-strippable heredoc), never the shell one-liner `RUN cmd && cmd` form
- First body line is an `echo "..."` describing the step in plain terms
- Follow the echo with `set -e` so the step fails loud
- Body indented for readability; the closing `EOF` sits at column 0
- Build args (`${CONDA_USER}`, `${JUPYTER_GROUP}`, ...) expand normally inside the heredoc

**Example**:
```dockerfile
RUN <<-EOF
    echo "installing pulseaudio voice stack and removing the installer"
    set -e
    /opt/target-install/install-pulseaudio.sh
    chown ${CONDA_USER}:${JUPYTER_GROUP} /run/voice
    rm -rf /opt/target-install
EOF
```

**Why**: the echo line labels each build step in the image build log, so a long multi-stage
build reads as a narrated sequence rather than opaque shell; `set -e` stops the layer on the
first failure instead of masking it behind a later success.

## Platform Switch: JUPYTERLAB_USER_ENV_ENABLE

**MANDATORY**: `JUPYTERLAB_USER_ENV_ENABLE` (default `1` = on; `0` locks the user env
store) MUST be baked in BOTH places:

- `services/jupyterlab/Dockerfile.jupyterlab` - `ENV JUPYTERLAB_USER_ENV_ENABLE=1` in the
  target stage, so hub-spawned containers (which never read compose.yml) get the default
- `compose.yml` - `JUPYTERLAB_USER_ENV_ENABLE=${JUPYTERLAB_USER_ENV_ENABLE:-1}` as the
  user-facing override knob

**Why**: the switch gates the whole user-env surface (Settings menu entries, envman applet,
set-profile-var, store injection at platform start). If only compose defined it, a
DockerSpawner deployment would resolve it as unset; if only the Dockerfile defined it,
compose users would have no `.env` knob. The two defaults must stay in sync at `1`.
