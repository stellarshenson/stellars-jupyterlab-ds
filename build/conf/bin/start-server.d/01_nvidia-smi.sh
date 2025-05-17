#!/bin/bash
# ----------------------------------------------------------------------------------------
# prints nvidia-smi result (NVIDIA GPU status)
# ----------------------------------------------------------------------------------------

# show result of nvidia-smi if nvidia GPU available
# and if GPU_SUPPORT_ENABLED env set
if [[ $GPU_SUPPORT_ENABLED == 1 ]]; then
    /usr/bin/nvidia-smi
fi


# EOF

