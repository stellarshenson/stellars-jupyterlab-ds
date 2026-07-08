# lab-utils.lib

Shared library scripts used by lab-utils menu and other utilities.

## Files

- `aws-profile-options` - returns AWS profiles as JSON for selector menus
- `claude/` - Claude Code default config files (settings.json, statusline-command.sh)
- `conda-env-options` - returns conda environments as JSON for selector menus
- `get-profile-var` - prints a variable as login shells resolve it (`~/.profile`, then the store)
- `set-profile-var` - sets a variable in the central store `~/.local/environment.env`; refuses when the deployment locks the store (`JUPYTERLAB_USER_ENV_ENABLE=0`)
