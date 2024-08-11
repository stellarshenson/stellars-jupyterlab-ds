## this container will serve as a builder for some cuda-specific
## libraries like huggingface llama_cpp
FROM nvidia/cuda:12.5.1-cudnn-runtime-ubuntu22.04 AS builder


# Install necessary packages for building
ENV DEBIAN_FRONTEND=noninteractive 
RUN apt-get update && apt-get install -y \
    git \
    build-essential \
    wget \
    cmake \
    python3 \
    python3-pip \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*


# make sure we have conda
ENV CONDA_DEFAULT_ENV=base
ENV CONDA_HOME=/opt/conda
ENV CONDA_CMD=${CONDA_HOME}/condabin/conda
ARG CONDA_PYTHON_VERSION=3.11

# download and install conda
RUN wget https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh \
 -O ~/miniforge3.sh && bash ~/miniforge3.sh -b -u -p ${CONDA_HOME} \
 && rm -rf ~/miniforge3.sh

## install base env
RUN ${CONDA_CMD} install --name base -c conda-forge -y python=${CONDA_PYTHON_VERSION}
RUN ${CONDA_CMD} update --name base -c defaults -y conda
RUN ${CONDA_CMD} install --name base -v -y cuda-toolkit=12.1

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
## additional permisible params: -DGGML_CUDA_FORCE_CUBLAS=on -DGGML_CUDA_FORCE_MMQ=on 
RUN CMAKE_ARGS="-DGGML_CUDA=on -DCUDA_ARCHITECTURES=all-major" FORCE_CMAKE=1 pip wheel llama-cpp-python --no-cache-dir

# copy custom built packages to /opt/custo
RUN cp llama*.whl ${EXPORT_DIR}

##############################################################################################
##############################################################################################

## this dockergfile is loosely based on the github project
# FROM nvidia/cuda:12.5.1-cudnn-runtime-ubuntu22.04
FROM nvidia/cuda:12.5.1-runtime-ubuntu22.04

# File Author / Maintainer
LABEL maintainer="Konrad Jelen <konrad.jelen@gmail.com>"
ARG TENSORFLOW_VERSION="<2.17"

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
RUN apt install -y `yq eval '.packages[]' /apt-packages.yml | sed 's/$/ /' | tr -d '\r\n'`
RUN apt update && apt upgrade -y

# copy all config files and scripts
COPY --chmod=644  ./conf/etc.bash.bashrc /etc/bash.bashrc
COPY --chmod=644  ./conf/environment_base.yml /environment_base.yml
COPY --chmod=644  ./conf/environment_tensorflow.yml /environment_tensorflow.yml
COPY --chmod=644  ./conf/environment_torch.yml /environment_torch.yml
COPY --chmod=755  ./conf/bin/conda-entry.sh /conda-entry.sh
COPY --chmod=755  ./conf/bin/conda-run.sh /conda-run.sh
COPY --chmod=755  ./conf/bin/start-jupyterlab.sh /start-jupyterlab.sh
COPY --chmod=755  ./conf/bin/generate-jupyterlab-ssl.sh /generate-jupyterlab-ssl.sh
COPY --chmod=755  ./conf/bin/welcome-message.sh /welcome-message.sh
COPY --chmod=644  ./conf/misc/welcome-message.txt /welcome-message.txt
COPY --chmod=755  ./conf/utils /opt/utils
COPY --chmod=644  ./conf/patches /tmp/patches

########################################################
#  REMOVE DEFAULT PACKAGES                             #
########################################################

## container comes with pre-installed packages
## we need to remove them all and install conda
## filter packages to not uninstall base packages
RUN pip freeze | grep -v blinker > requirements-to-uninstall.txt \
 && pip uninstall -r requirements-to-uninstall.txt -y  \
 && pip cache purge


########################################################
#  CREATE JUPYTERLAB CONDA USER                        #
########################################################

## user to be used with conda
ENV CONDA_HOME=/opt/conda
ARG UTILS_PATH=/opt/utils
ARG PATCHES_PATH=/opt/patches
ENV CONDA_CMD=${CONDA_HOME}/condabin/conda
ARG CONDA_USER=lab
ARG CONDA_USER_PASSWD=password
ARG JUPYTER_GROUP=jupyter
ARG CONDA_USER_HOME=/home/${CONDA_USER}
ARG CONDA_USER_WORKSPACE=${CONDA_USER_HOME}/workspace

## create new user and add sudo rights
## also add group conda and add it to jupyterlab user
RUN <<EOF
useradd -ms /bin/bash ${CONDA_USER}
addgroup ${JUPYTER_GROUP}
adduser -q ${CONDA_USER} sudo
adduser -q ${CONDA_USER} ${JUPYTER_GROUP}
usermod -g ${JUPYTER_GROUP} ${CONDA_USER}
echo "${CONDA_USER}:${CONDA_USER_PASSWD}" | chpasswd
EOF

## update sudoers to allow conda user sudo without password
# RUN echo "${CONDA_USER} ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers.d/conda

## switch user to update config file
USER ${CONDA_USER}

## use predefined contents of a user home
COPY --chown=${CONDA_USER} ./templates/home ${CONDA_USER_HOME}

