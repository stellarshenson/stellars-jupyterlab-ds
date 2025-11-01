#!/bin/bash
## Scaffolds new data science project based on cookiecutter

# create new project using cookiecutter
conda run --no-capture-output -n base cookiecutter https://github.com/stellarshenson/cookiecutter-data-science.git
