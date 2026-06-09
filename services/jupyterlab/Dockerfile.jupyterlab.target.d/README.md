# Target Installer Scripts

Run in the `target` stage to install system components. Not shipped in the image.

- `install-pulseaudio.sh` - installs the PulseAudio + SoX voice stack (via the bundle's `jupyterlab_voice_capture_extension install`) and registers `AUDIODRIVER=pulseaudio` in `/etc/default/platform.env`, for Claude Code `/voice`. Daemon starts at boot from `conf/bin/start-platform.d/15_start_pulseaudio.sh`
