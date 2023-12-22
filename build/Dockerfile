## this dockergfile is loosely based on the github project
## https://gist.github.com/xkortex/5ae49d7e6e969405bd2c3152a949c1f1
FROM continuumio/miniconda3 

# update sources list
RUN cp /etc/apt/sources.list /etc/apt/sources.list.bak
COPY ./conf/sources.list /etc/apt/sources.list

# install dependencies
RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y awscli git vim bash-completion mc curl sudo software-properties-common less

# chromium is required for nbconvert to webpdf -> turning notebooks to nice pdfs
RUN apt-get install -y chromium

## install nvidia CUDA and cuda suite
## ***************************************************
## 2023-12-22 note - cuda installation is not required to use cuda accelerated algorithms 
## like cudf or tensorflow. If anything changes - the container will have access to the 
## lates nvidia packages enabled with the nvidia repository. When you enable
## the docker to use gpu, tools like 'nvidia-smi' will be enabled anyway
## ***************************************************
## set up nvidia repo https://docs.nvidia.com/datacenter/tesla/tesla-installation-notes/index.html
## https://developer.nvidia.com/cuda-12-0-1-download-archive?target_os=Linux&target_arch=x86_64&Distribution=Debian&target_version=11&target_type=deb_network
RUN distribution=$(. /etc/os-release;echo $ID$VERSION_ID | sed -e 's/\.//g') && \
wget https://developer.download.nvidia.com/compute/cuda/repos/$distribution/x86_64/cuda-keyring_1.0-1_all.deb && \
sudo add-apt-repository contrib && \
dpkg -i cuda-keyring_1.0-1_all.deb 
# RUN sudo apt-get update && \
# sudo apt-get -y install cuda

# copy all config files and scripts
COPY ./conf/environment.yml /tmp/environment.yml
COPY ./conf/conda_entry.sh /conda_entry.sh
COPY ./conf/start-jupyterlab.sh /start-jupyterlab.sh
COPY ./conf/conda_run.sh /conda_run.sh
COPY ./conf/config /root/.config
COPY ./conf/vimrc /root/.vimrc
COPY ./conf/bashrc /tmp/.bashrc
RUN chmod +x /conda_run.sh /conda_entry.sh /start-jupyterlab.sh

## set up vim with all its plugins
RUN git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
RUN vim -E -S ~/.vimrc +PluginInstall +qall || echo ok

## Create jupyterlab env and ignore pip warnings
ENV PIP_ROOT_USER_ACTION ignore
ENV CONDA_DEFAULT_ENV jupyterlab

# install required packages. no need to create env, update will take care of it
# also update the packages
RUN conda env update -n ${CONDA_DEFAULT_ENV:-base} --solver=libmamba -f /tmp/environment.yml
RUN conda update -y -n ${CONDA_DEFAULT_ENV:-base} --all

## Tell the docker build process to use this for RUN.
SHELL ["/conda_run.sh"]

## Configure .bashrc to drop into a conda env and immediately activate our TARGET env
## Save CONDA_DEFAULT_ENV first, as it will be overwritten by conda init
RUN echo '# saving the conda environment, as conda init is going to reset this to "base"' >> ~/.bashrc
RUN echo '_CONDA_DEFAULT_ENV=${CONDA_DEFAULT_ENV:-base}' >>  ~/.bashrc
RUN conda init 
RUN echo '# restoring saved conda default env, as it was resetted to "base" by conda init' >> ~/.bashrc
RUN echo 'CONDA_DEFAULT_ENV=${_CONDA_DEFAULT_ENV:-base}' >>  ~/.bashrc
RUN echo 'conda activate "${CONDA_DEFAULT_ENV:-base}"' >>  ~/.bashrc

## merge bashrc files
RUN cp /tmp/.bashrc ~/bashrc-to-merge
RUN cat ~/.bashrc >> ~/bashrc-to-merge
RUN mv ~/bashrc-to-merge ~/.bashrc

ENV TERM xterm-256color
ENTRYPOINT ["/conda_entry.sh"]
CMD ["tail", "-f", "/dev/null"]

# EOF
