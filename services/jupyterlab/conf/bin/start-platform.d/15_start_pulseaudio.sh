#!/bin/bash
# ----------------------------------------------------------------------------------------
# PulseAudio Voice Source Launch Script
#
# Starts the PulseAudio userspace daemon and the `voicein` pipe-source for
# Claude Code /voice. The browser voice-capture extension writes PCM into the
# FIFO at /run/pulseaudio.fifo; PulseAudio exposes it as the default source so
# SoX `rec` (and thus /voice) can record it.
#
# Packages, /etc/pulse/client.conf and the AUDIODRIVER export are baked into the
# image (Dockerfile.jupyterlab.target.d/install-pulseaudio.sh). This boot hook
# only (re)starts the daemon and recreates the FIFO - both are runtime state on
# tmpfs, lost on every container restart.
# ----------------------------------------------------------------------------------------

echo "Starting PulseAudio voice source for Claude Code /voice"
conda run -n base jupyterlab_voice_capture_extension start -d

# EOF
