# stellars-jupyterlab-ds
Miniconda + Jupyterlab for Data Science

### installation

Installation is dependent on the docker software installed.
Jupyterlab 4 is going to be availabe via container and will
be completely isolated from the rest of the computer's software

There will be software required to be installed in order to run this:

1. docker desktop - this software comes with the docker-compose required to run the container
2. docker-compose (comes with docker desktop)

1. install [docker desktop software](https://www.docker.com/products/docker-desktop/)
2. run `./bin/build.sh` to build the containers
3. run `./bin/start.sh` to run jupyterlab without nvidia GPU acceleration
4. run `./bin/start_nvidia.sh` to run jupyterlab **with** nvidia GPU acceleration
5. access [](http://localhost:8888) to run jupyterlab


