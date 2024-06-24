## this dockergfile is loosely based on the github project
FROM nvidia/cuda:12.4.1-cudnn-runtime-ubuntu22.04

# File Author / Maintainer
MAINTAINER Konrad Jelen <konrad.jelen@gmail.com>

# update sources list and increase timeouts
COPY ./conf/apt /etc/apt
COPY ./conf/apt-packages.yml /apt-packages.yml

# install yaml parser repository and yq tool, in the parent system you need
# RUN apt update && apt install -y software-properties-common
# RUN add-apt-repository ppa:rmescandon/yq -y && apt update && apt install yq -y
# and then copy /etc/apt/sources.list.d to docker image
RUN apt update && apt install yq -y 

# install required packages, list will be taken from apt-packages.yml
RUN apt install -y `yq eval '.packages[]' /apt-packages.yml | sed 's/$/ /' | tr -d '\r\n'`
RUN apt update && apt upgrade -y

# copy all config files and scripts
COPY --chmod=644  ./conf/etc.bash.bashrc /etc/bash.bashrc
COPY --chmod=644  ./conf/environment.yml /environment.yml
COPY --chmod=755  ./conf/bin/conda-entry.sh /conda-entry.sh
COPY --chmod=755  ./conf/bin/conda-run.sh /conda-run.sh
COPY --chmod=755  ./conf/bin/start-jupyterlab.sh /start-jupyterlab.sh
COPY --chmod=755  ./conf/bin/generate-jupyterlab-ssl.sh /generate-jupyterlab-ssl.sh
COPY --chmod=755  ./conf/bin/welcome-message.sh /welcome-message.sh
COPY --chmod=655  ./conf/misc/welcome-message.sh /welcome-message.txt


########################################################
#  REMOVE DEFAULT PACKAGES                             #
########################################################

## container comes with pre-installed packages
## we need to remove them all and install conda
## filter packages to not uninstall base packages
RUN pip freeze | grep -v blinker > requirements-to-uninstall.txt \
 && pip uninstall -r requirements-to-uninstall.txt -y \
 && pip cache purge


########################################################
#  CREATE JUPYTERLAB CONDA USER                        #
########################################################

## user to be used with conda
ENV CONDA_HOME /opt/conda
ARG CONDA_USER=lab
ARG CONDA_USER_PASSWD=password
ARG JUPYTER_GROUP=jupyter
ARG CONDA_USER_HOME=/home/${CONDA_USER}
# ARG JUPYTER_WORKSPACE=/mnt/workspace
ARG CONDA_USER_WORKSPACE=${CONDA_USER_HOME}/workspace

## create new user and add sudo rights
## also add group conda and add it to jupyterlab user
RUN useradd -ms /bin/bash ${CONDA_USER} \
 && addgroup ${JUPYTER_GROUP} \
 && adduser -q ${CONDA_USER} sudo  \
 && adduser -q ${CONDA_USER} ${JUPYTER_GROUP} \
 && usermod -g ${JUPYTER_GROUP} ${CONDA_USER} \
 && echo "${CONDA_USER}:${CONDA_USER_PASSWD}" | chpasswd

## update sudoers to allow conda user sudo without password
# RUN echo "${CONDA_USER} ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers.d/conda

## switch user to update config file
USER ${CONDA_USER}

## use predefined contents of a user home
COPY --chown=${CONDA_USER} ./templates/home ${CONDA_USER_HOME}

## use predefined jupyter and other config files
#COPY --chown=${CONDA_USER} ./conf/dot.jupyter ${CONDA_USER_HOME}/.jupyter
#COPY --chown=${CONDA_USER} ./conf/dot.config  ${CONDA_USER_HOME}/.config
#COPY --chown=${CONDA_USER} --chmod=644 ./conf/dot.vimrc   ${CONDA_USER_HOME}/.vimrc

## ensure good permissions
RUN find ${CONDA_USER_HOME} -type d -printf '"%p"\n' | xargs chmod 700 \
 && find ${CONDA_USER_HOME} -type f -printf '"%p"\n' | xargs chmod 600

