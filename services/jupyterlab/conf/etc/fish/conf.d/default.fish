# Stellars JupyterLab DS - system-wide fish configuration
# Drives conda init, greeting, environment and the login banner for all users.
# fish_prompt is autoloaded from /etc/fish/functions/fish_prompt.fish.
# Runs after 50-source-profile.fish (which bridges ~/.profile via bass).

# Conda initialization (system-wide; replaces per-user `conda init fish`)
if test -f /opt/conda/bin/conda
    eval /opt/conda/bin/conda "shell.fish" "hook" $argv | source
else if test -f /opt/conda/etc/fish/conf.d/conda.fish
    source /opt/conda/etc/fish/conf.d/conda.fish
else
    set -gx PATH /opt/conda/bin $PATH
end

# Load stellars prompt (also autoloaded from /etc/fish/functions; explicit for safety)
source /etc/fish/functions/fish_prompt.fish

# Disable default fish greeting
function fish_greeting
    # Empty function disables the default greeting
end

# Docker MCP gateway environment variable
set -gx DOCKER_MCP_IN_CONTAINER 1

# Fix CUDA loading for running nvidia-smi
ldconfig 2>/dev/null

# Show welcome and MOTD only for top-level shells (SHLVL <= 3)
# Note: SHLVL is 3 when JupyterLab is launched via 'conda run' (adds extra shell level)
if test "$SHLVL" -le 3
    # Display welcome message (shown once a day)
    if test -f /welcome-message.sh
        /welcome-message.sh
    end

    # Display message of the day
    if test -f /etc/motd
        cat /etc/motd
    end

    # Display gpustat if GPU support enabled
    if test "$ENABLE_GPU_SUPPORT" = 1; and test "$ENABLE_GPUSTAT" = 1
        # Narrow gpustat to the assigned GPUs when a specific subset is granted.
        # NVIDIA_VISIBLE_DEVICES is 'all' for a full grant or a host-index list
        # (e.g. '0,2') for a subset; pass that subset to gpustat --id.
        set -l gpustat_id
        if test -n "$NVIDIA_VISIBLE_DEVICES"; and test "$NVIDIA_VISIBLE_DEVICES" != all
            set gpustat_id --id "$NVIDIA_VISIBLE_DEVICES"
        end
        env LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/conda/lib conda run --no-capture-output -n base gpustat $gpustat_id --no-color --no-header --no-processes
        echo
    end

    # Brief delay to prevent terminal init race conditions
    sleep 0.3
end
