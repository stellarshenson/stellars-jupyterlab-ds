#!/usr/bin/env bash
# Install the PulseAudio + SoX voice stack for Claude Code /voice.
#
# Runs in the target stage (see README.md). The installer CLI ships in the
# stellars jupyterlab bundle (jupyterlab_voice_capture_extension), so no extra
# package is added to the conda env. `install` apt-installs pulseaudio,
# pulseaudio-utils, sox and libsox-fmt-pulse, provisions the /run/voice runtime
# dir (chowned to the lab user by the Dockerfile right after this script -
# /run is plain writable-layer in docker, not tmpfs, so it persists), and
# writes the default-server line to /etc/pulse/client.conf. It does NOT start
# the daemon - that happens at boot via start-platform.d/15_start_pulseaudio.sh.
#
# Runs as root in the target stage, so the CLI's apt step needs no sudo and the
# platform.env append below writes directly.
set -euo pipefail

platform_env="/etc/default/platform.env"

echo "installing PulseAudio + SoX voice stack via jupyterlab_voice_capture"
"${CONDA_CMD:-conda}" run -n "${CONDA_DEFAULT_ENV:-base}" \
    jupyterlab_voice_capture install

# Claude's /voice runs in a separate `rec` (SoX) process that needs AUDIODRIVER.
# platform.env is sourced under `set -a` at container start, so a bare
# assignment auto-exports to every child shell, including the claude process.
if ! grep -q '^AUDIODRIVER=' "${platform_env}"; then
    echo "registering AUDIODRIVER=pulseaudio in ${platform_env}"
    {
        echo ""
        echo "# audio driver for Claude Code /voice (SoX rec -> PulseAudio)"
        echo "AUDIODRIVER=pulseaudio"
    } >> "${platform_env}"
fi

# EOF
