#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GCS_BUCKET="${GCS_BUCKET:-docs-avagate-dev}"
BUCKET="gs://${GCS_BUCKET}/sites"
DOCS_BASE="${DOCS_BASE:-https://docs.avagate.dev}"
DOCS_BASE="${DOCS_BASE%/}"
CACHE_CONTROL="${CACHE_CONTROL:-max-age=300}"
CUSTOM_MANIFESTS_PATH="${CUSTOM_MANIFESTS_PATH:-${SCRIPT_DIR}/custom-manifests.json}"
TMP_ENTRIES="$(mktemp)"
TMP_OUTPUT="$(mktemp)"

cleanup() {
  rm -f "$TMP_ENTRIES" "$TMP_OUTPUT"
}
trap cleanup EXIT

> "$TMP_ENTRIES"

while IFS= read -r manifest_path; do
  [[ -z "$manifest_path" ]] && continue

  dir="${manifest_path#${BUCKET}/}"
  dir="${dir%/manifest.json}"

  if [[ -z "$dir" || "$dir" == *"/"* ]]; then
    echo "warning: skipping unexpected manifest path: ${manifest_path}" >&2
    continue
  fi

  if ! manifest_json="$(gcloud storage cat "$manifest_path" 2>/dev/null)"; then
    echo "warning: failed to read ${manifest_path}" >&2
    continue
  fi

  if ! normalized="$(jq -c --arg default_link "${DOCS_BASE}/${dir}/" '
    if type != "object" then
      error("not an object")
    elif (.name | type) != "string" or .name == "" then
      error("missing or invalid name")
    else
      {
        name: .name,
        description: (if (.description? | type) == "string" and .description != "" then .description else empty end),
        icon: (if (.icon? | type) == "string" and .icon != "" then .icon else empty end),
        link: (if (.link? | type) == "string" and .link != "" then .link else $default_link end)
      }
    end
  ' <<< "$manifest_json" 2>/dev/null)"; then
    echo "warning: invalid manifest at ${manifest_path}" >&2
    continue
  fi

  echo "$normalized" >> "$TMP_ENTRIES"
done < <(gcloud storage ls "${BUCKET}/*/manifest.json" 2>/dev/null || true)

if [[ -f "$CUSTOM_MANIFESTS_PATH" ]]; then
  if ! custom_json="$(jq -c 'if type != "array" then error("not an array") else . end' "$CUSTOM_MANIFESTS_PATH" 2>/dev/null)"; then
    echo "warning: invalid custom-manifests.json" >&2
  else
    if [[ -s "$TMP_ENTRIES" ]]; then
      existing_names="$(jq -s 'map(.name)' "$TMP_ENTRIES")"
    else
      existing_names='[]'
    fi

    while IFS= read -r entry; do
      [[ -z "$entry" ]] && continue

      if ! normalized="$(jq -c '
        if type != "object" then
          error("not an object")
        elif (.name | type) != "string" or .name == "" then
          error("missing or invalid name")
        elif (.link? | type) != "string" or .link == "" then
          error("missing link")
        else
          {
            name: .name,
            description: (if (.description? | type) == "string" and .description != "" then .description else empty end),
            icon: (if (.icon? | type) == "string" and .icon != "" then .icon else empty end),
            link: .link
          }
        end
      ' <<< "$entry" 2>/dev/null)"; then
        echo "warning: invalid custom manifest in ${CUSTOM_MANIFESTS_PATH}" >&2
        continue
      fi

      name="$(jq -r '.name' <<< "$normalized")"
      if jq -e --arg n "$name" 'index($n) != null' <<< "$existing_names" >/dev/null 2>&1; then
        echo "warning: skipping custom manifest '${name}' (already exists in GCS)" >&2
        continue
      fi

      echo "$normalized" >> "$TMP_ENTRIES"
      existing_names="$(jq -c --arg n "$name" '. + [$n]' <<< "$existing_names")"
    done < <(jq -c '.[]' <<< "$custom_json")
  fi
fi

if [[ ! -s "$TMP_ENTRIES" ]]; then
  echo '[]' > "$TMP_OUTPUT"
else
  jq -s 'sort_by(.name)' "$TMP_ENTRIES" > "$TMP_OUTPUT"
fi

gcloud storage cp "$TMP_OUTPUT" "${BUCKET}/projects.json" \
  --cache-control="${CACHE_CONTROL}"

echo "Uploaded ${BUCKET}/projects.json ($(jq 'length' "$TMP_OUTPUT") projects)"
