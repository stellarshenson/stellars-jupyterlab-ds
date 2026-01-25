#!/bin/bash
# Converts Vundle-cloned git repos to shallow clones (depth=1)
# Run after vim PluginInstall to reduce disk space

BUNDLE_DIR="${HOME}/.vim/bundle"

if [[ ! -d "$BUNDLE_DIR" ]]; then
    echo "Bundle directory not found: $BUNDLE_DIR"
    exit 1
fi

echo "Shallowing git repos in $BUNDLE_DIR..."

for repo in "$BUNDLE_DIR"/*/; do
    [[ -d "${repo}.git" ]] || continue

    name=$(basename "$repo")
    echo "  $name"

    cd "$repo" || continue

    # Get remote URL
    remote=$(git remote get-url origin 2>/dev/null)
    [[ -z "$remote" ]] && continue

    # Remove old repo and shallow clone
    cd "$BUNDLE_DIR"
    rm -rf "$repo"
    git clone --depth 1 --quiet "$remote" "$name" 2>/dev/null || echo "    failed: $name"
done

echo "Done."
