## this dockergfile is loosely based on the github project
## https://gist.github.com/xkortex/5ae49d7e6e969405bd2c3152a949c1f1
FROM continuumio/miniconda3 

# update sources list and increase timeouts
RUN cp /etc/apt/sources.list /etc/apt/sources.list.bak
COPY ./conf/sources.list /etc/apt/sources.list
COPY ./conf/apt /etc/apt

# install dependencies
RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y awscli git vim bash-completion mc curl sudo software-properties-common \ 
less gpw iputils-ping graphviz man gcc tree locate

## install nvidia CUDA and cuda suite
## set up nvidia repo https://docs.nvidia.com/datacenter/tesla/tesla-installation-notes/index.html
## no need to install cuda libs, we have conda packages pull what is required
RUN distribution=$(. /etc/os-release;echo $ID$VERSION_ID | sed -e 's/\.//g') && cd /tmp && \
wget https://developer.download.nvidia.com/compute/cuda/repos/$distribution/x86_64/cuda-keyring_1.0-1_all.deb && \
sudo add-apt-repository contrib && dpkg -i cuda-keyring_1.0-1_all.deb 
RUN sudo apt-get update 

# copy all config files and scripts
COPY ./conf/environment.yml /tmp/environment.yml
COPY ./conf/conda_entry.sh /conda_entry.sh
COPY ./conf/start-jupyterlab.sh /start-jupyterlab.sh
COPY ./conf/conda_run.sh /conda_run.sh
COPY ./conf/dot.config /root/.config
COPY ./conf/dot.vimrc /root/.vimrc
COPY ./conf/dot.bashrc /tmp/.bashrc
RUN chmod +x /conda_run.sh /conda_entry.sh /start-jupyterlab.sh

# prep for upgrades
RUN  mkdir -p /tmp/env_upgrade
COPY ./conf/Makefile /tmp/env_upgrade
COPY ./conf/requirements.keep /tmp/env_upgrade

## set up vim with all its plugins
RUN git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim && \
vim -E -S ~/.vimrc +PluginInstall +qall || echo ok

########################################################
#  CONDA JUPYTERLAB ENVIRONMENT INSTALLATION           #
########################################################

## Create jupyterlab env and ignore pip warnings
ENV PIP_ROOT_USER_ACTION ignore
ENV CONDA_DEFAULT_ENV jupyterlab

# install required packages. no need to create env, update will take care of it
# also clean unused space (give conda-forge the priority)
RUN conda env update -n ${CONDA_DEFAULT_ENV:-base} --solver=libmamba -f /tmp/environment.yml && \
conda list -n ${CONDA_DEFAULT_ENV:-base} > /tmp/environment.install.log && \
conda clean -ltpy && \ 
pip cache purge 


########################################################
#  ENABLING CONDA JUPYTERLAB ENVIRONMENT               #
########################################################

## Tell the docker build process to use this for RUN.
## this script enables environment when used 
## with environment variable CONDA_DEFAULT_ENV=<environment_name>
SHELL ["/conda_run.sh"]

## Configure .bashrc to drop into a conda env and immediately activate our TARGET env
## Save CONDA_DEFAULT_ENV first, as it will be overwritten by conda init
RUN echo '# saving the conda environment, as conda init is going to reset this to "base"' >> ~/.bashrc
RUN echo '_CONDA_DEFAULT_ENV=${CONDA_DEFAULT_ENV:-base}' >>  ~/.bashrc
RUN conda init 
RUN echo '# restoring saved conda default env, as it was resetted to "base" by conda init' >> ~/.bashrc
RUN echo 'CONDA_DEFAULT_ENV=${_CONDA_DEFAULT_ENV:-base}' >>  ~/.bashrc
RUN echo 'conda activate "${CONDA_DEFAULT_ENV:-base}"' >>  ~/.bashrc

## merge bashrc files - conda generated and copied
RUN cat /tmp/.bashrc > ~/bashrc-to-merge
RUN cat ~/.bashrc >> ~/bashrc-to-merge
RUN mv ~/bashrc-to-merge ~/.bashrc

## install playwright browsers and dependencies to enable 
## jupyter notebook export to webpdf with nbconvert
RUN CONDA_DEFAULT_ENV=${CONDA_DEFAULT_ENV:-base} playwright install-deps && playwright install

## upgrade environment
RUN CONDA_DEFAULT_ENV=${CONDA_DEFAULT_ENV:-base} cd /tmp/env_upgrade && \
make save_environment && make upgrade_environment 

########################################################
#  NVIDIA CUDA & TENSORFLOW INSTALLATION               #
########################################################

## install cuda & tensorflow, using instructions https://docs.rapids.ai/install
## those packages need to be installed together as per rapids installation guide
RUN CONDA_DEFAULT_ENV=${CONDA_DEFAULT_ENV:-base} conda install -y --solver=libmamba -c conda-forge \ 
-c rapidsai -c conda-forge -c nvidia python=3.10 rapids=23.12 cuda-version=11.8 && \
conda clean -ltpy && conda list -n ${CONDA_DEFAULT_ENV:-base} > /tmp/environment.install_nvidia.log

## install tensorflow using pip, conda tensorflow installation doesn't support cuda
RUN CONDA_DEFAULT_ENV=${CONDA_DEFAULT_ENV:-base} pip install --upgrade tensorflow[and-cuda] tensorboard 

## final update of the entire conda using conda-forge as preferred channel
RUN CONDA_DEFAULT_ENV=${CONDA_DEFAULT_ENV:-base} conda update -y -c conda-forge --all && \
conda clean -ltpy && pip cache purge 

## save build date for reference
RUN date >/build-date.txt
RUN gpw 1 4 | tr [:lower:] [:upper:] >/build-name.txt

## use predefined jupyter server config
COPY ./conf/dot.jupyter /root/.jupyter

## update terminal and shell settings
ENV TERM xterm-256color
ENTRYPOINT ["/conda_entry.sh"]

## start jupyterlab. otherwise
## you should put tail -f /dev/null
CMD ["/start-jupyterlab.sh"]

## expose jupyterlab and tensorboard by default
EXPOSE 8888/tcp
EXPOSE 6066/tcp

# EOF
