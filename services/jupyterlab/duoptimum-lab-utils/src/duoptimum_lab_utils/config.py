"""Deployment data root and the paths derived from it.

The packaged tool no longer sits beside its data, so paths resolve from a data
root instead of __file__. Default is the platform deployment location /opt/utils;
DUOPTIMUM_LAB_UTILS_HOME overrides it (used by the test suite and non-image
installs). Read on each call so an env change takes effect without reimport.
"""

import os
from pathlib import Path

DEFAULT_DATA_HOME = Path("/opt/utils")
ENV_DATA_HOME = "DUOPTIMUM_LAB_UTILS_HOME"


def data_home() -> Path:
    """Resolved (absolute) deployment data root.

    DUOPTIMUM_LAB_UTILS_HOME redirects only this Python tool. The bash completion
    and lab-utils.lib consumers (e.g. anthropic-claude-code.sh) hardcode the fixed
    /opt/utils deployment path and ignore the override; the fish completion shells
    out to `lab-utils --json`, so it inherits this resolution and does honour the
    override. In the image the env is unset, so all callers resolve to /opt/utils;
    the override is for tests and non-image installs.
    """
    override = os.environ.get(ENV_DATA_HOME)
    base = Path(os.path.expanduser(override)) if override else DEFAULT_DATA_HOME
    return base.resolve()


def menu_config_path() -> Path:
    return data_home() / "lab-utils.yml"


def global_scripts_dir() -> Path:
    return data_home() / "lab-utils.d"


def lib_dir() -> Path:
    return data_home() / "lab-utils.lib"


def local_scripts_dir() -> Path:
    return Path.home() / ".local" / "lab-utils.d"
