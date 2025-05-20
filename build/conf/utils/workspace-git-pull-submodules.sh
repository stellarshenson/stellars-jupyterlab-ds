#!/bin/sh

git submodule foreach '
  echo "==> $name"

  if ! git fetch; then
    echo "\033[31mFetch failed in $name\033[0m"
  elif git pull --rebase; then
    echo "\033[32mOk.\033[0m"
  else
    echo "\033[33mPull failed in $name\033[0m"
  fi
'

