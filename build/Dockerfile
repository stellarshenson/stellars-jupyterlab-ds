## this dockergfile is loosely based on the github project
FROM tensorflow/tensorflow:latest-gpu

# update sources list and increase timeouts
COPY ./conf/apt /etc/apt

# install dependencies
RUN apt update && apt upgrade -y
RUN apt install -y git vim bash-completion mc curl sudo software-properties-common \ 
 less gpw gpg iputils-ping graphviz man gcc tree locate git zip

# copy all config files and scripts
COPY ./conf/dot.config /root/.config
COPY ./conf/dot.vimrc /root/.vimrc
COPY ./conf/dot.bashrc /tmp/dot.bashrc
COPY ./conf/bash.bashrc /etc/bash.bashrc
COPY ./conf/environment.yml /environment.yml
COPY ./conf/bin/conda_entry.sh /conda_entry.sh
COPY ./conf/bin/conda_run.sh /conda_run.sh
COPY ./conf/bin/start-jupyter.sh /start-jupyter.sh

## use predefined jupyter server config
COPY ./conf/dot.jupyter /root/.jupyter

# make run scripts executable
RUN chmod +x /conda_run.sh /conda_entry.sh /start-jupyter.sh

## set up vim with all its plugins
RUN git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim \
 && vim -E -S ~/.vimrc +PluginInstall +qall || echo ok


########################################################
#  AWS TOOLS INSTALLATION                              #
########################################################

# aws cli boto3 doesn't work with
# the urllib3 v2+, need to downgrade
RUN apt install -y awscli 
RUN pip install 'urllib3<2'

########################################################
#  CONDA JUPYTERLAB ENVIRONMENT INSTALLATION           #
########################################################

## Create jupyterlab env and ignore pip warnings
ENV CONDA_DEFAULT_ENV jupyterlab

## install conda
RUN curl https://repo.anaconda.com/pkgs/misc/gpgkeys/anaconda.asc | gpg --dearmor > conda.gpg \
 && install -o root -g root -m 644 conda.gpg /usr/share/keyrings/conda-archive-keyring.gpg \
 && gpg --keyring /usr/share/keyrings/conda-archive-keyring.gpg --no-default-keyring --fingerprint 34161F5BF5EB1D4BFBBB8F0A8AEB4F8B29D82806 \
 && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/conda-archive-keyring.gpg] https://repo.anaconda.com/pkgs/misc/debrepo/conda stable main" > /etc/apt/sources.list.d/conda.list
RUN apt update && apt install conda -y 
ENV PATH $PATH:/opt/conda/bin

# update conda system
# install required packages. no need to create env, update will take care of it
# also clean unused space (give conda-forge the priority)
RUN conda update -n base -c defaults conda -y
RUN conda env update -n ${CONDA_DEFAULT_ENV:-base} -f /environment.yml \
 && conda clean -ltpy && pip cache purge 

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
RUN cat /tmp/dot.bashrc > ~/bashrc-to-merge
RUN cat ~/.bashrc >> ~/bashrc-to-merge
RUN mv ~/bashrc-to-merge ~/.bashrc

## install playwright browsers and dependencies to enable 
## jupyter notebook export to webpdf with nbconvert
# RUN CONDA_DEFAULT_ENV=${CONDA_DEFAULT_ENV:-base} playwright install-deps && playwright install

## final update of the entire conda using conda-forge as preferred channel
RUN CONDA_DEFAULT_ENV=${CONDA_DEFAULT_ENV:-base} conda update -y -c conda-forge --all \
 && conda clean -ltpy && pip cache purge 

########################################################
#  INSTRALLING PIP PACKAGES FROM REQUIREMENTS          #
########################################################

# upgrade pip and install all reqs
#RUN pip install --upgrade pip
#RUN pip install --upgrade -r /requirements.txt -c /constraints.txt && pip cache purge

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
# -c rapidsai -c conda-forge -c nvidia  rapids=24.02 python=3.10 cuda-version=12.0 && \
# conda clean -ltpy

## install tensorflow using pip, conda tensorflow installation doesn't support cuda
## you can also install the nightly build: tf-nightly[and-cuda]
## installing tf-keras allows to use KERAS v2
RUN CONDA_DEFAULT_ENV=${CONDA_DEFAULT_ENV:-base} \ 
 pip install --upgrade tensorflow tf-keras tensorboard keras-cv keras_nlp keras-datasets \
 keras-tcn keras-self-attention keras-multi-head keras-mdn-layer \
 && pip cache purge

## install cuda accelerated numpy = cupy and conda-version
# RUN CONDA_DEFAULT_ENV=${CONDA_DEFAULT_ENV:-base} \ 
#  conda install -y -c rapidsai -c conda-forge -c nvidia rapids cuda-version cupy cudf


## install torchvision and pytorch
## also install libgl1 to avoid issues with libGL missing
## need to set CONDA_OVERRIDE_CUDA, see https://conda-forge.org/blog/2021/11/03/tensorflow-gpu/
RUN apt install -y libgl1-mesa-glx
RUN CONDA_DEFAULT_ENV=${CONDA_DEFAULT_ENV:-base} CONDA_OVERRIDE_CUDA="12.3" \ 
 conda install -y -c conda-forge 'pytorch>2=*cuda*' torchvision ultralytics


########################################################
#  PREPARE DOCKER CONTAINER ENTRY POINT                #
########################################################

## set env variables to disable tensorflow warnings and to enable new libstdc++.so.6
ENV TF_CPP_MIN_LOG_LEVEL 3
ENV PIP_ROOT_USER_ACTION ignore

## working directory for jupyterlab
ENV WORKSPACE_DIR /opt/workspace

## save build date for reference
RUN date >/build-date.txt
RUN gpw 1 4 | tr [:lower:] [:upper:] >/build-name.txt

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

