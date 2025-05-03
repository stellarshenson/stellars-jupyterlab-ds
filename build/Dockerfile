## this container will serve as a builder for some cuda-specific
## libraries like huggingface llama_cpp
# FROM nvidia/cuda:12.6.3-cudnn-runtime-ubuntu24.04 AS builder
FROM nvidia/cuda:12.8.1-cudnn-runtime-ubuntu24.04 AS builder

# cuda toolkit version - should be the same as torch
ARG CUDA_TOOLKIT_VERSION=12.8

# Install necessary packages for building
ENV DEBIAN_FRONTEND=noninteractive 
RUN <<-EOF
    echo "installing necessary OS packages"
    apt-get update 
    apt-get install -y git build-essential wget \
	cmake python3 python3-pip python3-dev
    rm -rf /var/lib/apt/lists/*
EOF

# make sure we have conda
ENV CONDA_DEFAULT_ENV=base
ENV CONDA_HOME=/opt/conda
ENV CONDA_CMD=${CONDA_HOME}/condabin/conda
COPY --chmod=644  ./conf/environment_builder.yml /environment_builder.yml

# download and install conda
RUN <<-EOF
    echo "installing miniforge"
    wget https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh \
	-O ~/miniforge3.sh
    bash ~/miniforge3.sh -b -u -p ${CONDA_HOME}
    rm -rf ~/miniforge3.sh
EOF

## install builder env in 'base'
RUN <<-EOF
    echo "installing builder environment in base"
    ${CONDA_CMD} env update --name base --file=/environment_builder.yml
    ${CONDA_CMD} update --name base -c conda-forge -y conda
    ${CONDA_CMD} install --name base -v -y cuda-toolkit=${CUDA_TOOLKIT_VERSION}
EOF

# enable special shell for conda
COPY --chmod=755  ./conf/bin/conda-run.sh /conda-run.sh
SHELL ["/conda-run.sh"]
RUN conda init

# create work directory
ARG BUILD_DIR=/opt/build
ARG EXPORT_DIR=/opt/exports
RUN mkdir ${BUILD_DIR} ${EXPORT_DIR}
WORKDIR ${BUILD_DIR}

## Build the llama-cpp-python library with CUDA support
## additional permissible params: -DGGML_CUDA_FORCE_CUBLAS=on -DGGML_CUDA_FORCE_MMQ=on 
RUN <<-EOF
    CMAKE_ARGS="-DGGML_CUDA=on -DCUDA_ARCHITECTURES=all-major" FORCE_CMAKE=1 \
    pip wheel llama-cpp-python --no-cache-dir
EOF

# copy custom built packages to /opt/exports
RUN cp llama*.whl ${EXPORT_DIR}

##############################################################################################
##############################################################################################

## this dockergfile is loosely based on the github project
# FROM nvidia/cuda:12.6.3-runtime-ubuntu24.04 AS target
FROM nvidia/cuda:12.8.1-runtime-ubuntu24.04 AS target

# File Author / Maintainer
LABEL maintainer="Konrad Jelen <konrad.jelen@gmail.com>"

# copy build dir from builder
ARG EXPORT_DIR=/opt/exports
COPY --from=builder ${EXPORT_DIR} ${EXPORT_DIR}

# update sources list and increase timeouts
COPY ./conf/apt /etc/apt
COPY ./conf/apt-packages.yml /apt-packages.yml

# install yaml parser repository and yq tool, in the parent system you need
# RUN apt update && apt install -y software-properties-common
# RUN add-apt-repository ppa:rmescandon/yq -y && apt update && apt install yq -y
# and then copy /etc/apt/sources.list.d to docker image
ENV DEBIAN_FRONTEND=noninteractive 
RUN apt update && apt install yq -y 

# install required packages, list will be taken from apt-packages.yml
RUN <<-EOF
    echo "installing OS packages from manifest"
    apt install -y `yq eval '.packages[]' /apt-packages.yml | sed 's/$/ /' | tr -d '\r\n'`
    apt update && apt upgrade -y
EOF

# copy all config files and scripts
COPY --chmod=644  ./conf/etc.bash.bashrc /etc/bash.bashrc
COPY --chmod=644  ./conf/environment_base.yml /environment_base.yml
COPY --chmod=644  ./conf/environment_base_jupyterlab.yml /environment_base_jupyterlab.yml
COPY --chmod=644  ./conf/environment_tensorflow.yml /environment_tensorflow.yml
COPY --chmod=644  ./conf/environment_torch.yml /environment_torch.yml
COPY --chmod=755  ./conf/bin/conda-entry.sh /conda-entry.sh
COPY --chmod=755  ./conf/bin/mkchksum.sh /mkchksum.sh
COPY --chmod=755  ./conf/bin/conda-run.sh /conda-run.sh
COPY --chmod=755  ./conf/bin/start-jupyterlab.sh /start-jupyterlab.sh
COPY --chmod=755  ./conf/bin/generate-jupyterlab-ssl.sh /generate-jupyterlab-ssl.sh
COPY --chmod=755  ./conf/bin/welcome-message.sh /welcome-message.sh
COPY --chmod=644  ./conf/misc/welcome-message.txt /welcome-message.txt
COPY --chmod=755  ./conf/utils /opt/utils
COPY --chmod=644  ./conf/patches /tmp/patches

########################################################
#  FIX PACKAGES AND REMOVE UNNECESSARY                 #
########################################################

## container comes with pre-installed packages
## we need to remove them all and install conda
## filter packages to not uninstall base packages
RUN <<-EOF
    echo "cleaning existing python installation"
    pip freeze | grep -v blinker > requirements-to-uninstall.txt
    pip uninstall -r requirements-to-uninstall.txt -y
    pip cache purge
EOF

## allow viewer extensions to midnight commander - like for parquet files
RUN <<-EOF
    echo "patching midnight-commander extensions"
    cp -a /etc/mc/mc.ext.ini /etc/mc/mc.ext.ini.bak 2>/dev/null || true
    patch /etc/mc/mc.ext.ini /tmp/patches/mc.ext.ini.patch
EOF

########################################################
#  INSTALL AWS COMMANDLINE UTILITY V2                  #
########################################################

## need to install awscliv2 directly from amazon, otherwise it fails to work
RUN <<-EOF
    echo "installing amazon awscliv2 - AWS command line utility v2 "
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
    unzip /tmp/awscliv2.zip -d /tmp
    /tmp/aws/install
    echo "removing awscli installation files"
    rm -rf /tmp/aws /tmp/awscliv2.zip
EOF

########################################################
#  CREATE JUPYTERLAB CONDA USER                        #
########################################################

## user to be used with conda
ENV CONDA_HOME=/opt/conda
ARG UTILS_PATH=/opt/utils
ARG PATCHES_PATH=/tmp/patches
ENV CONDA_CMD=${CONDA_HOME}/condabin/conda
ARG CONDA_USER=lab
ARG CONDA_USER_UID=1000
ARG CONDA_USER_GROUP=lab
ARG CONDA_USER_GROUP_GID=1000
ARG JUPYTER_GROUP=jupyter
ARG JUPYTER_GROUP_GID=1001
ARG USER_DOCKER_CACHE_PATH=/tmp
ARG CONDA_USER_PASSWD=password
ARG CONDA_USER_HOME=/home/${CONDA_USER}
ARG CONDA_USER_WORKSPACE=${CONDA_USER_HOME}/workspace
ENV CONDA_RUN_DEBUG=0
ENV PATH=${PATH}:${CONDA_HOME}/condabin
ENV PIP_EXISTS_ACTION=w

## create new user with specific UID and GID, and add sudo rights
## also add group conda and add it to jupyterlab user
RUN <<-EOF
    echo "preparing conda user account"
    echo "removing existing ubuntu account if exists"
    userdel -f -r ubuntu 2>/dev/null || true

    echo "adding new ${CONDA_USER} account with specific UID=${CONDA_USER_UID} and GID=${CONDA_USER_GID}"
    groupadd -g ${CONDA_USER_GROUP_GID} ${CONDA_USER_GROUP}
    groupadd -g ${JUPYTER_GROUP_GID} ${JUPYTER_GROUP}
    useradd -ms /bin/bash -u ${CONDA_USER_UID} -g ${CONDA_USER_GROUP_GID} ${CONDA_USER}
    
    adduser -q ${CONDA_USER} sudo
    adduser -q ${CONDA_USER} ${JUPYTER_GROUP}
    adduser -q ${CONDA_USER} ${CONDA_USER_GROUP}

    echo "setting user ${CONDA_USER} default group to ${JUPYTER_GROUP}"
    usermod -g ${JUPYTER_GROUP} ${CONDA_USER}
    
    echo "setting user ${CONDA_USER} default password ${CONDA_USER_PASSWD}"
    echo "${CONDA_USER}:${CONDA_USER_PASSWD}" | chpasswd
EOF

## update sudoers to allow conda user sudo without password
# RUN echo "${CONDA_USER} ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers.d/conda

## switch user to update config file
USER ${CONDA_USER}

## use predefined contents of a user home
COPY --chown=${CONDA_USER} ./templates/home ${CONDA_USER_HOME}

## create workspace, this is where user projects will be located
RUN mkdir ${CONDA_USER_WORKSPACE}

## ensure good permissions, this is because files in github repo
## might have mixed permissions. we need to fix that
RUN <<-EOF
    echo "all directories in the ${CONDA_USER_HOME} should be accessible only to user '${CONDA_USER}'"
    find ${CONDA_USER_HOME} -type d -printf '"%p"\n' | xargs chmod 700
    echo "all files in the ${CONDA_USER_HOME} should be readible only to user '${CONDA_USER}'"
    find ${CONDA_USER_HOME} -type f -printf '"%p"\n' | xargs chmod 600
EOF

## set up vim with all its plugins including syntax colouring and autocomplete
## last '|| echo ok' is required for docker to assume successful build, as vim
## plugins installation exits with non-zero exit code
RUN <<-EOF
    echo "installing VIM plugins"
    git clone https://github.com/VundleVim/Vundle.vim.git ${CONDA_USER_HOME}/.vim/bundle/Vundle.vim
    vim -E -S ${CONDA_USER_HOME}/.vimrc -c "PluginInstall" -c "UnicodeDownload!" -c "qall" || echo ok
EOF

########################################################
#  PREPARE JUPYTERLAB WORKSPACE AND CERTS              #
########################################################

## certs and workspace folders should be owned by the user
USER ${CONDA_USER}

# make sure initial workspace has template files
COPY --chown=${CONDA_USER} ./templates/workspace ${CONDA_USER_WORKSPACE}
COPY --chown=${CONDA_USER} ./templates/certs /mnt/certs
COPY --chown=${CONDA_USER} ./templates/cache /mnt/cache

## install helpful scripts in the workspace as symlinks
RUN <<-EOF
    echo "copying workspace helpful scripts"
    for x in `ls ${UTILS_PATH}/*.sh`; do
	ln -s $x ${CONDA_USER_WORKSPACE}/`basename $x`
    done
EOF

########################################################
#  CONDA JUPYTERLAB ENVIRONMENT INSTALLATION           #
########################################################

## conda must be installed as root
USER root

## create default and additional environments. by default CONDA_DEFAULT_ENV should be 'base', 
## but you can make it different. There are also dedicated 'tensorflow' and 'torch' environments 
## to separate dependencies and avoid dependency conflicts. ARG CONDA_DEFAULT_ENV is required 
## additionally to ENV for effective variable substitution in the RUN statements
ARG CONDA_TENSORFLOW_ENV=tensorflow
ARG CONDA_TORCH_ENV=torch
ENV CONDA_DEFAULT_ENV=base

## prevent automatic 'base' activation
## alternative is 'conda config --set auto_activate_base false'
ENV CONDA_AUTO_ACTIVATE_BASE=false

## change ownership of conda folder to conda user
RUN <<-EOF
    echo "creating $CONDA_HOME directory"
    mkdir -p /opt/conda
    chown -R :${JUPYTER_GROUP} ${CONDA_HOME}
    chmod -R 770 ${CONDA_HOME}
EOF

## create empty logfile with permissions for jupyterlab to write
ARG JUPYTER_LOG=/var/log/jupyterlab.log
RUN <<-EOF
    echo "creating jupyter logs directory accessible to users"
    touch ${JUPYTER_LOG}
    chown :${JUPYTER_GROUP} ${JUPYTER_LOG}
    chmod 664 ${JUPYTER_LOG}
EOF

## switch user to conda jupyterlab user
USER ${CONDA_USER}
WORKDIR ${CONDA_USER_HOME}

## install conda from miniforge archive https://github.com/conda-forge/miniforge
RUN <<-EOF
    echo "installing miniforge3"
    wget https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh \
	-O ~/miniforge3.sh
    bash ~/miniforge3.sh -b -u -p ${CONDA_HOME}
    rm -rf ~/miniforge3.sh
EOF

## update conda system & install required packages from environment.yml
RUN <<-EOF 
    echo "installing ${CONDA_DEFAULT_ENV} env with python version from env file"
    if [ "${CONDA_DEFAULT_ENV}" != "base" ]; then
	${CONDA_CMD} create --name ${CONDA_DEFAULT_ENV} -y
    fi

    ${CONDA_CMD} env update -v --name ${CONDA_DEFAULT_ENV} --file=/environment_base.yml 
    ${CONDA_CMD} update --name ${CONDA_DEFAULT_ENV} -c conda-forge -y conda
EOF

## Tell the docker build process to use this for RUN.
## this script enables environment when used 
## with environment variable CONDA_DEFAULT_ENV=<environment_name>
SHELL ["/conda-run.sh"]

## Configure .bashrc to drop into a conda env and immediately activate our TARGET env
## Save CONDA_DEFAULT_ENV first, as it will be overwritten by conda init
RUN <<-EOF
    echo "prepare bash shell initialisation script"
    conda init
    echo "# activate environment set by CONDA_DEFAULT_ENV env variable" >> ${CONDA_USER_HOME}/.bashrc
    echo "# it is initialised either in .profile or during container start" >> ${CONDA_USER_HOME}/.bashrc
    echo 'conda activate ${CONDA_DEFAULT_ENV}' >> ${CONDA_USER_HOME}/.bashrc
    echo "# EOF" >> ${CONDA_USER_HOME}/.bashrc
EOF

## patch ~/.profile to have an example of conda preferred environment
RUN <<-EOF
    echo "patching shell profile script" 
    cd ${CONDA_USER_HOME}
    patch < ${PATCHES_PATH}/home.profile.patch
    echo "patched ${CONDA_USER_HOME}/.profile"
EOF

## it must be configured to work with jupyter notebooks via nbdime
RUN <<-EOF
    echo "configuring git to work with jupyter notebooks"
    conda run -n ${CONDA_DEFAULT_ENV} conda run pip install nbdime
    conda run -n ${CONDA_DEFAULT_ENV} conda run nbdime config-git --enable --global
EOF

## final update of the entire conda base environment
RUN CONDA_DEFAULT_ENV="${CONDA_DEFAULT_ENV}" conda update -y -c conda-forge --all

########################################################
#  NVIDIA CUDA, TORCH & TENSORFLOW INSTALLATION        #
########################################################

## run installation as conda user
USER ${CONDA_USER}

## install cuda accelerated numpy = cupy and conda-version in the base enviromnent
## this should be available to both tensorflow and torch environments later
#RUN CONDA_DEFAULT_ENV=${CONDA_DEFAULT_ENV:-base} \ 
# conda install -y -c rapidsai -c conda-forge -c nvidia rapids cuda-version cupy cudf

## clone built base env to both tensorflow and torch envs
RUN <<-EOF
    echo "cloning ${CONDA_TENSORFLOW_ENV} and ${CONDA_TORCH_ENV} environments from ${CONDA_DEFAULT_ENV}"
    conda create --name ${CONDA_TENSORFLOW_ENV} --clone ${CONDA_DEFAULT_ENV}
    conda create --name ${CONDA_TORCH_ENV} --clone ${CONDA_DEFAULT_ENV}
EOF

## need to set CONDA_OVERRIDE_CUDA, see https://conda-forge.org/blog/2021/11/03/tensorflow-gpu/
## needed if tensorflow or torch are installed using conda, otherwise this is ignored
ENV CONDA_OVERRIDE_CUDA=12.3

## install tensorflow using pip to its dedicated environment
## installing tf-keras allows to use KERAS v2 (legacy)
RUN conda env update -v --name ${CONDA_TENSORFLOW_ENV} --file=/environment_tensorflow.yml 

## install torch to its dedicated environment
## install torch with torchvision and ultralytics (yolo)
RUN conda env update -v --name ${CONDA_TORCH_ENV} --file=/environment_torch.yml 

## make sure CUDNN_PATH and LD_LIBRARY_PATH is pointing to cuda
## see https://stackoverflow.com/questions/60208936/cannot-dlopen-some-gpu-libraries-skipping-registering-gpu-devices
## path can be obtained by using >> python -c "import nvidia.cudnn;print(nvidia.cudnn.__file__)"))
ENV CUDNN_PATH=/opt/conda/lib/python3.11/site-packages/nvidia/cudnn
ENV LD_LIBRARY_PATH=${CUDNN_PATH}/lib:${LD_LIBRARY_PATH}


########################################################
#  JUPYTERLAB INSTALLATION                             #
########################################################

## update conda by installing jupyterlab
## we didn't do this earlier to have jupyterlab only in base
## and not to clone it to other environments
RUN <<-EOF 
    echo "installing Jupyterlab in ${CONDA_DEFAULT_ENV} env"
    ${CONDA_CMD} env update --name ${CONDA_DEFAULT_ENV} --file=/environment_base_jupyterlab.yml 
EOF


########################################################
#  GENERATIVE AI WITHi CUDA SUPPORT ON TORCH           #
########################################################

## packages were built by the builder container, install them all
## among the packages is CUDA supported llama-cpp-python
## other environments will inherit this when cloned from base
USER ${CONDA_USER}
RUN <<-EOF
    echo "installing packages built with builder: `ls ${EXPORT_DIR}/*.whl`"
    conda run -n ${CONDA_TORCH_ENV} pip install ${EXPORT_DIR}/*.whl
EOF

########################################################
#  FINAL UPDATE AND CLEANUP                            #
########################################################

## final round of updates to keep all up to date and final cleanup
RUN CONDA_DEFAULT_ENV=${CONDA_DEFAULT_ENV:-base} conda clean -ltpy && pip cache purge
RUN CONDA_DEFAULT_ENV=${CONDA_TENSORFLOW_ENV} conda clean -ltpy && pip cache purge
RUN CONDA_DEFAULT_ENV=${CONDA_TORCH_ENV} conda clean -ltpy && pip cache purge

## remove prebuilt packages imported from builder
## apt cleanup and remove prebuilt packages
USER root
# RUN rm -rf ${EXPORT_DIR}
RUN apt autoremove -y && apt purge 


########################################################
#  PREPARE DOCKER CONTAINER ENTRY POINT                #
########################################################

USER root

## ignore pip warnings re root access
ENV PIP_ROOT_USER_ACTION=ignore

## save build date for reference
COPY --chmod=644 ./conf/misc/build-info.txt /
COPY --chmod=644 ./conf/misc/motd-template.txt /

## generate build name and build date
## and generate motd using template
RUN <<-EOF
    echo "generating build name"
    date >/build-date.txt
    gpw 1 4 | tr [:lower:] [:upper:] >/build-name.txt
    cat /motd-template.txt | sed "s/@BUILD_NAME@/$(cat /build-name.txt)/g" \
	| sed "s/@BUILD_DATE@/$(cat /build-date.txt)/g" > /etc/motd
    rm /motd-template.txt
EOF

## update terminal and shell settings
ENV TERM=xterm-256color

## startup ENV parameters for jupyterlab
ENV JUPYTERLAB_SERVER_IP="*"
ENV JUPYTERLAB_SERVER_TOKEN=""

## default values for GPU support envs
# GPU_SUPPORT_ENABLED controls nvidia support of the system
# and GPUSTAT_ENABLED enables gpu status message in terminal if GPU present
ENV GPU_SUPPORT_ENABLED=0 
ENV GPUSTAT_ENABLED=1

## setup entry point, workdir and startup command
## and set user to be conda user
USER ${CONDA_USER}
WORKDIR ${CONDA_USER_WORKSPACE}
ENTRYPOINT ["/conda-entry.sh"]
CMD ["/start-jupyterlab.sh"]

## expose ports
# 8888 - jupyterlab, 8000 and 8001 - jupyterhub
# 6006 - tensorboard, 5000 - mlflow, 3030 - general purpose callback port
# you would typically use socat to pass callback traffic to container
EXPOSE 8888 
EXPOSE 8000
EXPOSE 8001 
EXPOSE 6006
EXPOSE 5000
EXPOSE 3030

# EOF

