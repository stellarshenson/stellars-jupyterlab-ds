# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# set default conda environment
export CONDA_DEFAULT_ENV="base"
export AWS_PROFILE="default"

. "$HOME/.cargo/env"

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
