- `conda-entry.sh` - system entry point (i.e. for launching commands), runs commands in the conda environment
- `conda-run.sh` - wrapper to allow running commands via conda (in the selected environment)
- `mkcert.sh` - script to generate SSL certificates
- `mkchksum.sh` - script to generate files checksums
- `render-info.py` - script to render system information in the docker console
- `start-platform.d` - startup scripts launched by `start-platform.sh` in the alphabetical order
- `start-platform.sh` - command executed by docker upon system start, launches startup scripts and starts jupyterlab
- `welcome-message.sh` - produces welcome message once a day

