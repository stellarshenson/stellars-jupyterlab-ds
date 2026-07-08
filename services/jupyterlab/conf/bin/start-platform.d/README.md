this directory contains startup scripts run
during the startup of the platform.

`*.sh` scripts are executed alphabetically

`99_jupyterlab_config.sh` should stay the last script to run, to prevent users from overwriting the configuration file for the platform

`05_lock_user_env.sh` must keep a lower ordinal than `06_disable_sudo.sh` - both its branches need sudo, which 06 revokes for good when `JUPYTERLAB_SUDO_ENABLE=0`
