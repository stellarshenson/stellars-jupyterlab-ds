---
description: Create a GitHub release for the current version - rich notes, tag, and dist installers as assets (via REST API)
---

Create a GitHub release for the current platform version, matching the style of previous releases. Rich notes with top-10 highlights and changes since the last release, the version tag, and the `dist/` installers attached as assets. If the source changed and the server image was not rebuilt/pushed, `make rebuild && make push` runs first so the versioned image the notes reference actually exists on Docker Hub. `gh` is not installed - use the GitHub REST API directly with the token from `~/.git-credentials`.

Optional `$ARGUMENTS`: extra emphasis for the highlights, or a specific tag to release against. Default is the current version from `pyproject.toml`.

**Step 1: Resolve version, tag, and image name**
Read the version metadata and build the tag in the repo convention `{version}_cuda-{cuda}_jl-{jupyterlab}`:
```bash
python3 - <<'PY'
import tomllib
d=tomllib.load(open("pyproject.toml","rb"))
v=d["project"]["version"]; s=d["tool"]["stellars"]
tag=f'{v}_cuda-{s["cuda"]}_jl-{s["jupyterlab"]}'
print("VERSION", v); print("TAG", tag)
print("IMAGE", f'stellars/stellars-jupyterlab-ds:{tag}')
PY
```
Confirm the local tag already points at `HEAD` (`git describe --tags --exact-match HEAD`). If it does not exist yet, note that it will be created at `HEAD` when the release is published.

**Step 2: Ensure the server image and installers are current**
The release notes tell users to `docker pull` the versioned image, so that image must be built and published first. Detect whether the current source has been rebuilt and pushed:
```bash
# uncommitted source changes (image would be stale)?
git status --porcelain -- services/
# is the versioned image already on Docker Hub?
curl -s -o /dev/null -w "%{http_code}" \
  "https://hub.docker.com/v2/repositories/stellars/stellars-jupyterlab-ds/tags/<tag>"   # 200 = published, 404 = missing
```
If there are source changes and the server was not rebuilt/pushed (uncommitted changes under `services/`, or the `<tag>` image returns 404 on Docker Hub), rebuild and push it - `make rebuild` builds `latest` from source WITHOUT bumping the version and regenerates the `dist/` installers as its last step, then `make push` tags `latest` as `<tag>`, pushes `latest` + `<tag>` to Docker Hub, and creates the local git tag:
```bash
make rebuild && make push
```
This pushes a multi-GB image to Docker Hub - an outward-facing action - so confirm with the user before running it. If the image is already published and the source is unchanged, skip the rebuild. Then make sure both installers exist for the current version (a `make rebuild` above already produced them; otherwise build just the installers):
```bash
ls -la dist/stellars-jupyterlab-ds-setup-*.sh dist/stellars-jupyterlab-ds-setup-*.exe 2>/dev/null
```
If either is missing or stale, run `make installers` (the Windows `.exe` needs NSIS; it is skipped with a warning when `makensis` is absent - report that the exe will not be attached in that case).

**Step 3: Find the last release and gather the changelog**
```bash
TOKEN=$(grep 'github.com' ~/.git-credentials | head -1 | sed -E 's#https://[^:]+:([^@]+)@github.com#\1#')
curl -s -H "Authorization: token $TOKEN" \
  https://api.github.com/repos/stellarshenson/stellars-jupyterlab-ds/releases/latest \
  | python3 -c "import json,sys;r=json.load(sys.stdin);print('LAST_TAG',r['tag_name']);print('LAST_NAME',r['name'])"
```
Then summarize the notable work since that tag (use the release's underlying version tag as the baseline):
```bash
git rev-list --count <LAST_TAG>..HEAD
git log --no-merges --pretty='%s' <LAST_TAG>..HEAD | grep -iE '^(feat|build|perf)(\(|:)'
```

**Step 4: Draft the release notes**
Write the body to a scratchpad file, following the structure of previous releases:
- `# Release Notes: Version {version}` and a `**Docker Image:**` line
- `## Overview` - one paragraph, commit count since the last release, headline changes, JupyterLab + CUDA versions
- `## Platform Updates` - a table with Previous/Current for JupyterLab, CUDA, Python
- `## Top 10 Highlights` - exactly 10 `###`-numbered sections drawn from the feat/build commits, each with a one-line intro and a short bullet list
- `## Installation` - docker pull, `make pull && make start`, installer one-liners, docker compose (with `--env-file .env.default --env-file .env`)
- `### Access URLs` - host-based: `https://lab.<project>.localhost`, proxied services under it, `https://traefik.<project>.localhost`
- `### Assets` - list the attached installers
- `## Resources` - README, Docker Hub, author footer

Rules for the body:
- NO mention of licensing or license changes
- No emojis, no em-dashes (use ` - `), GitHub-flavored markdown
- Ground every highlight in an actual commit since the last release

**Step 5: Confirm before publishing**
Publishing a release is outward-facing and hard to reverse. Show the user the tag name, the drafted notes, and the asset list, and get explicit confirmation before Step 6. If `$ARGUMENTS` asked for a draft, create it with `"draft":true`.

**Step 6: Push the tag, create the release, upload assets**
```bash
TOKEN=$(grep 'github.com' ~/.git-credentials | head -1 | sed -E 's#https://[^:]+:([^@]+)@github.com#\1#')
REPO=stellarshenson/stellars-jupyterlab-ds
TAG=<tag>

# push the tag (created at HEAD if it did not exist)
git push origin "$TAG"

# create the release (body from the scratchpad file)
python3 - "$TAG" "<body-file>" > /tmp/release-payload.json <<'PY'
import json,sys
tag,body=sys.argv[1],open(sys.argv[2]).read()
print(json.dumps({"tag_name":tag,"name":f"Stellars Jupyterlab Data Science Platform {tag.split('_')[0]}",
  "body":body,"draft":False,"prerelease":False}))
PY
RID=$(curl -s -X POST -H "Authorization: token $TOKEN" -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/$REPO/releases" -d @/tmp/release-payload.json \
  | python3 -c "import json,sys;print(json.load(sys.stdin)['id'])")

# upload each installer as an asset
for f in dist/stellars-jupyterlab-ds-setup-*.sh dist/stellars-jupyterlab-ds-setup-*.exe; do
  [ -f "$f" ] || continue
  curl -s -X POST -H "Authorization: token $TOKEN" -H "Content-Type: application/octet-stream" \
    --data-binary @"$f" \
    "https://uploads.github.com/repos/$REPO/releases/$RID/assets?name=$(basename "$f")" \
    | python3 -c "import json,sys;r=json.load(sys.stdin);print('uploaded',r['name'],r['size']) if 'name' in r else print('ERROR',r)"
done
```

**Step 7: Verify and report**
```bash
curl -s https://api.github.com/repos/stellarshenson/stellars-jupyterlab-ds/releases/latest \
  | python3 -c "import json,sys;r=json.load(sys.stdin);print(r['name']);print(r['html_url']);[print(' -',a['name'],a['size']) for a in r['assets']]"
```
Report the release URL, the tag, and the attached assets. Confirm no license text is present in the body.

**Notes**
- This command creates a tag and a public release - invoking `/release` is the explicit approval for that tag and push; still confirm the drafted notes in Step 5 first
- Never commit or push `.env` (holds the token) - assets come from `dist/` only, which is gitignored
