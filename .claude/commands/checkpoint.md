---
description: Create checkpoint tag before major change or after important milestone
---

Create a checkpoint tag to mark a stable point before implementing major changes or after completing important work.

**Tag format**: `CHECKPOINT_<NAME>_<version>`
- Name should be uppercase with underscores (e.g., `BEFORE_ACTIVITY_TRACKER`, `AFTER_SESSION_EXTENSION`)
- Suffix is the shortened version (major.minor.patch) extracted from project.env

**Step 1: Get current version**
Use the Bash tool to extract the shortened version:
```bash
grep "^VERSION=" project.env | sed 's/VERSION="//;s/_.*//'
```

**Step 2: Determine checkpoint name**
Based on context, suggest a checkpoint name:
- Before implementation: `BEFORE_<FEATURE_NAME>`
- After completion: `AFTER_<FEATURE_NAME>`
- Stable release point: `STABLE_<DESCRIPTION>`

If unclear, ask the user for the checkpoint name.

**Step 3: Create and push tag**
Use the Bash tool to create annotated tag and push:
```bash
git tag -a CHECKPOINT_<NAME>_<version> -m "Checkpoint: <brief description>" && \
git push origin CHECKPOINT_<NAME>_<version>
```

**Step 4: Confirm**
Inform the user:
- The full tag name created
- That it was pushed to origin
- How to revert to this checkpoint if needed: `git checkout CHECKPOINT_<NAME>_<version>`
