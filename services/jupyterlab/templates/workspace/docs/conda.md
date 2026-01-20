# Conda Cheatsheet

## Quick Start

Create a new environment for any new project or workflow.

| Task | Command |
|------|---------|
| Verify conda install and check version | `conda info` |
| Update conda in base environment | `conda update -n base conda` |
| Create a new environment | `conda create --name ENVNAME` |
| Activate environment | `conda activate ENVNAME` |

## Channels and Packages

Package dependencies and platform specifics are automatically resolved when using conda.

| Task | Command |
|------|---------|
| List installed packages | `conda list` |
| List packages with source info | `conda list --show-channel-urls` |
| Update all packages | `conda update --all` |
| Install from specific channel | `conda install -c CHANNELNAME PKG1 PKG2` |
| Install specific version | `conda install PKGNAME=3.1.4` |
| Install with channel prefix | `conda install CHANNELNAME::PKGNAME` |
| Install with AND logic | `conda install "PKGNAME>2.5,<3.2"` |
| Install with OR logic | `conda install "PKGNAME [version='2.5\|3.2']"` |
| Uninstall package | `conda uninstall PKGNAME` |
| View channel sources | `conda config --show-sources` |
| Add channel | `conda config --add channels CHANNELNAME` |
| Set strict channel priority | `conda config --set channel_priority strict` |

## Working with Environments

List environments at the beginning of your session. Environments with an asterisk are active.

| Task | Command |
|------|---------|
| List all environments | `conda env list` |
| List packages in environment | `conda list -n ENVNAME --show-channel-urls` |
| Install packages in environment | `conda install -n ENVNAME PKG1 PKG2` |
| Remove package from environment | `conda uninstall PKGNAME -n ENVNAME` |
| Update all in environment | `conda update --all -n ENVNAME` |

## Environment Management

Specifying the environment name confines conda commands to that environment.

| Task | Command |
|------|---------|
| Create with Python version | `conda create -n ENVNAME python=3.10` |
| Clone environment | `conda create --clone ENVNAME -n NEWENV` |
| Rename environment | `conda rename -n ENVNAME NEWENVNAME` |
| Delete environment | `conda remove -n ENVNAME --all` |
| List revisions | `conda list -n ENVNAME --revisions` |
| Restore to revision | `conda install -n ENVNAME --revision NUMBER` |
| Remove package from channel | `conda remove -n ENVNAME -c CHANNELNAME PKGNAME` |

## Exporting Environments

Name the export file "environment" to preserve the environment name.

| Task | Command |
|------|---------|
| Cross-platform compatible | `conda env export --from-history > ENV.yml` |
| Platform + package specific | `conda env export ENVNAME > ENV.yml` |
| Platform + package + channel | `conda list --explicit > ENV.txt` |

## Importing Environments

When importing, conda resolves platform and package specifics.

| Task | Command |
|------|---------|
| From .yml file | `conda env create -n ENVNAME --file ENV.yml` |
| From .txt file | `conda create -n ENVNAME --file ENV.txt` |

## Additional Hints

| Task | Command |
|------|---------|
| Get help for any command | `conda COMMAND --help` |
| Get info for any package | `conda search PKGNAME --info` |
| Run without user prompt | `conda install PKG1 PKG2 --yes` |
| Remove all unused files | `conda clean --all` |
| Examine configuration | `conda config --show` |

## Resources

- [Conda Documentation](https://conda.io)
- [Anaconda Cloud](https://anaconda.cloud)
