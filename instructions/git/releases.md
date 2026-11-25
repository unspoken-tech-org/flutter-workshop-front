# Releases and tags: front

Never create, move or delete a tag unless the user asks: `vX.Y.Z` publishes
the installer every app installs on its own from `/releases/latest`, and only
a new release undoes it. Workflow: `.github/workflows/release-flutter-windows.yml`.

- Semver: minor = feature, patch = fix, major = breaking change.
- Bump `version:` in `pubspec.yaml` to `X.Y.Z` in the release or hotfix PR,
  before the tag. The workflow refuses a tag whose `X.Y.Z` differs from the
  pubspec and publishes nothing: fix the pubspec by PR, delete the tag and
  create it again. CI fails a PR whose pubspec version is below the last final
  tag. The build takes the version from the tag (`--build-name`).
- `vX.Y.Z-rc.N` (with a dot) becomes a pre-release, ignored by
  `/releases/latest`. `vX.Y.Z` on the same commit as the approved rc becomes
  `latest`. A hotfix patch skips the rc. The API uses the same suffixes.
- `vX.Y.Z-rc.N-qa` builds the rc against the QA API (`.env-qa`); every other
  tag builds with `.env-prd`. The workflow drops `GITHUB_OWNER`/`GITHUB_REPO`
  from the QA build, so it never checks for updates (it would install the next
  prod final). Its installer replaces a prod install on the same machine: QA
  builds go on test machines only.
- `git tag -a vX.Y.Z -m "<notes in pt-BR>" <sha> && git push origin vX.Y.Z`.
  The final tag's message is the release note users see in the update dialog;
  an rc pre-release gets GitHub's generated notes (PRs since the last final).
- The API version it needs must already be in production.
- `release/X.Y` (optional, on request): cut from `main`, or from the released
  tag, to freeze a candidate or ship a hotfix while `main` is ahead. Tag there,
  merge fixes back into `main`, delete it at the next minor.