## create workspace
RUN mkdir ${CONDA_USER_WORKSPACE}

## ensure good permissions
RUN find ${CONDA_USER_HOME} -type d -printf '"%p"\n' | xargs chmod 700 \
 && find ${CONDA_USER_HOME} -type f -printf '"%p"\n' | xargs chmod 600

## set up vim with all its plugins
RUN git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim \
 && vim -E -S ~/.vimrc +PluginInstall +qall || echo ok

########################################################
#  PREPARE JUPYTERLAB WORKSPACE AND CERTS              #
########################################################

## templates should be owned by the user
USER ${CONDA_USER}

# make sure initial workspace has template files
COPY --chown=${CONDA_USER} ./templates/workspace ${CONDA_USER_WORKSPACE}
COPY --chown=${CONDA_USER} ./templates/certs /mnt/certs

## install helpful scripts in the workspace as symlinks
RUN <<EOF
for x in `ls ${UTILS_PATH}/*.sh`; do 
    ln -s $x ${CONDA_USER_WORKSPACE}/`basename $x`
done
EOF

########################################################
#  CONDA JUPYTERLAB ENVIRONMENT INSTALLATION           #
########################################################

## conda must be installed as root
USER root

## Create target env and ignore pip warnings
## you can use 'base' or 'jupyterlab' for env name
## also made dedicatedd tf and pt envs but they are not used yet
ENV CONDA_DEFAULT_ENV=base
ARG CONDA_TENSORFLOW_ENV=tensorflow
ARG CONDA_TORCH_ENV=torch
ARG CONDA_PYTHON_VERSION=3.11

## change ownership of conda folder to conda user
RUN mkdir -p /opt/conda && chown -R :${JUPYTER_GROUP} ${CONDA_HOME} && chmod -R 770 ${CONDA_HOME}

## create empty logfile with permissions for jupyterlab to write
ARG JUPYTER_LOG=/var/log/jupyterlab.log
RUN touch ${JUPYTER_LOG} \
 && chown :${JUPYTER_GROUP} ${JUPYTER_LOG} \
 && chmod 664 ${JUPYTER_LOG}

## switch user to conda jupyterlab user
USER ${CONDA_USER}
WORKDIR ${CONDA_USER_HOME}

## install conda from miniforge archive https://github.com/conda-forge/miniforge
RUN wget https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh \
 -O ~/miniforge3.sh && bash ~/miniforge3.sh -b -u -p ${CONDA_HOME} \
 && rm -rf ~/miniforge3.sh

## update conda system & install required packages from environment.yml
RUN ${CONDA_CMD} install --name base -c conda-forge -y python=${CONDA_PYTHON_VERSION}
RUN ${CONDA_CMD} update --name base -c conda-forge -y conda

## create first environment (should be base)
RUN ${CONDA_CMD} env update --name ${CONDA_DEFAULT_ENV:-base} -f /environment_base.yml 

## Tell the docker build process to use this for RUN.
## this script enables environment when used 
## with environment variable CONDA_DEFAULT_ENV=<environment_name>
SHELL ["/conda-run.sh"]

## Configure .bashrc to drop into a conda env and immediately activate our TARGET env
## Save CONDA_DEFAULT_ENV first, as it will be overwritten by conda init
RUN <<EOF
 rm ~/.bashrc
 echo '###### START OF AUTOGENERATED CODE IN DOCKERFILE' >> ~/.bashrc
 echo '# saving the conda environment, as conda init is going to reset this to "base"' >> ~/.bashrc
 echo '_CONDA_DEFAULT_ENV=${CONDA_DEFAULT_ENV:-base}' >>  ~/.bashrc
 conda init
 echo '# restoring saved conda default env, as it was resetted to "base" by conda init' >> ~/.bashrc
 echo 'CONDA_DEFAULT_ENV=${_CONDA_DEFAULT_ENV:-base}' >>  ~/.bashrc
 echo 'conda activate "${CONDA_DEFAULT_ENV:-base}"' >>  ~/.bashrc
 echo '###### END OF AUTOGENERATED CODE IN DOCKERFILE' >> ~/.bashrc
EOF

## merge bashrc files - conda generated and copied
COPY --chmod=644 ./conf/home.bashrc ${CONDA_USER_HOME}/home.bashrc
RUN <<EOF
 cat ${CONDA_USER_HOME}/home.bashrc > ${CONDA_USER_HOME}/bashrc-to-merge
 cat ${CONDA_USER_HOME}/.bashrc >> ${CONDA_USER_HOME}/bashrc-to-merge
 mv  ${CONDA_USER_HOME}/bashrc-to-merge ${CONDA_USER_HOME}/.bashrc
 rm  ${CONDA_USER_HOME}/home.bashrc
EOF

## patch ~/.profile to have an example of conda preferred environment
RUN <<EOF
 cd ${CONDA_USER_HOME}
 patch < ${PATCHES_PATH}/home.profile.patch
EOF


## final update of the entire conda using conda-forge as preferred channel
RUN CONDA_DEFAULT_ENV=${CONDA_DEFAULT_ENV:-base} conda update -y -c conda-forge --all 


