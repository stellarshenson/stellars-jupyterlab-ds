# Jupyterlab for Data Science Platform
Miniconda + Jupyterlab for Data Science
This project defines a pre-packaged, pre-configured jupyterlab running over miniconda with nvidia support and 
a list of pre-installed data science packages that would let you run your data science projects in a snap

![](./doc/jupyterlab.png)

<!-- ![](./doc/jupyterlab-launcher.png) -->

![](./doc/docker-desktop.png)

There were many jupyterlab features installed, among them:
- jupyterlab-git extension
- jupyterlab-lsp language servers (python) extension
- autocompletion and code suggests with documentation
- variable inspector
- resource usage monitor

for the complete list of packages, please see [packages manifest](https://github.com/stellarshenson/stellars-jupyterlab-ds/blob/main/build/conf/environment.yml). It is frequently updated to promote best tools that can help you with the development

There also is a Tensorboard server running on `6006` port and `/tmp/tf_logs` logs directory to help you with your ML/AI development and tensorflow neural nets training monitoring

### About me
Name: Konrad Jelen (aka stellars henson) <konrad.jelen+github@gmail.com>  
Linked-in: https://www.linkedin.com/in/konradjelen/

### Installation

Installation is dependent on the docker software installed.
Jupyterlab 4 is going to be availabe via container and will
be completely isolated from the rest of the computer's software

Docker hub repository: https://hub.docker.com/repository/docker/stellars/stellars-jupyterlab-ds/general

There will be software required to be installed in order to run this:

1. [docker desktop](https://www.docker.com/products/docker-desktop/) - this software comes with the docker-compose required to run the container
2. `docker-compose` command - comes with the docker-desktop software

### Usage

1. run `docker-compose pull` in the main folder to download the latest container image 
2. run `docker-compose up` in the main folder to run the container
3. access http://localhost:8888 to run JupyterLab
4. access http://localhost:6006 to run Tensorboard

**Tip:** you don't need to run `docker-compose build` if you pull the docker image from the docker hub. When you run `docker-compose up` for the first time docker will find out if you can use prebuilt package 

### Configuration

- **./home** folder has the files and other folders that you wish to have in the home directory in the container. This would be your `.aws` folder with the account config and credentials, it would be your `.gitconfig` file and also `.jupyter` folder with the jupyterlab settings
- **./workspace** this is the default folder where jupyterlab will look for projects and save its notebooks. You can change this folder to another via mapping in the `docker-compose.yml` files 
- **./build** contains container build artefacts, you wouldn't need to look there

**Tip:** modify the `/opt/workspace` entry in the `volumes:` section of the<br>docker-compose files to map to a different projects location in your filesystem 

### Features
* jupyterlab 4+ (see [jupyterlab homepage](https://jupyterlab.readthedocs.io/en/latest) for reference)
* git, autocomplete and other extensions to jupyterlab
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
* nice intellij dark theme (medium contrast)
* favourites (useful when you have many projects)
* nice colourful termina + mc and other useful tools
* __tensorboard__ (already configured and running on port 6006)
* tensorflow visualisation extensions

<!-- EOF -->
