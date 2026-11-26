#!/usr/bin/env bash
# Builds the OpenAI plugin directory ZIP and prints its path.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
plugin_dir="${repo_root}/plugins/contentsquare"
out_dir="${repo_root}/dist"

version="$(jq -r .version "${plugin_dir}/plugin.json")"
zip_path="${out_dir}/contentsquare-openai-${version}.zip"

mkdir -p "${out_dir}"
rm -f "${zip_path}"

# OpenAI reads the manifest from the archive root, and the Claude and Cursor
# manifests in the same folder must stay out of the upload.
(cd "${plugin_dir}" && zip -X -q -r "${zip_path}" plugin.json mcp.json assets)

bash "${repo_root}/scripts/check-openai-zip.sh" "${zip_path}"
echo "${zip_path}"
