## this dockergfile is loosely based on the github project
## https://gist.github.com/xkortex/5ae49d7e6e969405bd2c3152a949c1f1
FROM continuumio/miniconda3 as stage1
COPY ./conf/environment.yml /tmp/environment.yml
COPY ./conf/conda_entry.sh /conda_entry.sh
COPY ./conf/start-jupyterlab.sh /start-jupyterlab.sh
COPY ./conf/conda_run.sh /conda_run.sh
COPY ./conf/config /root/.config
COPY ./conf/vim /root/.vim
COPY ./conf/vimrc /root/.vimrc
COPY ./conf/bashrc /tmp/.bashrc

RUN chmod +x /conda_run.sh /conda_entry.sh /start-jupyterlab.sh
RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y awscli git vim bash-completion mc


FROM stage1 as anaconda-jupyterlab

## Create jupyterlab env
# ENV CONDA_DEFAULT_ENV jupyterlab
ENV CONDA_DEFAULT_ENV jupyterlab

# install required packages. no need to create env, update will take care of it
# RUN conda create --solver=libmamba -n ${CONDA_DEFAULT_ENV:-base} python=3.10 
RUN conda env update -n ${CONDA_DEFAULT_ENV:-base} --solver=libmamba -f /tmp/environment.yml
RUN conda info

## Tell the docker build process to use this for RUN.
SHELL ["/conda_run.sh"]

## Configure .bashrc to drop into a conda env and immediately activate our TARGET env
RUN conda init && echo 'conda activate "${CONDA_DEFAULT_ENV:-base}"' >>  ~/.bashrc

## merge bashrc files
RUN cp /tmp/.bashrc ~/bashrc-to-merge
RUN cat ~/.bashrc >> ~/bashrc-to-merge
RUN mv ~/bashrc-to-merge ~/.bashrc

ENV TERM xterm-256color
ENTRYPOINT ["/conda_entry.sh"]
CMD ["tail", "-f", "/dev/null"]

# EOF
