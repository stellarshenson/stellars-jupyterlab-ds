#!/bin/sh

git submodule update --remote
git submodule foreach '
  echo "==> $name"
  if ! git fetch; then
    echo "\033[31mFetch failed in $name\033[0m"
  else
    # Get the configured branch from .gitmodules
    branch=$(git config -f $toplevel/.gitmodules submodule.$name.branch)
    if [ -z "$branch" ]; then
      branch="main"  # or master, depending on your default
    fi
    
    # Ensure we are on the correct branch
    current_branch=$(git rev-parse --abbrev-ref HEAD)
    if [ "$current_branch" = "HEAD" ]; then
      echo "Detached HEAD detected, checking out $branch"
      git checkout $branch
    fi
    
    if git pull --rebase origin $branch; then
      echo "\033[32mOk.\033[0m"
    else
      echo "\033[33mPull failed in $name\033[0m"
    fi
  fi
'
