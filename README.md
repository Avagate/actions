# avagate/actions

Shared, reusable GitHub Actions for Avagate repositories.

## Actions

- [`deploy-vitepress-to-gcs`](deploy-vitepress-to-gcs/) — build a VitePress docs site and deploy it to the `docs-avagate-dev` GCS bucket under `sites/<folder>/`.

Reference an action by path and ref, for example:

```yaml
- uses: avagate/actions/deploy-vitepress-to-gcs@main
```
