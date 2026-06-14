# deploy-vitepress-to-gcs

Composite GitHub Action that builds a VitePress docs site and deploys it to a private GCS bucket under `sites/<folder>/`.

## Usage

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          ref: ${{ inputs.source_ref || github.ref }}
      - uses: avagate/actions/deploy-vitepress-to-gcs@main
        env:
          GCP_SA_KEY: ${{ secrets.GCP_SA_KEY }}
```

With no `with:` inputs, a repo named `coreauth` deploys to `gs://docs-avagate-dev/sites/coreauth`.

## Required environment variable

Composite actions cannot declare `secrets:`. The caller must pass the GCP service account JSON key via `env`:

- **`GCP_SA_KEY`** — JSON credentials for a service account with write access to the target bucket. Read by the `google-github-actions/auth@v2` step as `credentials_json`.

## Inputs

All inputs are optional.

- **`gcs_bucket`** — GCS bucket name without the `gs://` prefix. Default when empty: `docs-avagate-dev`.
- **`gcs_folder`** — Site slug deployed to `gs://<bucket>/sites/<folder>/`. Default when empty: `${{ github.event.repository.name }}` (e.g. `avagate/coreauth` → `coreauth`). Override when the repo name differs from the site slug or for monorepos.
- **`build_command`** — Default: `pnpm docs:build`.
- **`dist_path`** — Built site output directory. Default: `docs/.vitepress/dist`.
- **`manifest_path`** — Source path for `manifest.json` copied into `dist_path` before upload. Default: `docs/manifest.json`. The copy step is skipped when this input is empty or the file does not exist.

## Deploy target

Uploads always go to:

```text
gs://<gcs_bucket>/sites/<gcs_folder>/
```

The `sites/` prefix is fixed to match the docs portal bucket layout.

## Example with overrides

```yaml
- uses: avagate/actions/deploy-vitepress-to-gcs@main
  with:
    gcs_folder: legacy-site-name
    build_command: pnpm --filter docs build
    dist_path: packages/docs/.vitepress/dist
  env:
    GCP_SA_KEY: ${{ secrets.GCP_SA_KEY }}
```

## Versioning

This action is referenced with `@main`. To pin to an immutable release, push a tag (e.g. `v1`) and reference `avagate/actions/deploy-vitepress-to-gcs@v1`.
