# build-projects-manifest

Composite GitHub Action that aggregates per-site `manifest.json` files from a GCS bucket into a single `projects.json` for the docs portal home page.

## Quick start

Copy [`workflow-template.yaml`](workflow-template.yaml) to `.github/workflows/build-projects.yaml` in your repo and add the `GCP_SA_KEY` repository secret.

## Usage

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: avagate/actions/build-projects-manifest@v4
        env:
          GCP_SA_KEY: ${{ secrets.GCP_SA_KEY }}
```

No checkout step is required — the action bundles its own script and reads per-site manifests from GCS.

## Required environment variable

Composite actions cannot declare `secrets:`. The caller must pass the GCP service account JSON key via `env`:

- **`GCP_SA_KEY`** — JSON credentials for a service account with read access to `gs://<bucket>/sites/*/manifest.json` and write access to `gs://<bucket>/sites/projects.json`. Read by the `google-github-actions/auth@v2` step as `credentials_json`.

## Inputs

All inputs are optional.

- **`gcs_bucket`** — GCS bucket name without the `gs://` prefix. Default when empty: `docs-avagate-dev`.
- **`site_base_url`** — Public base URL for the docs portal (no trailing slash). Used as the default `link` value for projects that omit `link` in their manifest. Default: `https://docs.avagate.dev`.
- **`cache_control`** — `Cache-Control` header for the uploaded `projects.json`. Default: `max-age=300`.

## Behavior

The action:

1. Lists `gs://<gcs_bucket>/sites/*/manifest.json` in GCS.
2. Reads each manifest, validates that it is an object with a non-empty `name`, and normalizes optional `description`, `icon`, and `link` fields (default `link`: `{site_base_url}/{folder}/`).
3. Sorts entries by `name` and uploads the result to `gs://<gcs_bucket>/sites/projects.json`.

Invalid or unreadable manifests are skipped with a warning; the job continues.

## External projects

Docs sites hosted outside the bucket (for example on GitHub Pages) can still appear on the portal by uploading a manifest stub to GCS:

```text
gs://<gcs_bucket>/sites/<slug>/manifest.json
```

Each manifest is an object with a required `name` and optional `description`, `icon`, and `link`. Set `link` explicitly when the docs are not served from `{site_base_url}/{slug}/`.

Example:

```json
{
  "name": "External Docs",
  "description": "Optional short description",
  "icon": "https://example.com/icon.svg",
  "link": "https://example.com/docs/"
}
```

## Example with overrides

```yaml
- uses: avagate/actions/build-projects-manifest@v4
  with:
    gcs_bucket: docs-staging-avagate-dev
    site_base_url: https://docs-staging.avagate.dev
    cache_control: max-age=60
  env:
    GCP_SA_KEY: ${{ secrets.GCP_SA_KEY }}
```

## Versioning

Pin to the moving major tag, e.g. `avagate/actions/build-projects-manifest@v4`. The `Release` workflow publishes an immutable semver tag (`v4.1.2`) on each release and moves the matching major tag (`v4`) to it, so `@v4` always resolves to the latest backward-compatible release. A new major tag (`v5`, …) is introduced only for breaking changes.
