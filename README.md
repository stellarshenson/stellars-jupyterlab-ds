# stellars-jupyterlab-ds
Miniconda + Jupyterlab for Data Science

##### About me
Name: Konrad Jelen (aka stellars henson) <konrad.jelen+github@gmail.com>
Linked-in: https://www.linkedin.com/in/konradjelen/

### Installation

Installation is dependent on the docker software installed.
Jupyterlab 4 is going to be availabe via container and will
be completely isolated from the rest of the computer's software

There will be software required to be installed in order to run this:

1. docker desktop - this software comes with the docker-compose required to run the container
2. docker-compose - comes with the docker-desktop software
3. install [docker desktop software](https://www.docker.com/products/docker-desktop/)


### Usage

1. run `docker-compose build` followed by `docker-compose up` to run the container
2. access http://localhost:8888 to run jupyterlab

<div class="alert alert-block alert-info">
<b>Tip:</b> modify the `/opt/workspace` entry in the `volumes:` section of the
docker-compose files to map to a different projects location in your filesystem </div>


### Features
* jupyterlab 4.0.9
* lsp extensions for python autocompletion
* full set of ML libraries: keras, tensorflow, scikit-learn, scipy, numpy
* full set of DM libraries pandas, polars
* full set of graphs libraries matplotlib, seaborn
* nvidia cuda enabled ML and DM libraries - cupy, cudf and tensorflow with gpu support
* miniconda with nice jupyterlab terminal support
* html and pdf (webpdf) generation support
* memory profiler
* mapping to your filesystem folder that holds your projects
