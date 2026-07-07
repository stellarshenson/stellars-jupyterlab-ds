Build helpers, normally driven by the repo-root Makefile (`make build` / `make build_verbose`), which exports `PKG_VERSION` before calling the `.sh` variants.

* `build.sh` - linux script to build the platform image
* `build.bat` - windows script to build the platform image
* `build_verbose.sh` - linux build with detailed BuildKit output (`--progress=plain`)
* `build_verbose.bat` - windows build with detailed BuildKit output (`--progress=plain`)
