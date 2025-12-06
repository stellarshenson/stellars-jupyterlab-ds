#!/bin/bash
## Scaffolds new data science project using Copier

REPO_URL="https://github.com/stellarshenson/cookiecutter-data-science.git"

# Get latest tag from GitHub
LATEST_TAG=$(git ls-remote --tags --sort=-v:refname "$REPO_URL" 2>/dev/null | head -n1 | sed 's/.*refs\/tags\///')

# Display template version (cyan)
if [ -n "$LATEST_TAG" ]; then
    echo -e "\033[36mUsing template version: $LATEST_TAG\033[0m"
fi

# Ask for project name (magenta bold)
echo -en "\033[1;35mEnter project name:\033[0m "
read PROJECT_NAME

if [ -z "$PROJECT_NAME" ]; then
    echo "Error: Project name cannot be empty"
    exit 1
fi

echo ""

# Create project using copier (project_name derived from folder name)
copier copy --trust "$REPO_URL" "$PROJECT_NAME"
