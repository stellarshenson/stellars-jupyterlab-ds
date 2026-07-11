# lab-utils.lib

Shared library scripts used by lab-utils menu and other utilities.

## Files

- `aws-profile-options` - returns AWS profiles as JSON for selector menus
- `claude/` - Claude Code default config files (settings.json, statusline-command.sh)
- `conda-env-options` - returns conda environments as JSON for selector menus
- `env-var-policy.yml` - managed env-var policy read by `duoptimum_lab_utils.envman`: `protected_names` / `protected_prefixes` (refused everywhere), `allowed_names` (prefix-guard exemptions), `selector_managed` (keys the Environment Variables applet hides because a Settings selector owns them, e.g. `JUPYTERLAB_TERMINAL_SHELL` via Default Shell). Extends the built-in strict defaults - the built-in floor is unioned with these entries, so the file can only ADD protections/exemptions/managed keys, never remove a built-in one; a missing/partial/invalid file keeps the full floor
- `get-profile-var` - prints a variable as login shells resolve it (`~/.profile`, then the store)
- `set-profile-var` - sets a variable in the central store `~/.local/environment.env`; refuses when the deployment locks the store (`JUPYTERLAB_USER_ENV_ENABLE=0`)
