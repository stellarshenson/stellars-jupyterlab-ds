## this dockergfile is loosely based on the github project
FROM tensorflow/tensorflow:latest-gpu

# update sources list and increase timeouts
COPY ./conf/apt /etc/apt

# install dependencies
RUN apt update && apt upgrade -y
RUN apt install -y git vim bash-completion mc curl sudo software-properties-common \ 
 less gpw gpg iputils-ping graphviz man gcc tree locate git zip

# copy all config files and scripts
COPY ./conf/etc.bash.bashrc /etc/bash.bashrc
COPY ./conf/etc.motd /etc/motd
COPY ./conf/environment.yml /environment.yml
COPY ./conf/bin/conda_entry.sh /conda_entry.sh
COPY ./conf/bin/conda_run.sh /conda_run.sh
COPY ./conf/bin/start-jupyter.sh /start-jupyter.sh

# fix permissions
RUN chmod 755 /conda_run.sh /conda_entry.sh /start-jupyter.sh
RUN chmod 644 /etc/bash.bashrc /etc/motd

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
#  AWS TOOLS INSTALLATION                              #
########################################################

## aws cli boto3 doesn't work with the urllib3 v2+
## aws cli will be installed globally across envs
## RUN apt install -y awscli
## RUN pip install 'urllib3<2' six


########################################################
#  CREATE JUPYTERLAB CONDA USER                        #
########################################################

## user to be used with conda
ENV CONDA_USER jupyterlab
ENV CONDA_USER_HOME /home/${CONDA_USER}

## create new user and add sudo rights
## also add group conda and add it to jupyterlab user
RUN useradd -ms /bin/bash ${CONDA_USER}
RUN adduser -q ${CONDA_USER} sudo

## update sudoers to allow jupyterlab sudo without password
RUN echo "${CONDA_USER} ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers.d/jupyterlab

## switch user to update config file
USER ${CONDA_USER}

## use predefined jupyter and other config files
COPY --chown=${CONDA_USER} ./conf/dot.jupyter ${CONDA_USER_HOME}/.jupyter
COPY --chown=${CONDA_USER} ./conf/dot.config  ${CONDA_USER_HOME}/.config
COPY --chown=${CONDA_USER} ./conf/dot.vimrc   ${CONDA_USER_HOME}/.vimrc


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

## install conda
#RUN curl https://repo.anaconda.com/pkgs/misc/gpgkeys/anaconda.asc | gpg --dearmor > conda.gpg \
# && install -o root -g root -m 644 conda.gpg /usr/share/keyrings/conda-archive-keyring.gpg \
# && gpg --keyring /usr/share/keyrings/conda-archive-keyring.gpg --no-default-keyring --fingerprint 34161F5BF5EB1D4BFBBB8F0A8AEB4F8B29D82806 \
# && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/conda-archive-keyring.gpg] https://repo.anaconda.com/pkgs/misc/debrepo/conda stable main" > /etc/apt/sources.list.d/conda.list
#RUN apt update && apt install conda -y 

## change ownership of conda folder to conda user
RUN chown -R ${CONDA_USER} /opt

## switch user to conda jupyterlab user
USER ${CONDA_USER}
WORKDIR ${CONDA_USER_HOME}

## set path to conda bin
ENV PATH $PATH:/opt/conda/bin

## install conda from miniconda archive from https://docs.anaconda.com/free/miniconda
RUN mkdir -p ~/miniconda3 \
 && wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda3/miniconda.sh \
 && bash ~/miniconda3/miniconda.sh -b -u -p /opt/conda \
 && rm -rf ~/miniconda3

## update conda system & install required packages from environment.yml
RUN conda install -n base -c conda-forge -y python=${CONDA_PYTHON_VERSION}
RUN conda update -n base -c defaults -y conda
RUN conda env update -n ${CONDA_DEFAULT_ENV:-base} -f /environment.yml 

## Tell the docker build process to use this for RUN.
## this script enables environment when used 
## with environment variable CONDA_DEFAULT_ENV=<environment_name>
SHELL ["/conda_run.sh"]

## Configure .bashrc to drop into a conda env and immediately activate our TARGET env
## Save CONDA_DEFAULT_ENV first, as it will be overwritten by conda init
RUN rm ~/.bashrc
RUN echo '# saving the conda environment, as conda init is going to reset this to "base"' >> ~/.bashrc
RUN echo '_CONDA_DEFAULT_ENV=${CONDA_DEFAULT_ENV:-base}' >>  ~/.bashrc
RUN conda init 
RUN echo '# restoring saved conda default env, as it was resetted to "base" by conda init' >> ~/.bashrc
RUN echo 'CONDA_DEFAULT_ENV=${_CONDA_DEFAULT_ENV:-base}' >>  ~/.bashrc
RUN echo 'conda activate "${CONDA_DEFAULT_ENV:-base}"' >>  ~/.bashrc

