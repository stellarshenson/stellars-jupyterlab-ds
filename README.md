docker run -p 8888:8888 \
 -v stellars-jupyterlab-ds_workspace:/home/lab/workspace \
 -v stellars-jupyterlab-ds_certs:/mnt/certs \
 --name stellars-jupyterlab-ds \
 --hostname jupyterlab \
 stellars/stellars-jupyterlab-ds:latest

 -v stellars-jupyterlab-ds_home:/home \
