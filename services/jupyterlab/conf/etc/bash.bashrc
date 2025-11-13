# Copyright 2018 The TensorFlow Authors. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# ==============================================================================

# Do not print anything if this is not being used interactively
[ -z "$PS1" ] && return

# Set up attractive prompt
export TERM=xterm-256color
alias grep="grep --color=auto"
alias ls="ls --color=auto"

# Fix CUDA loading for running nvidia-smi
ldconfig 2>/dev/null

# include opt utils scripts in PATH
export PATH="/opt/utils:$PATH"

# include docker cli in PATH
export PATH="/opt/docker:$PATH"

# show motd only for SHLVL less or equal 2
if [[ "$SHLVL" -gt 2 ]]; then
    return
fi

# display welcome message
# it is displayed once a day and shows content of
# /welcome-message.txt
if [[ -f /welcome-message.sh ]]; then
    /welcome-message.sh
fi

# display message of the day
if [[ -f /etc/motd ]]; then
    cat /etc/motd
fi

# display gpustat
if [[ "${ENABLE_GPU_SUPPORT}" = 1 ]] && [[ "${ENABLE_GPUSTAT}" = 1 ]]; then
    /opt/conda/bin/gpustat --no-color --no-header --no-processes
fi

# sleep to prevent issues with motd line disappearing because if init delay
sleep 0.3

# EOF
