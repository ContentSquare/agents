#!/usr/bin/env bash
# Fails unless the ZIP has the layout the OpenAI plugin upload accepts.
set -euo pipefail

zip_path="$1"
entries="$(zipinfo -1 "${zip_path}")"
status=0

for required in plugin.json mcp.json; do
  if ! grep -qxF "${required}" <<<"${entries}"; then
    echo "::error::${zip_path}: ${required} must be at the archive root" >&2
    status=1
  fi
done

unexpected="$(grep -vE '^(plugin\.json|mcp\.json|assets/.*)$' <<<"${entries}" || true)"
if [[ -n "${unexpected}" ]]; then
  echo "::error::${zip_path}: unexpected entries:" >&2
  echo "${unexpected}" >&2
  status=1
fi

exit "${status}"
