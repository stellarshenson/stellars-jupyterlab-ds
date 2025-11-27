#!/bin/bash
## Scaffolds new data science project based on cookiecutter

# create new project using ccds (cookiecutter-data-science)
conda run --no-capture-output -n base ccds ${COOKIECUTTER_DATASCIENCE_TEMPLATE_URL} --checkout master
