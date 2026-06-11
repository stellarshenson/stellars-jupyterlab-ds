#!/bin/bash
# Wrapper to launch btop once the terminal size is established. ttyd starts this
# command immediately, before the browser client has reported its window size,
# so btop would otherwise draw at the pty default (e.g. 80x24) and not span the
# full terminal. Polling stty size until the ttyd resize lands fixes that.

# Wait for the client resize to arrive and report reasonable dimensions
while true; do
    read rows cols < <(stty size 2>/dev/null || echo "0 0")

    # Valid once at least 20x80 (same threshold as launch-lab-utils.sh)
    if [ "$rows" -ge 20 ] && [ "$cols" -ge 80 ]; then
        break
    fi

    sleep 0.2
done

# Hand the now-correctly-sized terminal to btop
exec btop --utf-force

# EOF
