#!/bin/bash
# ----------------------------------------------------------------------------------------
# Persist user conda environments across container recreation
#
# /opt/conda/envs lives in the container's writable layer and is FIRST in conda's
# default envs_dirs, so `conda create -n foo` (and the lab-utils extra environments)
# land there and are silently lost on every image update. Prepending ~/.conda/envs
# (home volume) makes new environments persistent; the package cache moves to
# ~/.cache/conda/pkgs (cache volume) so downloads survive updates too. Image-baked
# envs under /opt/conda/envs stay discoverable - the default entry remains in the list.
#
# Idempotent, and deliberately hands-off when the user already manages envs_dirs in
# their own ~/.condarc.
# ----------------------------------------------------------------------------------------

mkdir -p "${HOME}/.conda/envs" "${HOME}/.cache/conda/pkgs"

# anchored: a commented-out "# envs_dirs:" line means the user does NOT have a
# working config and must still get one
if ! grep -qs '^envs_dirs' "${HOME}/.condarc"; then
    log_info "Making user conda envs persistent (envs -> ~/.conda/envs, pkg cache -> ~/.cache/conda/pkgs)"
    # write the keys directly - `conda config` would also copy the system
    # channel/mirror config into the user file, freezing the image's mirrors
    # as of FIRST BOOT into vol_home forever (user condarc wins over the
    # image's /opt/conda/.condarc, so a later mirror change would never land).
    # /opt/conda entries keep the image-baked envs and package cache reachable
    [ -f "${HOME}/.condarc" ] && [ -n "$(tail -c1 "${HOME}/.condarc")" ] && echo >> "${HOME}/.condarc"
    cat >> "${HOME}/.condarc" <<-EOF
	envs_dirs:
	  - ${HOME}/.conda/envs
	  - /opt/conda/envs
	pkgs_dirs:
	  - ${HOME}/.cache/conda/pkgs
	  - /opt/conda/pkgs
	EOF
fi

# EOF
