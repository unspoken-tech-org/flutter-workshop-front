# Pull requests

- Base: `feat/<name>-<part>` into `feature/<name>`; `feature/<name>` into
  `main`; the rest into `main` (hotfix: `release/X.Y`). Always pass
  `gh pr create --base`.
- Title in commit format. Final feature PR: `feat(<name>): <what it delivers>`.
- Body: What, Why, How to test, Related (parent `feature/<name>`, paired PR in
  the other repo).
- Merge commit only (`gh pr merge --merge`), never squash or rebase. Merge only
  when the user asks.
- Small sub-PRs, draft while in progress. Before opening: tests and lint pass
  locally and the branch is up to date with its base.
- Final PR: every sub-PR merged, `main` merged in, tested in QA through an rc
  tagged on `feature/<name>` (`releases.md`); link that rc in the PR.
- The API merges and ships first. Contract changes are additive, so the front
  works with the API one version behind.
