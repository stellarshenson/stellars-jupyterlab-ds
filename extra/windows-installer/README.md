# Windows Installer

NSIS installer that deploys the platform on a Windows machine with Docker Desktop - the user downloads a single setup `.exe`, no repository checkout needed.

- **Requires on the target machine** - Docker Desktop or Rancher Desktop with the docker compose plugin; checked at installer startup, the installer refuses to run without it and points to both download pages
- **Installs to** - `%LOCALAPPDATA%\stellars-jupyterlab-ds` (per-user, no admin rights needed)
- **Project name** - asked during install (default `stellars-jupyterlab-ds`); becomes part of the access URL (`https://lab.<name>.localhost`) and the prefix for container and volume names; saved to `.env` as `COMPOSE_PROJECT_NAME`
- **Password** - asked during install, saved to `.env` as `JUPYTERLAB_SERVER_TOKEN`; the JupyterLab login page asks for it, it is never placed in the URL and can be changed after login
- **Ships** - `compose.yml`, `compose-gpu.yml`, `.env.default`, `start.bat`, `stop.bat`, `LICENSE`; the platform image is pulled from Docker Hub on first start (several GB)
- **Runs the platform** - "Start the platform now" checkbox on the finish page launches `start.bat` (GPU-aware, prints the access URL)
- **Shortcuts** - Start Menu folder with Start JupyterLab, Stop JupyterLab, Open JupyterLab (`https://lab.<name>.localhost`, from the chosen project name) and Uninstall, plus a JupyterLab desktop shortcut to the same access URL
- **Uninstaller** - registered in Add/Remove Programs; runs `docker compose down --remove-orphans --rmi all` (plus `--volumes` after an explicit confirmation - that deletes notebooks and data), then removes files, shortcuts and the registry entry

## Build

Requires NSIS 3 (`makensis`) - `apt install nsis` on Debian/Ubuntu, or the NSIS Windows distribution. `make build` at the repo root builds the installer automatically after the docker image; standalone:

```
./build.sh
```

Output: `dist/stellars-jupyterlab-ds-setup-<version>.exe` - version read from the root `pyproject.toml`, older installers removed from `dist/` first (`dist/` is gitignored).
