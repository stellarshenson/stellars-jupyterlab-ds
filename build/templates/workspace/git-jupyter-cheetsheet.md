# Jupyterlab integration with GIT
[stellars-jupyterlab-ds]() has been integrated with the jupyterlab notebook using `jupyterlab-git` extension, but additionally there is a tool that allows _diffing_ and _merging_ jupyter notebooks


## GIT integration with NBDIME

see [medium article on nbdime with git integration](https://medium.com/@k__lyda/how-to-merge-jupyter-notebooks-in-git-repo-without-a-headache-ca776bfc0795)

```
$ pip install nbdime

$ nbdiff notebook_1.ipynb notebook_2.ipynb

$ nbdiff-web [<commit> [<commit>]] [<path>]

$ nbmerge-web base.ipynb local.ipynb remote.ipynb --out merged.ipynb

$ nbdime config-git --enable --global

$ git mergetool --tool=nbdime biutiful_notebook.ipynb
```


