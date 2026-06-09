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
# Packages, /etc/pulse/client.conf and the AUDIODRIVER export are baked into the
# image (Dockerfile.jupyterlab.target.d/install-pulseaudio.sh). This boot hook
# handles the runtime state lost on every restart (/run is tmpfs):
#   1. recreate the lab-owned /run/voice dir - the daemon runs as the lab user
#      and cannot create the FIFO in root-owned /run, so it needs a subfolder
#      it owns (module-pipe-source mkfifo()s the FIFO there, no sudo)
#   2. start the daemon + voicein source, which creates the FIFO
# ----------------------------------------------------------------------------------------

echo "Provisioning /run/voice and starting PulseAudio voice source for Claude Code /voice"
sudo install -d -m 0755 -o "$(id -un)" -g "$(id -gn)" /run/voice
conda run -n base jupyterlab_voice_capture start -d

# EOF
