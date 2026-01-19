# System-wide .bashrc file for interactive bash(1) shells.
# Based on Ubuntu 24.04 default with stellars-jupyterlab-ds customizations.
#
# To enable the settings / commands in this file for login shells as well,
# this file has to be sourced in /etc/profile.

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, overwrite the one in /etc/profile)
# but only if not SUDOing and have SUDO_PS1 set; then assume smart user.
if ! [ -n "${SUDO_USER}" -a -n "${SUDO_PS1}" ]; then
  PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi

# enable color support for ls and grep
export TERM=xterm-256color
alias ls='ls --color=auto'
alias grep='grep --color=auto'

# enable bash completion in interactive shells
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# if the command-not-found package is installed, use it
if [ -x /usr/lib/command-not-found -o -x /usr/share/command-not-found/command-not-found ]; then
    function command_not_found_handle {
        # check because c-n-f could've been removed in the meantime
        if [ -x /usr/lib/command-not-found ]; then
           /usr/lib/command-not-found -- "$1"
           return $?
        elif [ -x /usr/share/command-not-found/command-not-found ]; then
           /usr/share/command-not-found/command-not-found -- "$1"
           return $?
        else
           printf "%s: command not found\n" "$1" >&2
           return 127
        fi
    }
fi

# ==============================================================================
# Stellars JupyterLab DS customizations
# ==============================================================================

# Fix CUDA loading for running nvidia-smi
ldconfig 2>/dev/null

# Include conda lib for libmamba solver (libxml2.so.16)
export LD_LIBRARY_PATH="/opt/conda/lib:${LD_LIBRARY_PATH}"

# Docker MCP gateway environment variable
export DOCKER_MCP_IN_CONTAINER=1

# Show welcome and MOTD only for top-level shells (SHLVL <= 3)
# Note: SHLVL is 3 when JupyterLab is launched via 'conda run' (adds extra shell level)
if [[ "$SHLVL" -le 3 ]]; then
    # display welcome message (shown once a day)
    if [[ -f /welcome-message.sh ]]; then
        /welcome-message.sh
    fi

    # display message of the day
    if [[ -f /etc/motd ]]; then
        cat /etc/motd
    fi

    # display gpustat if GPU support enabled
    if [[ "${ENABLE_GPU_SUPPORT}" = 1 ]] && [[ "${ENABLE_GPUSTAT}" = 1 ]]; then
        conda run --no-capture-output -n base gpustat --no-color --no-header --no-processes
        echo
    fi

    # brief delay to prevent terminal init race conditions
    sleep 0.3
fi

# EOF
