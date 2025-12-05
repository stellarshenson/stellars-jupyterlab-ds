#!/bin/bash
## Scaffolds new data science project using Copier

# Ask for project name (magenta bold)
echo -en "\033[1;35mEnter project name:\033[0m "
read PROJECT_NAME

if [ -z "$PROJECT_NAME" ]; then
    echo "Error: Project name cannot be empty"
    exit 1
fi

echo ""

# Create project using copier (project_name derived from folder name)
copier copy --trust \
    https://github.com/stellarshenson/cookiecutter-data-science.git \
    "$PROJECT_NAME"
