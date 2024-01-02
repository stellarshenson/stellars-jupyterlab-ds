# stellars-jupyterlab-ds
Miniconda + Jupyterlab for Data Science
This project defines a pre-packaged, pre-configured jupyterlab running over miniconda with nvidia support and 
a list of pre-installed data science packages that would let you run your data science projects in a snap

### About me
Name: Konrad Jelen (aka stellars henson) <konrad.jelen+github@gmail.com>  
Linked-in: https://www.linkedin.com/in/konradjelen/

### Installation

Installation is dependent on the docker software installed.
Jupyterlab 4 is going to be availabe via container and will
be completely isolated from the rest of the computer's software

Docker hub repository: https://hub.docker.com/repository/docker/stellars/stellars-jupyterlab-ds/general

There will be software required to be installed in order to run this:

1. docker desktop - this software comes with the docker-compose required to run the container
2. docker-compose - comes with the docker-desktop software
3. install [docker desktop software](https://www.docker.com/products/docker-desktop/)

<div class="alert alert-block alert-info">
<b>Tip:</b> you don't need to run `docker-compose build` if you pull the docker image from the docker hub. 
  When you run `docker-compose up` for the first time docker will find out if you can use prebuilt package
</div>

### Usage

1. run `docker-compose build` followed by `docker-compose up` to run the container
2. access http://localhost:8888 to run jupyterlab

**Tip:** modify the `/opt/workspace` entry in the `volumes:` section of the
docker-compose files to map to a different projects location in your filesystem

### Configuration

- **./home** folder has the files and other folders that you wish to have in the home directory in the container. This would be your `.aws` folder with the account config and credentials, it would be your `.gitconfig` file and also `.jupyter` folder with the jupyterlab settings
- **./workspace** this is the default folder where jupyterlab will look for projects and save its notebooks. You can change this folder to another via mapping in the `docker-compose.yml` files 
- **./build** contains container build artefacts, you wouldn't need to look there


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
* configurable mapping to your filesystem folder that holds your projects
* configurable settings files and folders used in __jupyterlab__, such as AWS credentials, GIT settings and jupyterlab settings, so that when you decide to shred the container and run it anew again, you can be sure your settings were saved
