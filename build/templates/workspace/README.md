# Introduction

Welcome to stellars-jupyterlab-ds platform. This is your environment intended
for data science and machine learning / ai projects. You will find a lot of
packagages installed and configured for you in such way that it just works.

Running JupyterLab server on  https://localhost:8888
Connect VSCode to Jupyter on  https://localhost:8888/lab/tree
Running Tensorboard server on http://localhost:6006
Tensorboard monitoring logs located in `/tmp/tf_logs`
Using work dir (projects) `/home/lab/workspace` (mount)
Jupyterlab settings saved to `/home/lab/.jupyter`

Visit: https://github.com/stellarshenson/stellars-jupyterlab-ds

In the workspace you will find the following helpful tools:
- `workspace-git-*.sh`: help you keep workspace git projects up to date
- `test_cuda_tf_and_torch.sh`: test if tensorflow and pytorch can use your GPU
- `cookiecutter-new-project.sh`: create new data-science project using cookiecutter

There were many useful scientific and machine learning packages preinstalled
You can always verify which of them are available in the platform by executing:
$ conda list

There are by default three environments installed: base, tensorflow and torch
You can change active environment using:
`$ conda activate env_name`

Default conda environment is set by `CONDA_DEFAULT_ENV` environment variable
You can change it in the `docker-compose.yml` file or `~/.profile`

You can also find out about installed packages by inspecting manifest files:
`/environment_base.yml`, `/environment_tensorflow.yml` and `/environment_torch.yml`

Miniforge3 environment (conda) was installed in `/opt/conda`
Thanks to `nb_conda_kernels` extension, when you create new environment
it will be automatically available to you as a kernel in the jupyterlab environment

To execute commands as root use: `sudo`, password is: `password` unless changed


## Projects Workspace

- `cookiecutter-new-project.sh` - creates new project using enhanced cookiecutter datascience template
- `test_cuda_tf_and_torch.sh` - tests cuda components and GPU support
- `logger.py` - useful logging library for the notebooks
- `workspace-git-commit.sh` - runs git commit for all repos in the workspace
- `workspace-git-pull.sh` - runs git pull with rebase for all git repos in the workspace
- `workspace-git-push.sh` - runs git push for all git repos in the workspace
