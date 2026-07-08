#!/bin/bash
# ----------------------------------------------------------------------------------------
# PulseAudio Voice Source Launch Script
#
# Starts the PulseAudio userspace daemon and the `voicein` pipe-source for
# Claude Code /voice. The browser voice-capture extension writes PCM into the
# FIFO at /run/voice/pulseaudio.fifo; module-pipe-source creates that FIFO and
# PulseAudio exposes it as the default source so SoX `rec` (and thus /voice)
# can record it.
#
# Packages, /etc/pulse/client.conf, the AUDIODRIVER export and the lab-owned
# /run/voice dir are all baked into the image
# (Dockerfile.jupyterlab.target.d/install-pulseaudio.sh + chown). This boot
# hook only starts the daemon + voicein source, which creates the FIFO -
# no sudo needed anywhere.
# ----------------------------------------------------------------------------------------

# check if enabled (same ENABLE_SERVICE_* convention as the other services - the
# image bakes the default, no in-script fallback needed)
if [[ ${ENABLE_SERVICE_PULSEAUDIO} != 1 ]]; then
    exit 0
fi

log_info "Starting PulseAudio voice source for Claude Code /voice"

# a container restart leaves the previous boot's runtime state behind (docker
# keeps /run and /tmp in the writable layer): module-pipe-source REFUSES a
# pre-existing FIFO ("Module initialization failed"), which killed voice on
# every second boot, and a stale pid file can block the daemon start outright.
# All of it is disposable per-boot state - clear it unless a daemon is actually
# alive and serving. Paths match jupyterlab_voice_capture's PULSE_RUNTIME_PATH
# and DEFAULT_SINK_PATH constants.
if ! PULSE_RUNTIME_PATH=/tmp/pulse-lab pactl info >/dev/null 2>&1; then
    rm -rf /tmp/pulse-lab
    rm -f /run/voice/pulseaudio.fifo
fi

# same launch shape as the other services: output lands in a dedicated log file
# instead of vanishing into conda run's capture
touch /var/log/pulseaudio.log 2>/dev/null || true
conda run -n base jupyterlab_voice_capture start -d >> /var/log/pulseaudio.log 2>&1

# EOF
