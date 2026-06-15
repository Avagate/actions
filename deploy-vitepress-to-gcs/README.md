# deploy-vitepress-to-gcs

Composite GitHub Action that builds a VitePress docs site, deploys it to a private GCS bucket under `sites/<folder>/`, and rebuilds `sites/projects.json` for the docs portal home page.

## Quick start

Copy [`workflow-template.yaml`](workflow-template.yaml) to `.github/workflows/docs-deploy.yaml` in your repo, add the `GCP_SA_KEY` repository secret, and customize the `paths:` filters.

## Usage

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          ref: ${{ inputs.source_ref || github.ref }}
      - uses: avagate/actions/deploy-vitepress-to-gcs@v4
        env:
          GCP_SA_KEY: ${{ secrets.GCP_SA_KEY }}
```

With no `with:` inputs, a repo named `coreauth` deploys to `gs://docs-avagate-dev/sites/coreauth`.

## Required environment variable

Composite actions cannot declare `secrets:`. The caller must pass the GCP service account JSON key via `env`:

- **`GCP_SA_KEY`** — JSON credentials for a service account with write/delete access on the site folder under `gs://<bucket>/sites/<folder>/`, read access to `gs://<bucket>/sites/*/manifest.json`, and write access to `gs://<bucket>/sites/projects.json`. Read by the `google-github-actions/auth@v2` step as `credentials_json`.

## Inputs

All inputs are optional.

- **`gcs_bucket`** — GCS bucket name without the `gs://` prefix. Default when empty: `docs-avagate-dev`.
- **`gcs_folder`** — Site slug deployed to `gs://<bucket>/sites/<folder>/`. Default when empty: `${{ github.event.repository.name }}` (e.g. `avagate/coreauth` → `coreauth`). Override when the repo name differs from the site slug or for monorepos.
- **`build_command`** — Default: `pnpm docs:build`.
- **`dist_path`** — Built site output directory. Default: `docs/.vitepress/dist`.
- **`manifest_path`** — Source path for `manifest.json` copied into `dist_path` before upload. Default: `docs/manifest.json`. The copy step is skipped when this input is empty or the file does not exist.
- **`site_base_url`** — Public base URL for the deployed site (no trailing slash). Default: `https://docs.avagate.dev`.

## Outputs

- **`site_url`** — Public URL of the deployed site, e.g. `https://docs.avagate.dev/coreauth/`. Also written to the job summary and logs.

```yaml
- uses: avagate/actions/deploy-vitepress-to-gcs@v4
  id: docs
  env:
    GCP_SA_KEY: ${{ secrets.GCP_SA_KEY }}
- run: echo "Live at ${{ steps.docs.outputs.site_url }}"
```

## Deploy target

Uploads always go to:

```text
gs://<gcs_bucket>/sites/<gcs_folder>/
```

The `sites/` prefix is fixed to match the docs portal bucket layout.

After upload, the action runs [`build-projects-manifest`](../build-projects-manifest/) to aggregate all per-site `manifest.json` files into `gs://<gcs_bucket>/sites/projects.json`.

## Example with overrides

```yaml
- uses: avagate/actions/deploy-vitepress-to-gcs@v4
  with:
    gcs_folder: legacy-site-name
    build_command: pnpm --filter docs build
    dist_path: packages/docs/.vitepress/dist
  env:
    GCP_SA_KEY: ${{ secrets.GCP_SA_KEY }}
```

## Versioning

Pin to the moving major tag, e.g. `avagate/actions/deploy-vitepress-to-gcs@v4`. The `Release` workflow publishes an immutable semver tag (`v4.1.2`) on each release and moves the matching major tag (`v4`) to it, so `@v4` always resolves to the latest backward-compatible release. A new major tag (`v5`, …) is introduced only for breaking changes. See the [repo-wide versioning notes](../README.md#versioning).
