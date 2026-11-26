# Pull requests

- Base: `feature/onda-<N>` or `feature/<name>` into `main`;
  `feat/<name>-<part>` into `feature/<name>`; the rest into `main` (hotfix:
  `release/X.Y`). Wave items open no PR (`branches.md`). Always pass
  `gh pr create --base`.
- Title in commit format. Final feature PR: `feat(<name>): <what it delivers>`;
  wave PR: `feat(onda-<N>): <what it delivers>`, with one line per item
  (`<ID>`, merge commit, evidence) in the body.
- Body: What, Why, How to test, Related (parent `feature/<name>`, paired PR in
  the other repo).
- Merge commit only (`gh pr merge --merge`), never squash or rebase. Merging a
  PR (into `main`, `release/*` or any `feature/*`) only when the user asks;
  wave items merge locally per `branches.md`.
- Small sub-PRs, draft while in progress. Before opening: tests and lint pass
  locally and the branch is up to date with its base.
- Final PR: every sub-PR or wave item merged, `main` merged in, tested in QA
  through an rc tagged on the `feature/*` branch (`releases.md`) when it changes
  runtime behavior; link that rc in the PR.
- The API merges and ships first. Contract changes are additive, so the front
  works with the API one version behind.
