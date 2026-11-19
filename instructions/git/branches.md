# Branches

| Change | From | Name | PR into |
| --- | --- | --- | --- |
| Multi-PR feature (only when the user asks) | `main` | `feature/<name>` | `main`, once, when complete |
| Part of that feature | `feature/<name>` | `feat/<name>-<part>` | `feature/<name>` |
| Single-PR change | `main` | `<type>/<desc>` (commit type) | `main` |
| Prod bug, `main` releasable | `main` | `fix/<desc>` | `main`, then patch tag |
| Prod bug, `main` not releasable | `release/X.Y`, cut from the prod tag | `fix/<desc>` | `release/X.Y`, patch tag, then merge into `main` |
| Bug only inside a feature | `feature/<name>` | `fix/<desc>` | `feature/<name>`, no tag |

- Names in kebab-case. A feature spanning API and front uses the same
  `feature/<name>` in both repos.
- `release/X.Y` only when the user asks (see `releases.md`).
- `feature/<name>` is shared: bring `main` into it weekly with a PR
  (`gh pr create --base feature/<name> --head main`), never rebase it. A
  sub-branch may be rebased only before its PR opens.
- `main`, `feature/*` and `release/*` take changes only through PRs (rulesets
  block direct and force pushes). `v*` tags cannot be moved or deleted.
- Merged branches can be deleted. To find a bug, `git bisect --first-parent`.
