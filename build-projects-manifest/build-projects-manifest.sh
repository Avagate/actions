#!/usr/bin/env bash
set -euo pipefail

GCS_BUCKET="${GCS_BUCKET:-docs-avagate-dev}"
BUCKET="gs://${GCS_BUCKET}/sites"
DOCS_BASE="${DOCS_BASE:-https://docs.avagate.dev}"
DOCS_BASE="${DOCS_BASE%/}"
CACHE_CONTROL="${CACHE_CONTROL:-max-age=300}"
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

if [[ ! -s "$TMP_ENTRIES" ]]; then
  echo '[]' > "$TMP_OUTPUT"
else
  jq -s 'sort_by(.name)' "$TMP_ENTRIES" > "$TMP_OUTPUT"
fi

gcloud storage cp "$TMP_OUTPUT" "${BUCKET}/projects.json" \
  --cache-control="${CACHE_CONTROL}"

echo "Uploaded ${BUCKET}/projects.json ($(jq 'length' "$TMP_OUTPUT") projects)"
