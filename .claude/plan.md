# Research: YAML-Driven Terminal Menu Solutions

## Objective

Find open-source solutions that provide YAML-driven menu-submenu-command structure for terminal navigation with:
- Hierarchical menu navigation (back/forth)
- Command execution as leaf nodes
- Configuration via YAML files

## Research Findings

### 1. Close Matches (Partial Solutions)

#### Task / go-task (taskfile.dev)
- **What it does**: YAML-based task runner similar to Make
- **Pros**: Native YAML config (Taskfile.yml), hierarchical task dependencies, cross-platform
- **Cons**: No interactive menu TUI - runs tasks directly from CLI
- **Source**: [go-task/task](https://github.com/go-task/task)

#### Sunbeam
- **What it does**: General-purpose command-line launcher with scriptable UIs
- **Pros**: Define UIs from scripts, succession of views, extensible
- **Cons**: Uses JSON for view definitions (not YAML), requires scripting for each command
- **Source**: [pomdtr/sunbeam](https://github.com/pomdtr/sunbeam)

#### smenu
- **What it does**: Powerful terminal selection/menu tool
- **Pros**: Flexible layouts, keyboard/mouse navigation, scrolling windows
- **Cons**: Command-line driven configuration (not YAML), no native hierarchical menu support
- **Source**: [p-gen/smenu](https://github.com/p-gen/smenu)

#### fzf-based launchers (fzf-nova, fzlaunch)
- **What it does**: Fuzzy finder as script/app launcher
- **Pros**: Fast, fuzzy search, can integrate with any script collection
- **Cons**: Flat list (no hierarchical navigation), no native YAML config
- **Source**: [gotbletu/fzf-nova](https://github.com/gotbletu/fzf-nova), [tmarkov/fzlaunch](https://github.com/tmarkov/fzlaunch)

#### Charmbracelet tools (gum, bubbletea)
- **What it does**: Glamorous shell scripts and TUI framework
- **Pros**: Beautiful TUI components, Go-based, highly customizable
- **Cons**: Requires programming (not config-driven), no built-in YAML menu system
- **Source**: [charmbracelet/gum](https://github.com/charmbracelet/gum)

#### pet
- **What it does**: Command-line snippet manager with interactive search
- **Pros**: TOML config, fzf integration, parameterized snippets
- **Cons**: Flat snippet list (no hierarchical menus), TOML not YAML
- **Source**: [knqyf263/pet](https://github.com/knqyf263/pet)

#### bash-menu
- **What it does**: Console menu system for bash with spaces/contexts
- **Pros**: Directory navigation, script execution, customizable
- **Cons**: Not YAML-driven, manual menu definition in scripts
- **Source**: [dynamide/bash-menu](https://github.com/dynamide/bash-menu)

### 2. No Exact Match Found

After extensive research, **no existing open-source tool** provides the exact combination of:
- YAML configuration file
- Hierarchical menu/submenu structure
- Back/forth navigation
- Command execution as leaf nodes

### 3. Recommended Approaches

#### Option A: Build wrapper around existing tools
Create a Python/Bash script that:
1. Reads YAML menu definition
2. Uses `dialog` or `gum` for rendering
3. Handles navigation state
4. Executes commands from leaf nodes

**Estimated complexity**: Medium (2-3 days)

#### Option B: Use Task + custom TUI
Combine go-task Taskfile with a simple TUI wrapper:
1. Define tasks in Taskfile.yml
2. Build menu from task metadata/namespaces
3. Use fzf or gum for selection

**Estimated complexity**: Medium

#### Option C: Build on Bubbletea/Bubbles
Create a Go-based solution using Charmbracelet's framework:
1. Define YAML schema for menus
2. Parse YAML to menu tree
3. Use Bubbles list component for navigation
4. Execute shell commands from selections

**Estimated complexity**: High (1-2 weeks)

#### Option D: Enhance current lab-utils
Keep current dialog-based approach but:
1. Add YAML config layer on top
2. Auto-generate menu structure from YAML
3. Maintain backward compatibility with existing scripts

**Estimated complexity**: Low-Medium (1-2 days)

## Recommendation

**Option D (Enhance current lab-utils)** appears most practical because:
- Leverages existing dialog infrastructure
- Minimal dependencies
- Can be implemented incrementally
- YAML config can coexist with existing script-based approach

### Proposed YAML Schema

```yaml
# lab-utils-menu.yml
menu:
  title: "Lab Utils"
  items:
    - name: "Set Defaults"
      submenu:
        - name: "Default Shell"
          command: "set-defaults.d/default-shell.sh"
        - name: "Default Conda Env"
          command: "set-defaults.d/default-conda-env.sh"
        - name: "Default AWS Profile"
          command: "set-defaults.d/default-aws-profile.sh"

    - name: "Git Utils"
      submenu:
        - name: "Pull All Repos"
          command: "git-utils.d/pull-all.sh"
        - name: "Push All Repos"
          command: "git-utils.d/push-all.sh"

    - name: "Install Environments"
      command: "install-conda-env.sh"

    - name: "Test CUDA"
      command: "test-cuda.sh"
```

## Sources

- [Task (go-task)](https://taskfile.dev/) - YAML task runner
- [Sunbeam](https://github.com/pomdtr/sunbeam) - Command-line launcher
- [smenu](https://github.com/p-gen/smenu) - Terminal menu generator
- [Charmbracelet gum](https://github.com/charmbracelet/gum) - Shell script TUI tool
- [pet](https://github.com/knqyf263/pet) - Snippet manager
- [bash-menu](https://github.com/dynamide/bash-menu) - Bash menu system
- [fzf](https://github.com/junegunn/fzf) - Fuzzy finder
