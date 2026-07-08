# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# set default conda environment - container env (compose/hub knobs) wins when provided
export CONDA_DEFAULT_ENV="${CONDA_DEFAULT_ENV:-base}"
export AWS_PROFILE="${AWS_PROFILE:-default}"

# user environment variables (lab-utils > Settings > Environment Variables) - shells read the
# central store here at login; the platform start sources the SAME file directly
# (start-platform.sh), so this block is shell-only wiring
if [ -f "$HOME/.local/environment.env" ]; then
    set -a
    . "$HOME/.local/environment.env"
    set +a
fi

# source cargo env if installed
if [ -f "$HOME/.cargo/env" ]; then
    . "$HOME/.cargo/env"
fi

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
	. "$HOME/.bashrc"
    fi
fi

# set PATH so it includes user's private bin if it exists (idempotent)
if [ -d "$HOME/bin" ] ; then
    case ":$PATH:" in *:"$HOME/bin":*) ;; *) PATH="$HOME/bin:$PATH" ;; esac
fi

# set PATH so it includes user's private bin if it exists (idempotent)
if [ -d "$HOME/.local/bin" ] ; then
    case ":$PATH:" in *:"$HOME/.local/bin":*) ;; *) PATH="$HOME/.local/bin:$PATH" ;; esac
fi

# set PATH so it includes user's cargo bin if it exists (idempotent)
if [ -d "$HOME/.cargo/bin" ] ; then
    case ":$PATH:" in *:"$HOME/.cargo/bin":*) ;; *) PATH="$HOME/.cargo/bin:$PATH" ;; esac
fi


# EOF