## set up vim with all its plugins
RUN git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim \
 && vim -E -S ~/.vimrc +PluginInstall +qall || echo ok


########################################################
#  CONDA JUPYTERLAB ENVIRONMENT INSTALLATION           #
########################################################

## conda must be installed as root
USER root

## Create target env and ignore pip warnings
## you can use 'base' or 'jupyterlab' for env name
ENV CONDA_DEFAULT_ENV base
ENV CONDA_PYTHON_VERSION 3.11

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

## set path to conda bin
ENV PATH $PATH:/opt/conda/bin

## install conda from miniforge archive https://github.com/conda-forge/miniforge
RUN wget https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh \
 -O ~/miniforge3.sh && bash ~/miniforge3.sh -b -u -p ${CONDA_HOME} \
 && rm -rf ~/miniforge3.sh

## update conda system & install required packages from environment.yml
RUN conda install -n base -c conda-forge -y python=${CONDA_PYTHON_VERSION}
RUN conda update -n base -c defaults -y conda
RUN conda env update -n ${CONDA_DEFAULT_ENV:-base} -f /environment.yml 

## Tell the docker build process to use this for RUN.
## this script enables environment when used 
## with environment variable CONDA_DEFAULT_ENV=<environment_name>
SHELL ["/conda-run.sh"]

## Configure .bashrc to drop into a conda env and immediately activate our TARGET env
## Save CONDA_DEFAULT_ENV first, as it will be overwritten by conda init
RUN rm ~/.bashrc \
 && echo '# saving the conda environment, as conda init is going to reset this to "base"' >> ~/.bashrc \
 && echo '_CONDA_DEFAULT_ENV=${CONDA_DEFAULT_ENV:-base}' >>  ~/.bashrc \
 && conda init \
 && echo '# restoring saved conda default env, as it was resetted to "base" by conda init' >> ~/.bashrc \
 && echo 'CONDA_DEFAULT_ENV=${_CONDA_DEFAULT_ENV:-base}' >>  ~/.bashrc \
 && echo 'conda activate "${CONDA_DEFAULT_ENV:-base}"' >>  ~/.bashrc

## merge bashrc files - conda generated and copied
COPY --chmod=644 ./conf/dot.bashrc ${CONDA_USER_HOME}/dot.bashrc
RUN cat ${CONDA_USER_HOME}/dot.bashrc > ${CONDA_USER_HOME}/bashrc-to-merge \
 && cat ${CONDA_USER_HOME}/.bashrc >> ${CONDA_USER_HOME}/bashrc-to-merge \
 && mv  ${CONDA_USER_HOME}/bashrc-to-merge ${CONDA_USER_HOME}/.bashrc  \
 && rm  ${CONDA_USER_HOME}/dot.bashrc

## final update of the entire conda using conda-forge as preferred channel
RUN CONDA_DEFAULT_ENV=${CONDA_DEFAULT_ENV:-base} conda update -y -c conda-forge --all 

########################################################
#  NVIDIA CUDA & TENSORFLOW INSTALLATION               #
########################################################

## need to set CONDA_OVERRIDE_CUDA, see https://conda-forge.org/blog/2021/11/03/tensorflow-gpu/
## needed if tensorflow or torch are installed using conda, otherwise this is ignored
ENV CONDA_OVERRIDE_CUDA=12.4

## install cuda toolkit - required by tensorflow and torch
## disabled because required packages are already 
## available in in nvidia/cuda:12.4.1-cudnn-runtime-ubuntu22.04
# RUN echo "${CONDA_USER_PASSWD}" | sudo -S apt install cuda-toolkit -y

## install tensorflow using pip using >>> pip install tensorflow[and-cuda]
## installing tf-keras allows to use KERAS v2 (legacy)
RUN CONDA_DEFAULT_ENV=${CONDA_DEFAULT_ENV:-base} \ 
 pip install --upgrade tensorflow[and-cuda] tf-keras tensorboard keras-cv \
 keras-mdn-layer keras-multi-head keras-self-attention keras-tcn keras_nlp


