#!/bin/bash
# Wrapper to launch btop sized correctly inside the ttyd web terminal.
#
# ttyd forks this command at the pty default (80x24) the moment the browser
# connects, before xterm.js has reported the real window size. btop reads its
# size at startup and on SIGWINCH, but the client's initial resize can land
# while btop is still starting and be missed - leaving btop stuck at 80x24
# until the user manually resizes the JupyterLab panel (which fires a fresh
# SIGWINCH). Polling stty size doesn't help: it passes at the 80x24 default
# before the real resize arrives.
#
# Fix: re-send SIGWINCH a few times just after launch so btop re-reads the
# (by-then correct) size on its own, no manual resize needed. `$$` stays the
# wrapper PID across `exec` - it becomes btop's PID - so the backgrounded
# subshell signals btop directly.

( for _ in 1 2 3 4 5; do sleep 0.4; kill -WINCH "$$" 2>/dev/null; done ) &

exec btop --utf-force

# EOF
