"""Small shared helpers with no intra-package dependencies."""

import sys
import termios


def flush_input_buffer() -> None:
    """Drop pending stdin so escape sequences do not leak into shell history."""
    try:
        if sys.stdin.isatty():
            termios.tcflush(sys.stdin.fileno(), termios.TCIFLUSH)
    except Exception:
        pass  # non-TTY or unsupported platform