## make sure CUDNN_PATH and LD_LIBRARY_PATH is pointing to cuda
## see https://stackoverflow.com/questions/60208936/cannot-dlopen-some-gpu-libraries-skipping-registering-gpu-devices
## path can be obtained by using >> python -c "import nvidia.cudnn;print(nvidia.cudnn.__file__)"))
ENV CUDNN_PATH /opt/conda/lib/python3.11/site-packages/nvidia/cudnn
ENV LD_LIBRARY_PATH ${CUDNN_PATH}/lib:${LD_LIBRARY_PATH}

## set env variables to disable tensorflow warnings and to enable new libstdc++.so.6
ENV TF_CPP_MIN_LOG_LEVEL 3

## install cuda accelerated numpy = cupy and conda-version
#RUN CONDA_DEFAULT_ENV=${CONDA_DEFAULT_ENV:-base} \ 
# conda install -y -c rapidsai -c conda-forge -c nvidia rapids cuda-version cupy cudf

## install torchvision, torch and ultralytics (yolo)
## also install libgl1 to avoid issues with libGL missing
RUN echo "${CONDA_USER_PASSWD}" | sudo -S apt install -y libgl1
RUN  CONDA_DEFAULT_ENV=${CONDA_DEFAULT_ENV:-base} \
 pip install --upgrade torch torchvision ultralytics


########################################################
#  FINAL UPDATE AND CLEANUP                            #
########################################################

## final round of updates to keep all up to date
## disabled update - it is automatically downgrading pytorch
#RUN CONDA_DEFAULT_ENV=${CONDA_DEFAULT_ENV:-base} \
# conda update -c conda-forge --all -y

## conda and pip cleanup
RUN CONDA_DEFAULT_ENV=${CONDA_DEFAULT_ENV:-base} conda clean -ltpy && pip cache purge

## apt cleanup
RUN echo "${CONDA_USER_PASSWD}" | sudo -S apt autoremove -y \
 && echo "${CONDA_USER_PASSWD}" | sudo -S apt purge 

########################################################
#  PREPARE JUPYTERLAB WORKSPACE AND CERTS              #
########################################################

# make sure initial workspace has template files
COPY --chown=${CONDA_USER} ./templates/workspace ${CONDA_USER_WORKSPACE}
COPY --chown=${CONDA_USER} ./templates/certs /mnt/certs

########################################################
#  PREPARE DOCKER CONTAINER ENTRY POINT                #
########################################################

## ignore pip warnings re root access
ENV PIP_ROOT_USER_ACTION ignore

## save build date for reference
COPY --chmod=644 ./conf/misc/build-info.txt /
COPY --chmod=644 ./conf/misc/motd-prototype.txt /
RUN echo "${CONDA_USER_PASSWD}" | sudo -S bash -c "date >/build-date.txt"
RUN echo "${CONDA_USER_PASSWD}" | sudo -S bash -c "gpw 1 4 | tr [:lower:] [:upper:] >/build-name.txt"
# RUN echo "${CONDA_USER_PASSWD}" | sudo -S bash -c " rig | head -n 1 | awk '{print $2}'>/build-name.txt"
RUN echo "${CONDA_USER_PASSWD}" | sudo -S bash -c "cat /motd-prototype.txt | sed \"s/@BUILD_NAME@/$(cat /build-name.txt)/g\" | sed \"s/@BUILD_DATE@/$(cat /build-date.txt)/g\" > /etc/motd"

## update terminal and shell settings
ENV TERM xterm-256color

## startup ENV parameters for jupyterlab
ENV JUPYTERLAB_SERVER_IP "*"
ENV JUPYTERLAB_SERVER_TOKEN ""
ENV JUPYTERLAB_SERVER_PASSWORD ""

## setup entry point, workdir and startup command
WORKDIR ${CONDA_USER_WORKSPACE}
ENTRYPOINT ["/conda-entry.sh"]
CMD ["/start-jupyterlab.sh"]

# EOF
