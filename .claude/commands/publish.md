---
description: Update journal, commit all changes with rich message, and push to repo
---

Publish changes to the repository by updating the journal, creating a rich commit message, and pushing.

**Step 1: Check repository status**
Use the Bash tool to run these commands in parallel:
```bash
git status --short
```
```bash
git diff --stat
```
```bash
git log -1 --oneline
```

**Step 2: Analyze changes and update journal**
- Review the git status and diff output
- Identify what substantive work was done (documents, code, features, fixes)
- Update `.claude/JOURNAL.md` with a new entry following the format:
  ```
  <number>. **Task - <short 3-5 word depiction>**: task description<br>
      **Result**: summary of the work done
  ```
- Only log substantive work (not routine maintenance or trivial changes)

**Step 3: Draft commit message**
Analyze all changes and create a concise commit message that:
- Uses conventional commit format: `feat:` / `fix:` / `docs:` / `refactor:` / `chore:`
- Summarizes the nature of changes (new feature, bug fix, enhancement, etc.)
- Focuses on the "why" rather than the "what"
- Keeps it 1-2 sentences maximum
- DO NOT include "Generated with Claude Code" or "Co-Authored-By: Claude"

**Step 4: Commit and push**
Use the Bash tool to run:
```bash
git add . && \
git commit -m "your commit message here" && \
git push
```

After completion, inform the user:
- What was added to the journal
- The commit message used
- Confirmation that changes were pushed to the remote repository

If there are no changes to commit, inform the user that the repository is clean.
