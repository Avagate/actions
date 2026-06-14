# avagate/actions

Shared, reusable GitHub Actions for Avagate repositories.

## Actions

- [`deploy-vitepress-to-gcs`](deploy-vitepress-to-gcs/) — build a VitePress docs site, deploy it to the `docs-avagate-dev` GCS bucket under `sites/<folder>/`, and rebuild `sites/projects.json`.
- [`build-projects-manifest`](build-projects-manifest/) — aggregate per-site `manifest.json` files from GCS into `sites/projects.json` for the docs portal home page.

Reference an action by path and ref, for example:

```yaml
- uses: avagate/actions/deploy-vitepress-to-gcs@v1
```

## Adopting in a new repo

1. Copy [`deploy-vitepress-to-gcs/workflow-template.yaml`](deploy-vitepress-to-gcs/workflow-template.yaml) to `.github/workflows/docs-deploy.yaml` (or another name).
2. Add the `GCP_SA_KEY` repository secret — JSON credentials for a service account with write/delete access on the site folder, read access to `sites/*/manifest.json`, and write access to `sites/projects.json`.
3. Customize the workflow `paths:` list so deploys run when your docs-related files change.
4. Ensure the repo has a root `.nvmrc` and a `pnpm docs:build` script (or pass `build_command` / `dist_path` overrides to the action).

By default, a repo named `my-project` deploys to `gs://docs-avagate-dev/sites/my-project/`. Override `gcs_folder` or `gcs_bucket` via action inputs when needed.

## Versioning

Use immutable tags (`@v1`, `@v2`, …). Bump the major tag when action inputs or behavior change incompatibly.
