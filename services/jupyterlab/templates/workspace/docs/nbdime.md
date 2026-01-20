# Notebook Diffing and Merging with nbdime

This environment includes nbdime for diffing and merging Jupyter notebooks in git repositories. The jupyterlab-git extension provides visual git integration, while nbdime handles notebook-specific diff and merge operations.

## Commands

**Diff two notebooks:**
```bash
nbdiff notebook_1.ipynb notebook_2.ipynb
```

**Web-based diff viewer:**
```bash
nbdiff-web [<commit> [<commit>]] [<path>]
```

**Web-based merge tool:**
```bash
nbmerge-web base.ipynb local.ipynb remote.ipynb --out merged.ipynb
```

**Enable git integration (already configured):**
```bash
nbdime config-git --enable --global
```

**Use as git mergetool:**
```bash
git mergetool --tool=nbdime notebook.ipynb
```

## Reference

See the [Medium article on nbdime](https://medium.com/@k__lyda/how-to-merge-jupyter-notebooks-in-git-repo-without-a-headache-ca776bfc0795) for detailed usage examples.
