#!/usr/bin/env bash
#
# Sync generated plugin skill copies from their single authored sources.
#
# Authored sources (edit these):
#   skills/<skill-name>/SKILL.md
#
# Generated copies (do NOT edit by hand — CI checks they match):
#   plugins/<plugin-name>/skills/<skill-name>/SKILL.md
#
# A plugin bundles a skill by having a directory
# `plugins/<plugin-name>/skills/<skill-name>/`. This script discovers every
# such directory and copies the matching authored source into it, so adding a
# new plugin or skill needs no edits here — just create the directories.
#
# Run `scripts/sync-plugin.sh` after changing an authored source.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

shopt -s nullglob

synced=0
for dest_dir in plugins/*/skills/*/; do
  skill_name="$(basename "$dest_dir")"
  src_dir="skills/$skill_name"
  if [[ ! -d "$src_dir" ]]; then
    echo "error: plugin bundles skill '$skill_name' but no authored source directory at $src_dir" >&2
    exit 1
  fi
  
  # Remove old sync output to handle deleted files
  rm -rf "${dest_dir:?}"/*
  # Copy all contents including subdirectories and dotfiles
  cp -a "$src_dir"/. "$dest_dir"
  
  echo "synced $src_dir/ -> $dest_dir/"
  synced=$((synced + 1))
done

if [[ "$synced" -eq 0 ]]; then
  echo "warning: no plugin skill directories found under plugins/*/skills/*/" >&2
fi
