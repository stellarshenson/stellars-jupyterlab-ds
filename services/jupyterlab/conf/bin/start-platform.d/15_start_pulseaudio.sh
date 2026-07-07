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

# check if enabled (default on - same ENABLE_SERVICE_* convention as the other services)
if [[ ${ENABLE_SERVICE_PULSEAUDIO:-1} != 1 ]]; then
    exit 0
fi

log_info "Starting PulseAudio voice source for Claude Code /voice"
conda run -n base jupyterlab_voice_capture start -d

# EOF
