# Personal default rules

Development-workflow rules for any coding agent.

## Git & commits
- Do NOT commit automatically. Never run `git commit` (or `git push`) on your own initiative.
- When you finish a task or a meaningful chunk of work, stop and explicitly tell me the change is ready for my review. Summarize what changed and let me review it.
- Only create a commit when I explicitly ask you to (e.g. "commit this", "commit now"). A general instruction to do a task is NOT permission to commit.
- The same applies to pushing, opening PRs, and other outward-facing git actions — wait for an explicit request.

## Parallel work with git worktrees
When I want to work on a feature without disturbing the branch and files currently checked out — e.g. another agent session is mid-task on `main` — use a git worktree instead of switching branches in place. Prefer this over stashing or cloning.

- ALWAYS create a new branch AND a worktree FIRST, before starting any of the actual work. Do not touch files for a parallel task until the branch and worktree exist.
- Branch off `main` by default — unless I explicitly name a different base to branch from.
- Branch naming follows a commitlint-style convention: `<type>/<short-kebab-description>`, e.g. `feat/name-of-feature`, `docs/name-of-branch`, `fix/…`, `chore/…`, `refactor/…`. Pick the `type` prefix that matches the nature of the work.
- A worktree is a linked working directory that shares the one repository — NOT a new clone. Branches, commits, and stashes are shared instantly; there is only ever one `.git` object store. Git forbids checking out the same branch in two worktrees at once — that rule is the collision guard between parallel sessions, so lean on it.
- Layout: put worktrees in a sibling directory `<repo>.worktrees/<branch>/`. Never nest a worktree inside the checkout — nesting confuses file watchers/tooling and risks committing the worktree by accident.
- Create off the base branch: `git -C <repo> worktree add ../<repo>.worktrees/<type>/<name> -b <type>/<name> <base>` (base is usually `main`).
- After creating, run that repo's setup before working — gitignored deps/build artifacts and any env files are NOT carried into a fresh worktree. Install dependencies with the repo's package manager and copy over any gitignored env files from the main checkout; infer the steps from the repo's docs/scripts. A fresh worktree that skips this looks "broken" but just isn't set up.
- Cleanup: `git worktree list` to see them; when a branch is merged, `git worktree remove <path>` (add `--force` if it warns) then `git worktree prune`.
