# Linux Installer

Self-extracting all-in-one shell installer - the user downloads a single `.sh`, no repository checkout needed. The deployment files (`compose.yml`, `compose-gpu.yml`, `start.sh`, `stop.sh`, `LICENSE`) are embedded as a gzipped tar payload; the platform image is pulled from Docker Hub on first start.

- **Requires on the target machine** - docker with the compose plugin; checked before anything is installed, the installer points to Docker Engine, Docker Desktop and Rancher Desktop when missing
- **Run as a file** - `sh stellars-jupyterlab-ds-setup-<version>.sh`; piping into sh does not work (the payload sits below the `__ARCHIVE_BELOW__` marker in `$0`)
- **Installs to** - `~/.local/share/stellars-jupyterlab-ds` by default, prompted and overridable
- **Password** - asked during install (hidden input), saved to `.env` as `JUPYTERLAB_SERVER_TOKEN`; the JupyterLab login page asks for it, it is never placed in the URL and can be changed after login
- **Displays** - the access URL (`https://localhost/stellars-jupyterlab-ds/jupyterlab`), where the password is stored, and the start/stop/uninstall paths; offers to start the platform right away via `start.sh` (GPU-aware)
- **Uninstaller** - generated `uninstall.sh` in the install directory; runs `docker compose down --remove-orphans --rmi all` (plus `--volumes` after an explicit confirmation - that deletes notebooks and data), then removes the installed files

## Build

```
./build.sh
```

Output: `dist/stellars-jupyterlab-ds-setup-<version>.sh` - version read from the root `pyproject.toml`, older installers removed from `dist/` first (`dist/` is gitignored). `make build` at the repo root builds it automatically after the docker image.
