# Commits

- `<type>(<scope>): <summary>` in English, imperative, lower case, no period,
  at most 72 chars. Types: `feat`, `fix`, `refactor`, `test`, `docs`, `ci`,
  `build`, `chore`, `perf`.
- One commit per scope; a refactor apart from a behavior change. Every commit
  builds and passes the tests.
- Breaking the API contract with the front: `feat(api)!:` plus a
  `BREAKING CHANGE:` footer, which means a major version. Ask first.
- Fold "wip" commits with `git rebase -i` only on your own sub-branch, before
  its PR. Never rewrite pushed commits of a shared branch.
- Never commit `.env`, `.env-*` or `.secrets/`.
