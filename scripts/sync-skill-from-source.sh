#!/usr/bin/env bash
#
# Mirror an authored skill from a source checkout into skills/<skill>/, regenerate
# the generated plugin copies, and open or update one PR per stack.
#
# Env (required): SOURCE_REPO, SOURCE_SHA, SOURCE_DIR, GH_TOKEN
# Env (optional): SKILLS_PATH, COMPARE_URL, SERVER_URL
set -euo pipefail

SOURCE_REPO="${SOURCE_REPO:?SOURCE_REPO is required}"
SOURCE_SHA="${SOURCE_SHA:?SOURCE_SHA is required}"
SOURCE_DIR="${SOURCE_DIR:?SOURCE_DIR is required}"
SKILLS_PATH="${SKILLS_PATH:-ai/.agents/skills}"
SERVER_URL="${SERVER_URL:-https://github.com}"

SHORT_SHA="${SOURCE_SHA:0:7}"
COMMIT_URL="$SERVER_URL/$SOURCE_REPO/commit/$SOURCE_SHA"
DIFF_URL="${COMPARE_URL:-$COMMIT_URL}"

src_root="$SOURCE_DIR/$SKILLS_PATH"
if [ ! -d "$src_root" ]; then
  echo "::notice::No skills directory at '$src_root' in ${SOURCE_REPO}@${SHORT_SHA} — nothing to sync."
  exit 0
fi

# Skill folder name -> stack (used as the PR branch key).
skill_to_stack() {
  case "$1" in
    contentsquare-flutter-sdk)     echo "flutter" ;;
    contentsquare-ios-sdk)         echo "ios" ;;
    contentsquare-android-sdk)     echo "android" ;;
    contentsquare-reactnative-sdk) echo "reactnative" ;;
    contentsquare-web-tag-install) echo "web" ;;
    *) printf '%s' "${1#contentsquare-}" | sed 's/-sdk$//' ;;
  esac
}

git fetch --quiet origin main

synced_any=false
shopt -s nullglob
for skill_src in "$src_root"/*/; do
  skill="$(basename "$skill_src")"
  stack="$(skill_to_stack "$skill")"
  branch="auto/skill-sync-$stack"
  dest="skills/$skill"

  echo "::group::Syncing skill '$skill' (stack: $stack)"

  # Reuse the branch while its PR is open; else branch fresh from main.
  reuse=false
  if git ls-remote --exit-code --heads origin "$branch" >/dev/null 2>&1; then
    state="$(gh pr view "$branch" --json state --jq '.state' 2>/dev/null || echo '')"
    if [ "$state" = "OPEN" ]; then
      reuse=true
    fi
  fi

  if [ "$reuse" = true ]; then
    echo "Open PR found for '$branch' — continuing it."
    git fetch --quiet origin "$branch"
    git checkout -B "$branch" "origin/$branch"
  else
    echo "No open PR for '$branch' — branching fresh from main."
    git checkout -B "$branch" origin/main
  fi

  # Mirror source, then regenerate the plugin copies.
  rm -rf "${dest:?}"
  mkdir -p "$dest"
  cp -a "${skill_src}." "$dest/"
  find "$dest" -name '.DS_Store' -delete
  ./scripts/sync-plugin.sh >/dev/null

  git add -A
  if git diff --cached --quiet; then
    echo "No content changes for '$skill' — skipping."
    echo "::endgroup::"
    continue
  fi

  echo "Source: ${SOURCE_REPO}@${SHORT_SHA} · diff: ${DIFF_URL}"

  git commit --quiet -m "chore(skills): update $skill skill"

  if [ "$reuse" = true ]; then
    git push --force-with-lease origin "$branch"
  else
    git push --force origin "$branch"
  fi

  synced_at="$(date -u '+%Y-%m-%d %H:%M UTC')"

  if [ "$reuse" = true ]; then
    gh pr comment "$branch" --body "🤖 Synced newer upstream changes to the \`$skill\` skill ($synced_at)."
    echo "Updated existing PR for '$branch'."
  else
    body_file="$(mktemp)"
    cat > "$body_file" <<EOF
## 🤖 Automated skill sync

Updates the \`$skill\` skill and its generated plugin copies from the upstream
source. Opened and updated automatically; while open, new changes are pushed here
instead of opening another PR. Don't hand-edit these files — edit the upstream
source and the change flows back here.
EOF
    gh pr create \
      --base main \
      --head "$branch" \
      --title "chore(skills): update $stack skill" \
      --body-file "$body_file"
    rm -f "$body_file"
    echo "Opened new PR for '$branch'."
  fi

  synced_any=true
  echo "::endgroup::"
done

if [ "$synced_any" = false ]; then
  echo "::notice::No skill changes required a PR for ${SOURCE_REPO}@${SHORT_SHA}."
fi
