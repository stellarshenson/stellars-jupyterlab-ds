#!/bin/bash
# ----------------------------------------------------------------------------------------
# prints nvidia-smi result (NVIDIA GPU status)
# ----------------------------------------------------------------------------------------

# show result of nvidia-smi if nvidia GPU available
# and if ENABLE_GPU_SUPPORT env set
if [[ ${ENABLE_GPU_SUPPORT} == 1 ]]; then
    /usr/bin/nvidia-smi
fi


# EOF

