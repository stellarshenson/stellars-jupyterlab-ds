# Acceptance Criteria - Platform

stellars-jupyterlab-ds is a containerized JupyterLab data-science platform served behind Traefik and shipped as a versioned Docker image. This document records platform-wide acceptance criteria; most sections are scaffolded and filled in over time, with the Lab Utilities tool detailed in full below.

## Contents

- [Access and Routing](#access-and-routing)
- [Image Build and Versioning](#image-build-and-versioning)
- [Container Startup](#container-startup)
- [Integrated Services](#integrated-services)
- [Persistence and Volumes](#persistence-and-volumes)
- [GPU Support](#gpu-support)
- [Branding and Configuration](#branding-and-configuration)
- [Security and Sudo](#security-and-sudo)
- [Extensions](#extensions)
- [Terminal UX](#terminal-ux)
- [Lab Utilities](#lab-utilities)
  - [Packaging](#packaging)
  - [Install and Overlay](#install-and-overlay)
  - [Module Structure](#module-structure)
  - [CLI Parity](#cli-parity)
  - [Data Discovery](#data-discovery)
  - [TUI](#tui)
  - [CLI Styling](#cli-styling)
  - [Tests and Test Data](#tests-and-test-data)
  - [Completions](#completions)
  - [Compatibility and Edges](#compatibility-and-edges)

## Access and Routing

- [x] **Host routing** - `https://lab.<project>.localhost` reaches JupyterLab (jupyter-server redirects `/` -> `/lab`); host derives from `COMPOSE_PROJECT_NAME`
  - log: 2026-07-02 criterion added with the host-based routing switch
  - log: 2026-07-02 verified live - curl 302 -> /lab, override project renders Host(`lab.my-lab.localhost`) (v3.8.11)
- [x] **Dashboard host** - `https://traefik.<project>.localhost` serves the traefik dashboard via `api@internal` over TLS
  - log: 2026-07-02 verified live - /dashboard/ 200 over TLS (v3.8.11)
- [x] **Proxied services** - mlflow, tensorboard, rmonitor, optuna reachable under the lab host via jupyter-server-proxy (`/mlflow`, `/tensorboard`, `/rmonitor`, `/optuna`, `/proxy/<port>/`)
  - log: 2026-07-02 verified live - /mlflow /tensorboard /rmonitor answer under the lab host; optuna same mechanism, not running by default (v3.8.11)
- [x] **Cert SANs** - generated cert carries `DNS:localhost`, `DNS:*.localhost`, `DNS:*.<project>.localhost`, `IP:127.0.0.1`, `IP:::1`; CN `lab.<project>.localhost`
  - log: 2026-07-02 verified live - openssl s_client shows all five SANs and the CN from the rebuilt image (v3.8.11)
- [x] **Cert regen guard** - cert regenerates when missing or when the `*.<project>.localhost` SAN is absent (pre-SAN volume or project rename); untouched otherwise
  - log: 2026-07-02 verified live - stale SAN-less volume regenerated on start; md5 unchanged across a further restart (v3.8.11)
- [x] **Configurable port** - `LAB_PORT` (default 443) sets the published HTTPS port; access URL gains `:<port>` only when != 443
  - log: 2026-07-02 verified live - platform served on LAB_PORT=8443 alongside the workbench stack holding :443 (v3.8.11)
- [x] **Env layering** - `.env.default` (tracked defaults) + `.env` (gitignored overrides incl. `JUPYTERLAB_SERVER_TOKEN`); every compose invocation passes both env-files
  - log: 2026-07-02 verified - compose config with both files, later file wins; start/stop/Makefile/installers all pass both (v3.8.11)
- [x] **Legacy variant removed** - path-based `compose-old.yml` dropped; host-based routing is the sole compose configuration
  - log: 2026-07-02 verified - compose config clean for compose-old.yml and the GPU overlay (v3.8.11)
  - log: 2026-07-03 compose-old.yml removed - legacy path-based variant retired, host-based is the only delivery (v3.9.1)
- [x] **Edge: stale cert volume** - existing `vol_certs` from a pre-SAN deployment regenerates on next start without manual volume removal
  - log: 2026-07-02 verified live - old-image cert migrated on container recreate, traefik serves the SAN cert after its (ordered) start (v3.8.11)
- [x] **Edge: project rename** - changing `COMPOSE_PROJECT_NAME` regenerates the cert with the new wildcard SAN and moves both hosts to the new namespace
  - log: 2026-07-02 verified - guard regen path proven for SAN-mismatch (rename = same path); renamed hosts render in compose config (v3.8.11)

## Image Build and Versioning

- [ ] **Versioning** - image tag derives from the pyproject version plus the cuda and jupyterlab versions; make build and rebuild produce a consistent tag; criteria to be detailed
  - log: 2026-06-21 section scaffolded

## Container Startup

- [ ] **Startup** - start-platform.sh sources platform.env and runs the start-platform.d scripts in order; criteria to be detailed
  - log: 2026-06-21 section scaffolded

## Integrated Services

- [ ] **Services** - MLflow, TensorBoard, Optuna and the resources monitor start when enabled and are reachable on their proxy routes; criteria to be detailed
  - log: 2026-06-21 section scaffolded

## Persistence and Volumes

- [ ] **Persistence** - home, workspace and cache volumes retain user data across container restart and image rebuild; criteria to be detailed
  - log: 2026-06-21 section scaffolded

## GPU Support

- [ ] **GPU** - ENABLE_GPU_SUPPORT toggles NVIDIA passthrough and CUDA is usable in notebooks when enabled; criteria to be detailed
  - log: 2026-06-21 section scaffolded

## Branding and Configuration

- [ ] **Branding** - JUPYTERLAB_SYSTEM_NAME rebrands welcome, MOTD and toolbar badge, logo and splash URIs apply, and config env vars take effect; criteria to be detailed
  - log: 2026-06-21 section scaffolded

## Security and Sudo

- [ ] **Sudo gate** - JUPYTERLAB_SUDO_ENABLE=0 hard-denies sudo at container start; criteria to be detailed
  - log: 2026-06-21 section scaffolded

## Extensions

- [ ] **Extension manager** - the manager backend honours the readonly env gate and ships dormant by default with no PyPI traffic; criteria to be detailed
  - log: 2026-06-21 section scaffolded

## Terminal UX

- [ ] **Terminal** - the resources-monitor terminal sizes correctly on load and terminal tabs carry meaningful titles; criteria to be detailed
  - log: 2026-06-21 section scaffolded

## Lab Utilities

The lab-utils terminal menu is refactored into an installable `duoptimum-lab-utils` Python package, pip-installed into the conda base environment and exposed as a `lab-utils` overlay command that runs from any active conda environment. The tool keeps its YAML-driven menu and CLI, gains Duoptimum styling, modular code and a test suite.

### Packaging

- [x] **Package layout** - code lives in services/jupyterlab/duoptimum-lab-utils as an importable duoptimum_lab_utils package with a pyproject.toml
  - log: 2026-06-21 criterion added
  - log: 2026-06-21 verified - importable package + pyproject present, lab-utils --help runs from a fresh install
- [x] **Version** - package version matches the lab platform version from pyproject project.version, not an independent number
  - log: 2026-06-21 criterion added
  - log: 2026-06-21 verified - installed dist version 3.8.8 equals the root platform pyproject version, dynamic from _version.txt stamped by the builder
  - log: 2026-06-22 make increment_version now also writes the bumped version into src/duoptimum_lab_utils/_version.txt (Makefile LAB_UTILS_VERSION_FILE) so the committed package version tracks the platform even in dev installs, not only at image build; _version.txt synced to the current platform version (no longer the 0.0.0 placeholder); guarded by test_version.py
- [x] **Entry point** - pyproject [project.scripts] defines lab-utils -> duoptimum_lab_utils.cli:main
  - log: 2026-06-21 criterion added
  - log: 2026-06-21 verified - console script installed and runs from the throwaway venv
- [x] **No dep churn** - the wheel installs with --no-deps so the base env's textual, rich and pyyaml are neither upgraded nor downgraded; pyproject declares all three and they match environment_base.yml
  - log: 2026-06-21 criterion added (as "Pinned deps")
  - log: 2026-06-21 reworded to the --no-deps mechanism and verified - deps align with environment_base.yml, install is --no-deps (architect census aligned)
  - log: 2026-06-22 pinned textual>=2 (tui adversary finding) - the menu highlight index relies on textual 2.x's add_option(None) separator model; a lower bound stops a constrained dev resolver pulling the pre-2.0 separator that breaks highlighted=1; base ships 8.2.7 so no churn
- [x] **Bundled data** - lab-utils.yml, lab-utils.d/ and lab-utils.lib/ ship as package data or as deployment files at a known path, discoverable without __file__ assumptions
  - log: 2026-06-21 criterion added
  - log: 2026-06-21 verified - data resolves via config.data_home() (/opt/utils default), not __file__; JSON parity confirms discovery

### Install and Overlay

- [x] **Wheel build** - the package is built into a wheel in the Dockerfile builder stage
  - log: 2026-06-21 criterion added
  - log: 2026-06-21 verified - builder runs pip wheel --no-deps; wheel built and installed locally with the stamped version
- [x] **Target install** - the target stage installs the built wheel into the conda base env at /opt/conda via the established conda run pip pattern, creating /opt/conda/bin/lab-utils
  - log: 2026-06-21 criterion added
  - log: 2026-06-21 in progress - Dockerfile target installs via conda run -n base pip (verified by inspection + architect trace); runtime confirmation pending make build
  - log: 2026-06-21 verified in image (make rebuild) - /opt/conda/bin/lab-utils present, shebang #!/opt/conda/bin/python3.13, importlib.metadata reports 3.8.8
- [x] **No retained wheel** - the wheel is not kept in the final image after installation
  - log: 2026-06-21 criterion added
  - log: 2026-06-21 in progress - Dockerfile rm -rf /tmp/duoptimum-wheel present; absence in the final image pending make build
  - log: 2026-06-21 verified in image - /tmp/duoptimum-wheel absent in the rebuilt :latest image
- [x] **Dockerfile standards** - the build and install steps follow existing Dockerfile conventions: builder and target multi-stage split, COPY --chmod, RUN heredoc blocks, and conda run -n base pip
  - log: 2026-06-21 criterion added
  - log: 2026-06-21 verified - builder/target split, RUN heredocs, conda run -n base pip, COPY --from=builder; architect re-confirm CLEAN
- [x] **Overlay command** - lab-utils on PATH resolves to the base-env console script
  - log: 2026-06-21 criterion added
  - log: 2026-06-21 in progress - architect traced the /opt/utils PATH prepend + symlink -> /opt/conda/bin/lab-utils end-to-end; runtime resolution pending make build
  - log: 2026-06-21 verified in image - /opt/utils/lab-utils is a symlink to /opt/conda/bin/lab-utils; `which lab-utils` resolves it and `lab-utils --json/--list` run against base
- [x] **Launcher tile** - the JupyterLab launcher tile still starts the menu via /opt/utils/launch-lab-utils.sh calling lab-utils
  - log: 2026-06-21 criterion added
  - log: 2026-06-21 verified - launch-lab-utils.sh unchanged, invokes the lab-utils command (name preserved)
- [x] **PATH untouched** - the /opt/utils PATH prepend in /etc/default/platform.env stays as is and needs no new edits
  - log: 2026-06-21 criterion added
  - log: 2026-06-21 verified - platform.env /opt/utils prepend unchanged, no edits
- [x] **Edge: active non-base env** - after conda activate of another env, lab-utils still launches and runs against the base-env interpreter
  - log: 2026-06-21 criterion added
  - log: 2026-06-21 in progress - architect confirmed reachability after conda activate via PATH + absolute-shebang trace; runtime launch pending make build
  - log: 2026-06-21 verified in image - with PATH=/opt/utils:/usr/bin:/bin (base bin /opt/conda/bin OFF PATH, the conda-activate-other-env case), lab-utils resolves via /opt/utils and runs base python (--json global:21); the #!/opt/conda/bin/python3.13 shebang pins base regardless of active env
- [x] **Edge: reinstall** - rebuilding the image reinstalls cleanly with no stale entry point or duplicate script
  - log: 2026-06-21 criterion added
  - log: 2026-06-21 in progress - old monolith deleted, no bare-script conflict (architect confirmed); clean reinstall pending make build
  - log: 2026-06-21 verified in image - rebuild over the prior 24h-old image: old monolith file gone, /opt/utils/lab-utils is the fresh symlink, single console script, no duplicate

### Module Structure

- [x] **Split** - the monolith is split into focused modules: theme and palette, menu loader, script resolver, TUI menu app, selector, CLI dispatch
  - log: 2026-06-21 criterion added
  - log: 2026-06-21 verified - theme/config/resolver/menu/selectors/tui/cli modules; architect confirmed clean boundaries, no UI-in-logic leakage
- [x] **No behaviour change** - the split preserves current runtime behaviour, structure changes only
  - log: 2026-06-21 criterion added
  - log: 2026-06-21 verified - byte-exact JSON parity and exit-code parity against the recovered monolith

### CLI Parity

- [x] **Help** - lab-utils --help and -h print usage as today
  - log: 2026-06-21 criterion added
  - log: 2026-06-21 verified - --help/-h print usage
- [x] **List** - lab-utils --list and -l print the script tree
  - log: 2026-06-21 criterion added
  - log: 2026-06-21 verified - --list/-l print the script tree
- [x] **JSON** - lab-utils --json prints machine-readable output unchanged in shape
  - log: 2026-06-21 criterion added
  - log: 2026-06-21 verified - --json is byte-for-byte identical to the monolith (6610 bytes, empty diff on the same data root)
- [x] **Create local** - lab-utils --create-local scaffolds ~/.local/lab-utils.d with the demo script
  - log: 2026-06-21 criterion added
  - log: 2026-06-21 verified - covered by the cli test suite
- [x] **Direct run** - lab-utils name and lab-utils parent/child execute the resolved script and propagate its exit code
  - log: 2026-06-21 criterion added
  - log: 2026-06-21 verified - resolves and runs the script, propagates the exit code (parity check)
- [x] **No-arg menu** - lab-utils with no arguments opens the interactive menu
  - log: 2026-06-21 criterion added
  - log: 2026-06-21 verified - cli dispatch + headless TUI render of the menu screen
- [x] **Edge: unknown script** - lab-utils with a missing script name exits non-zero with the not-found message
  - log: 2026-06-21 criterion added
  - log: 2026-06-21 verified - exits non-zero with the not-found message (parity: both exit 1; message on stdout, matching the monolith)
  - log: 2026-06-21 redesigned - fatal errors routed to stderr via _die() (architect MINOR; good design over strict parity); exit code and message text unchanged, JSON unaffected; cli test asserts stderr
- [x] **Edge: unknown option** - an unrecognised flag exits non-zero with usage guidance
  - log: 2026-06-21 criterion added
  - log: 2026-06-21 verified - unrecognised flag exits non-zero with usage (cli test)
  - log: 2026-06-21 redesigned - unknown-option error routed to stderr via the same _die() canonical path; cli test asserts stderr

### Data Discovery

- [x] **Deployment paths** - menu config and the global and lib script dirs are found at their deployment location, not relative to the package install dir
  - log: 2026-06-21 criterion added
  - log: 2026-06-21 verified - config paths resolve from the data root, not the package dir; resolver tests + parity
- [x] **Env override** - an env var can point the tool at an alternate menu config or script root for testing and custom deployments
  - log: 2026-06-21 criterion added
  - log: 2026-06-21 verified - DUOPTIMUM_LAB_UTILS_HOME redirects discovery (used by the suite and the parity run)
- [x] **Aux menu** - JUPYTERLAB_AUX_MENU_PATH injection still adds the Auxiliary Menu submenu, executables as items and yaml files as submenus
  - log: 2026-06-21 criterion added
  - log: 2026-06-21 verified - injection order covered by the loader tests
- [x] **User scripts** - ~/.local/lab-utils.d is scanned for user scripts
  - log: 2026-06-21 criterion added
  - log: 2026-06-21 corrected - dropped the extra-env.d clause (neither monolith nor package scans it); verified ~/.local/lab-utils.d scanning
- [x] **Edge: missing data dir** - absent global, lib or local dirs yield an empty section rather than a crash
  - log: 2026-06-21 criterion added
  - log: 2026-06-21 verified - absent dirs yield an empty section, no crash (tests)

### TUI

- [x] **Palette** - both the menu and selector screens use the Duoptimum palette of cyan and orange on dark slate, not Textual default theme tokens
  - log: 2026-06-21 criterion added
  - log: 2026-06-21 verified - headless render asserts DUO hexes present on both screens
- [x] **Header bar** - a one-row header shows the app name on the left and the platform version in the right corner
  - log: 2026-06-21 criterion added
  - log: 2026-06-21 verified - header shows app name left, version right-corner (render test)
- [x] **No glyphs** - item type is conveyed by colour and text label, never pictographic unicode; the legacy triangle, diamond, bullet, back and cross prefix glyphs are removed
  - log: 2026-06-21 criterion added
  - log: 2026-06-21 verified - render test asserts no legacy glyphs; submenu shown as name/ (slash cue)
- [x] **Subtle highlight** - the highlighted row uses the surface colour, overriding Textual's bright block-cursor for both focused and blurred states
  - log: 2026-06-21 criterion added
  - log: 2026-06-21 verified - highlight uses surface bg + bold, overrides the block-cursor (UX re-confirm PASS)
- [x] **Truecolor** - COLORTERM is set to truecolor before import so dark slates are not downsampled under WSL or ttyd
  - log: 2026-06-21 criterion added
  - log: 2026-06-21 verified - COLORTERM=truecolor set in package __init__ before any rich/textual import (UX re-confirm fix)
- [x] **Fixed theme** - the brand theme is fixed; no theme switcher reachable
  - log: 2026-06-21 criterion added
  - log: 2026-06-21 verified - get_system_commands drops the Theme switcher, keeps Quit/Keys/Screenshot
  - log: 2026-06-22 superseded - the standard command palette is now disabled outright (ENABLE_COMMAND_PALETTE = False), so no Theme switcher (nor any palette) is reachable; the get_system_commands override was removed as dead code; brand theme remains the only theme
- [x] **Type-to-filter** - typing printable characters in the menu filters commands as-you-type instead of requiring arrow selection
  - log: 2026-06-22 criterion added
  - log: 2026-06-22 verified - on_key builds a filter query; Pilot test types and asserts the filtered result set (test_tui.py)
- [x] **Subtree search** - the filter matches commands anywhere in the current subtree, not only the current level; a command nested in a submenu is found from the parent
  - log: 2026-06-22 criterion added
  - log: 2026-06-22 verified - flat index walks submenu/scan_dir/menu_file; typing "git" at root finds the nested git-commit leaf (test_tui.py)
- [x] **Ancestor path** - each filtered match shows its submenu ancestor path so the user sees where the command lives
  - log: 2026-06-22 criterion added
  - log: 2026-06-22 verified - filtered row renders "Sub / name"; path prefix in submenu colour (test_filtered_text_shows_path_and_highlights_match)
- [x] **Match highlight** - the substring the user typed is highlighted within the matched command name
  - log: 2026-06-22 criterion added
  - log: 2026-06-22 verified - the typed run carries a bold amber style span over the matched offset (test_tui.py)
- [x] **Filter indicator** - while filtering, the breadcrumb shows the live query and the match count
  - log: 2026-06-22 criterion added
  - log: 2026-06-22 verified - breadcrumb renders "filter: git   2 matches"
- [x] **No duplicate title** - the breadcrumb does not repeat the header app title at the root; it shows the in-menu path, or a "type to filter" hint at root
  - log: 2026-06-22 criterion added - reported issue: title appeared twice (header + breadcrumb root title)
  - log: 2026-06-22 verified - breadcrumb excludes the root stack entry; at root it shows "type to filter", not the app title (test_tui.py)
- [x] **Command palette disabled** - the standard Textual command palette (the confusing 2-row popup) is disabled; the in-menu filter replaces it
  - log: 2026-06-22 criterion added - reported issue: standard palette popup was a useless 2-row box
  - log: 2026-06-22 verified - ENABLE_COMMAND_PALETTE = False on both apps (test_command_palette_disabled)
- [x] **Edge: clear filter** - escape or backspace-to-empty clears the filter and restores the navigable menu rather than quitting
  - log: 2026-06-22 criterion added
  - log: 2026-06-22 verified - escape clears a non-empty filter (test_escape_clears_the_filter); backspace deletes a char then falls back to Back
- [x] **Edge: no matches** - a filter query matching nothing shows a "no matches" notice, not a crash or empty screen
  - log: 2026-06-22 criterion added
  - log: 2026-06-22 verified - _render_filtered emits a "no matches - esc to clear" row when the match set is empty

### CLI Styling

- [x] **Themed output** - coloured CLI output such as the --list tree and run banners renders via a rich theme mapped to the Duoptimum palette
  - log: 2026-06-21 criterion added
  - log: 2026-06-21 verified - rich Console with PASTEL_THEME; list tree and run banners themed
- [x] **JSON stays plain** - --json output is never colourised
  - log: 2026-06-21 criterion added
  - log: 2026-06-21 verified - --json emitted plain (parity bytes identical, no escape codes)

### Tests and Test Data

- [x] **Suite** - a pytest suite ships with the package and runs offline
  - log: 2026-06-21 criterion added
  - log: 2026-06-21 verified - pytest runs offline, 37 passed (textual 8.2.7)
  - log: 2026-06-22 grew to 45 passed - added TUI type-to-filter/no-duplicate-title/palette-disabled tests and version-sync tests
- [x] **Fixtures** - test data includes a sample lab-utils.yml, a fake lab-utils.d/ tree with top-level and nested .d scripts, and lab-utils.lib/ entries
  - log: 2026-06-21 criterion added
  - log: 2026-06-21 verified - fixtures ship the sample yml, the lab-utils.d tree and lib entries
- [x] **Resolver tests** - script resolution covers bare name, .sh suffix, parent/child to parent.d/child.sh, absolute path and not-found
  - log: 2026-06-21 criterion added
  - log: 2026-06-21 verified - resolver tests cover all five cases
- [x] **Loader tests** - menu loading covers inline submenu, scan_dir, menu_file in dict and bare-list forms, and aux-menu injection order
  - log: 2026-06-21 criterion added
  - log: 2026-06-21 verified - loader tests cover the submenu/scan_dir/menu_file forms and injection order
- [x] **Selector tests** - current value and options resolution from literal, script and command sources, plus current-option marking
  - log: 2026-06-21 criterion added
  - log: 2026-06-21 verified - selector tests cover current/options from all three sources and current marking
- [x] **CLI tests** - argument dispatch for --help, --list, --json, --create-local and direct run, with correct exit codes
  - log: 2026-06-21 criterion added
  - log: 2026-06-21 verified - cli tests cover dispatch and exit codes
- [x] **TUI tests** - headless render plus Pilot-driven type-to-filter, ancestor-path, match-highlight, escape-clears and palette-disabled checks
  - log: 2026-06-22 criterion added
  - log: 2026-06-22 verified - test_tui.py covers no-glyphs, no-duplicate-title, filter behaviour and ENABLE_COMMAND_PALETTE
- [x] **Version tests** - _version.txt holds a real semver (not 0.0.0) and __version__ resolves, falling back to the file with no dist metadata
  - log: 2026-06-22 criterion added
  - log: 2026-06-22 verified - test_version.py asserts the semver, resolution, and the monkeypatched fallback

### Completions

- [x] **Bash** - bash completion keeps completing script names and options for the lab-utils command
  - log: 2026-06-21 criterion added
  - log: 2026-06-21 verified - bash completion unchanged, command name preserved, hardcodes /opt/utils (accepted)
- [x] **Fish** - fish completion keeps working, including dynamic discovery via lab-utils --json
  - log: 2026-06-21 criterion added
  - log: 2026-06-21 verified - fish completion delegates to lab-utils --json, which is parity-stable and env-aware
- [x] **Paths reconciled** - completion path assumptions match the packaged tool's data location
  - log: 2026-06-21 criterion added
  - log: 2026-06-21 verified - completions target /opt/utils, which is the package data root; architect census aligned

### Compatibility and Edges

- [x] **Hardcoded lib ref** - scripts referencing /opt/utils/lab-utils.lib such as the claude assets used by anthropic-claude-code.sh still resolve after the refactor
  - log: 2026-06-21 criterion added
  - log: 2026-06-21 verified - anthropic-claude-code.sh /opt/utils/lab-utils.lib path unchanged and still present in the data root
- [x] **Edge: empty menu** - a submenu that resolves to zero items shows a notice rather than crashing
  - log: 2026-06-21 criterion added
  - log: 2026-06-21 verified - tui notifies "No items found" (warning) instead of crashing
- [x] **Edge: textual or rich absent** - the CLI degrades to plain text and the menu prints a clear install message instead of a traceback
  - log: 2026-06-21 criterion added
  - log: 2026-06-21 verified - rich guarded (HAVE_RICH plain fallback), textual lazily imported with a friendly install message
- [x] **Edge: conda env install** - a conda env yaml selected in the menu still installs via conda env create
  - log: 2026-06-21 criterion added
  - log: 2026-06-21 in progress - yaml items recognised by the menu loader (parity-stable); the conda env create runtime path pending image verification
  - log: 2026-06-21 verified in image - menu loads install-conda-env/{r,rust,tensorflow,torch} and /opt/utils/conda-env.d present; conda env create lives in the unchanged /opt/utils/lab-utils.d/install-conda-env.d scripts, which the package resolves and runs (direct-run + exit-code parity proven)
- [x] **Edge: closed stdin** - the post-run "Press Enter to continue" does not traceback when stdin is closed or redirected (echo | lab-utils, CI, ttyd detach)
  - log: 2026-06-22 criterion added (tui adversary finding)
  - log: 2026-06-22 verified - the three input() guards catch EOFError as well as KeyboardInterrupt; test_press_enter_survives_closed_stdin exercises the no-options run_selector path with input() raising EOFError