## merge bashrc files - conda generated and copied
COPY ./conf/dot.bashrc ${CONDA_USER_HOME}/dot.bashrc
RUN cat ${CONDA_USER_HOME}/dot.bashrc > ${CONDA_USER_HOME}/bashrc-to-merge
RUN cat ${CONDA_USER_HOME}/.bashrc >> ${CONDA_USER_HOME}/bashrc-to-merge
RUN mv  ${CONDA_USER_HOME}/bashrc-to-merge ${CONDA_USER_HOME}/.bashrc 
RUN rm  ${CONDA_USER_HOME}/dot.bashrc

## final update of the entire conda using conda-forge as preferred channel
RUN CONDA_DEFAULT_ENV=${CONDA_DEFAULT_ENV:-base} conda update -y -c conda-forge --all 


########################################################
#  NVIDIA CUDA & TENSORFLOW INSTALLATION               #
########################################################

## install nvidia-container-toolkit package to expose nvidia api to the container
## from: https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html
# RUN curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | \
#  sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
#  && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
#    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
#    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
# RUN sudo apt update && apt install -y nvidia-container-toolkit

## install cuda & tensorflow, using instructions https://docs.rapids.ai/install
## those packages need to be installed together as per rapids installation guide
#RUN CONDA_DEFAULT_ENV=${CONDA_DEFAULT_ENV:-base} conda install -y --solver=libmamba \ 
# -c rapidsai -c conda-forge -c nvidia  rapids=24.02 python=3.10 cuda-version=12.0 

## need to set CONDA_OVERRIDE_CUDA, see https://conda-forge.org/blog/2021/11/03/tensorflow-gpu/
ENV CONDA_OVERRIDE_CUDA=12.3

## install tensorflow using pip, conda tensorflow installation doesn't support cuda
## you can also install the nightly build: tf-nightly[and-cuda]
## installing tf-keras allows to use KERAS v2
RUN CONDA_DEFAULT_ENV=${CONDA_DEFAULT_ENV:-base} \ 
 pip install --upgrade tensorflow tf-keras tensorboard keras-cv keras_nlp keras-datasets \
 keras-tcn keras-self-attention keras-multi-head keras-mdn-layer 

## set env variables to disable tensorflow warnings and to enable new libstdc++.so.6
ENV TF_CPP_MIN_LOG_LEVEL 3

## install cuda accelerated numpy = cupy and conda-version
#RUN CONDA_DEFAULT_ENV=${CONDA_DEFAULT_ENV:-base} \ 
# conda install -y -c rapidsai -c conda-forge -c nvidia rapids cuda-version cupy cudf

## install torchvision and pytorch
## also install libgl1 to avoid issues with libGL missing
RUN sudo apt install -y libgl1-mesa-glx
RUN CONDA_DEFAULT_ENV=${CONDA_DEFAULT_ENV:-base} \ 
 conda install -y -c conda-forge 'pytorch>2=*cuda*' torchvision ultralytics


########################################################
#  FINAL UPDATE AND CLEANUP                            #
########################################################

## final round of updates to keep all up to date
RUN CONDA_DEFAULT_ENV=${CONDA_DEFAULT_ENV:-base} conda update -c conda-forge --all

## conda and pip cleanup
RUN CONDA_DEFAULT_ENV=${CONDA_DEFAULT_ENV:-base} conda clean -ltpy && pip cache purge

## apt cleanup
RUN sudo apt autoremove -y && sudo apt purge 


########################################################
#  PREPARE DOCKER CONTAINER ENTRY POINT                #
########################################################

## ignore pip warnings re root access
ENV PIP_ROOT_USER_ACTION ignore

## save build date for reference
COPY ./conf/misc/build-info.txt /
COPY ./conf/misc/motd-prototype.txt /
RUN sudo bash -c "date >/build-date.txt"
RUN sudo bash -c "gpw 1 4 | tr [:lower:] [:upper:] >/build-name.txt"
RUN sudo bash -c "cat /motd-prototype.txt | sed \"s/@BUILD_NAME@/$(cat /build-name.txt)/g\" | sed \"s/@BUILD_DATE@/$(cat /build-date.txt)/g\" > /etc/motd"

## update terminal and shell settings
ENV TERM xterm-256color

## setup entry point and
## command to run container with
ENTRYPOINT ["/conda_entry.sh"]
CMD ["/start-jupyter.sh"]

## expose jupyterlab and tensorboard by default
EXPOSE 8888/tcp
EXPOSE 6006/tcp

# EOF
