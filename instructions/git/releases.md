# Releases and tags: front

Never create, move or delete a tag unless the user asks: `vX.Y.Z` publishes
the installer every app installs on its own from `/releases/latest`, and only
a new release undoes it. Workflow: `.github/workflows/release-flutter-windows.yml`.

- Semver: minor = feature, patch = fix, major = breaking change.
- The build takes the version from the tag: do not bump `pubspec.yaml`.
- `vX.Y.Z-rc.N` (with a dot) becomes a pre-release, ignored by
  `/releases/latest`. `vX.Y.Z` on the same commit as the approved rc becomes
  `latest`. A hotfix patch skips the rc. The API uses the same suffixes.
- `git tag -a vX.Y.Z -m "<notes in pt-BR>" <sha> && git push origin vX.Y.Z`.
  The tag message is the release note users see.
- The API version it needs must already be in production.
- `release/X.Y` (optional, on request): cut from `main`, or from the released
  tag, to freeze a candidate or ship a hotfix while `main` is ahead. Tag there,
  merge fixes back into `main`, delete it at the next minor.