########################################################
#  GENERATIVE AI WITHi CUDA SUPPORT                    #
########################################################

## packages were built by the builder container, install them all
## among the packages is CUDA supported llama-cpp-python
USER ${CONDA_USER}
RUN CONDA_DEFAULT_ENV=${CONDA_DEFAULT_ENV} /usr/bin/env pip install ${EXPORT_DIR}/*.whl 

########################################################
#  NVIDIA CUDA, TORCH & TENSORFLOW INSTALLATION        #
########################################################

## run installation as conda user
USER ${CONDA_USER}

## clone built base env to both tensorflow and torch envs
RUN conda create --name ${CONDA_TENSORFLOW_ENV} --clone ${CONDA_DEFAULT_ENV}
RUN conda create --name ${CONDA_TORCH_ENV} --clone ${CONDA_DEFAULT_ENV}

## need to set CONDA_OVERRIDE_CUDA, see https://conda-forge.org/blog/2021/11/03/tensorflow-gpu/
## needed if tensorflow or torch are installed using conda, otherwise this is ignored
ENV CONDA_OVERRIDE_CUDA=12.5

## install tensorflow using pip to its dedicated environment
## installing tf-keras allows to use KERAS v2 (legacy)
RUN conda env update -v --name ${CONDA_TENSORFLOW_ENV} -f /environment_tensorflow.yml 

## install torch to its dedicated environment
## install torch with torchvision and ultralytics (yolo)
RUN conda env update -v --name ${CONDA_TORCH_ENV} -f /environment_torch.yml 

## make sure CUDNN_PATH and LD_LIBRARY_PATH is pointing to cuda
## see https://stackoverflow.com/questions/60208936/cannot-dlopen-some-gpu-libraries-skipping-registering-gpu-devices
## path can be obtained by using >> python -c "import nvidia.cudnn;print(nvidia.cudnn.__file__)"))
ENV CUDNN_PATH=/opt/conda/lib/python3.11/site-packages/nvidia/cudnn
ENV LD_LIBRARY_PATH=${CUDNN_PATH}/lib:${LD_LIBRARY_PATH}

## set env variables to disable tensorflow warnings and to enable new libstdc++.so.6
ENV TF_CPP_MIN_LOG_LEVEL=3

## install cuda accelerated numpy = cupy and conda-version
#RUN CONDA_DEFAULT_ENV=${CONDA_DEFAULT_ENV:-base} \ 
# conda install -y -c rapidsai -c conda-forge -c nvidia rapids cuda-version cupy cudf


########################################################
#  FINAL UPDATE AND CLEANUP                            #
########################################################

## final round of updates to keep all up to date and final cleanup
RUN CONDA_DEFAULT_ENV=${CONDA_DEFAULT_ENV:-base} conda clean -ltpy && /usr/bin/env pip cache purge
RUN CONDA_DEFAULT_ENV=${CONDA_TENSORFLOW_ENV} conda clean -ltpy && /usr/bin/env pip cache purge
RUN CONDA_DEFAULT_ENV=${CONDA_TORCH_ENV} conda clean -ltpy && /usr/bin/env pip cache purge

## apt cleanup
USER root
RUN apt autoremove -y && apt purge 

########################################################
#  PREPARE DOCKER CONTAINER ENTRY POINT                #
########################################################

USER root

## ignore pip warnings re root access
ENV PIP_ROOT_USER_ACTION=ignore

## save build date for reference
COPY --chmod=644 ./conf/misc/build-info.txt /
COPY --chmod=644 ./conf/misc/motd-prototype.txt /
RUN bash -c "date >/build-date.txt"
RUN bash -c "gpw 1 4 | tr [:lower:] [:upper:] >/build-name.txt"
RUN bash -c "cat /motd-prototype.txt | sed \"s/@BUILD_NAME@/$(cat /build-name.txt)/g\" | sed \"s/@BUILD_DATE@/$(cat /build-date.txt)/g\" > /etc/motd"

## update terminal and shell settings
ENV TERM=xterm-256color

## startup ENV parameters for jupyterlab
ENV JUPYTERLAB_SERVER_IP="*"
ENV JUPYTERLAB_SERVER_TOKEN=""
ENV JUPYTERLAB_SERVER_PASSWORD=""

## default values for GPU support envs
# GPU_SUPPORT_ENABLED controls nvidia support of the system
# and GPUSTAT_ENABLED enables gpu status message in terminal if GPU present
ENV GPU_SUPPORT_ENABLED=0 
ENV GPUSTAT_ENABLED=1

## setup entry point, workdir and startup command
## and set user to be conda user
WORKDIR ${CONDA_USER_WORKSPACE}
ENTRYPOINT ["/conda-entry.sh"]
CMD ["/start-jupyterlab.sh"]
USER ${CONDA_USER}

## expose ports
# 8888 - jupyterlab, 8000 and 8001 - jupyterhub
# 6006 - tensorboard, 5000 - mlflow
EXPOSE 8888 
EXPOSE 8000
EXPOSE 8001 
EXPOSE 6006
EXPOSE 5000

# EOF
