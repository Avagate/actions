## Pulling changes

Releases force-move major tags (`v4`, …) to the latest semver on each release.
Do **not** use `git pull --tags` — Git refuses to overwrite the stale local tag.

After `pnpm install`, the `prepare` script configures this clone to:

- skip automatic tag fetch on pull (`remote.origin.tagOpt = --no-tags`)
- force-update `v*` tags on `git fetch` (`+refs/tags/v*:refs/tags/v*`)

Use:

```bash
git fetch origin && git pull origin main
```

Or rely on the editor's pull/fetch controls — `.vscode/settings.json` sets
`"git.pullTags": false` and `"git.fetchTags": false` for this workspace so the
IDE never adds `--tags` to pull/fetch.

## Changelog

`CHANGELOG.md` is kept up to date automatically by the `post-commit` hook in
`.githooks/post-commit` (activated by `pnpm install` via the `prepare` script,
which sets `core.hooksPath` to `.githooks`).

How it works:

- After each commit, the hook prepends `- <commit subject>. (\`<short sha>\`)` to the
  `## Unreleased` section and amends the change into the same commit.
- The hook stays out of the way when:
  - `CHANGELOG.md` is already part of the commit (you wrote your own entry).
  - The commit is a merge, revert, fixup, squash, or `chore(changelog)` /
    `chore(release)` commit.
  - The commit subject is a bare version number like `0.4.9` or `v1.2.3`.
  - A rebase, cherry-pick, revert, or merge is in progress.
  - The commit's short SHA is already present in `## Unreleased`.

What this means for you:

- Write a clear, single-line commit subject — it becomes the changelog entry.
- If you want a more detailed entry than the subject line, edit `## Unreleased`
  yourself and stage `CHANGELOG.md` as part of the commit. The hook will detect
  it and leave your entry alone.
- Don't add version numbers or dates manually. The release workflow
  (`.github/workflows/release.yml`) bumps the `version` field in `package.json`
  and renames `## Unreleased` to `## <new version> - <YYYY-MM-DD>` when a
  maintainer triggers a release.
- Don't run version-bump commands locally (`pnpm version`); use the release
  workflow instead so the changelog and tags stay in sync.
