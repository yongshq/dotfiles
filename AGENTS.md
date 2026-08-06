# Personal default rules

Development-workflow rules for any coding agent.

## Git & commits
- Do NOT commit automatically. Never run `git commit` (or `git push`) on your own initiative.
- When you finish a task or a meaningful chunk of work, stop rather than rolling on. Summarize what changed, then follow the handoff signals below.
- Only create a commit when I explicitly ask you to (e.g. "commit this", "commit now"). A general instruction to do a task is NOT permission to commit.
- The same applies to pushing, opening PRs, and other outward-facing git actions — wait for an explicit request.

### Signal at each handoff point
Rather than advancing on your own, stop and say where things stand. Each of these is a handoff, not permission to proceed:

1. **Work finished / on standby** — summarize what changed, then *ask* whether to run a code review or skip it. Don't start reviewing unprompted, and don't just park on "ready for review" waiting for me to decide.
2. **After a code review** — on top of the detailed findings, give a top-level verdict: are there issues or not. If it's all clean, say so *and* highlight that it's ready to commit. Skipping the review skips only the review, never this signal: if I skip, still come back and tell me the changes are ready to commit.
3. **After a commit made in a worktree** — tell me it's ready to be rebased onto `main`.
4. **After the merge/rebase lands** — clean up: delete the feature/fix branch, remove the worktree and its directory, and shut down any dev servers started during the session.
5. **Finally** — give me a checklist of those cleanup steps plus a confirmation that everything is done.

Steps 1–2 apply to any work. Steps 3–5 are worktree-specific; when work happened directly on `main`, stop after step 2 and just note anything still running.

**Never drop out of the flow.** Skipping a step skips that step's *work*, not its signal — the sequence still runs to the end. And always close by telling me what's next: the specific next action and that it's waiting on me. Never leave me guessing where we are or what I'm meant to do.

## Parallel work with git worktrees
When I want to work on a feature without disturbing the branch and files currently checked out — e.g. another agent session is mid-task on `main` — use a git worktree instead of switching branches in place. Prefer this over stashing or cloning.

**This is the default.** Assume every new session in a repo works in parallel: branch + worktree first, before touching files. Working directly on `main` is the exception and needs me to say so explicitly ("we're working directly on main this session" or similar) — that then holds for the rest of the session.

Not a strict rule, though — judge by the task, and skip the worktree without asking when it plainly doesn't earn one:

- Read-only work: questions, code exploration, explaining, reviewing.
- A trivial one-liner, or a fix I'm watching land right now.
- Not a git repo, or the session is already inside a worktree / on a feature branch.
- The task is *about* the current checkout's working state (e.g. "review my uncommitted changes").

When it's genuinely borderline, say which way you're going in one line and keep moving — don't stall on a question.

**When you do spin one up:**

- ALWAYS create a new branch AND a worktree FIRST, before starting any of the actual work. Do not touch files for a parallel task until the branch and worktree exist.
- Branch off `main` by default — unless I explicitly name a different base to branch from.
- Branch naming follows a commitlint-style convention: `<type>/<short-kebab-description>`, e.g. `feat/name-of-feature`, `docs/name-of-branch`, `fix/…`, `chore/…`, `refactor/…`. Pick the `type` prefix that matches the nature of the work.
- A worktree is a linked working directory that shares the one repository — NOT a new clone. Branches, commits, and stashes are shared instantly; there is only ever one `.git` object store. Git forbids checking out the same branch in two worktrees at once — that rule is the collision guard between parallel sessions, so lean on it.
- Layout: put worktrees in a sibling directory `<repo>.worktrees/<name>/`, using a **flat** folder name — the kebab description only, with **no `<type>/` prefix in the path**. A slash in the path (e.g. `<repo>.worktrees/feat/<name>`) creates a nested `feat/` directory on disk, which is noise; keep the `<type>/` in the *branch name*, not the folder. Never nest a worktree inside the checkout either — nesting confuses file watchers/tooling and risks committing the worktree by accident.
- Create off the base branch: `git -C <repo> worktree add ../<repo>.worktrees/<name> -b <type>/<name> <base>` (base is usually `main`). Note the path uses the flat `<name>` while `-b` gets the full `<type>/<name>` branch — so the folder stays flat but the branch keeps its type prefix.
- After creating, run that repo's setup before working — gitignored deps/build artifacts and any env files are NOT carried into a fresh worktree. Install dependencies with the repo's package manager and copy over any gitignored env files from the main checkout; infer the steps from the repo's docs/scripts. A fresh worktree that skips this looks "broken" but just isn't set up.
- Cleanup: `git worktree list` to see them. A worktree and its branch are separate things — removing the folder doesn't delete the branch, so do both or the branch list quietly grows. How much to check first depends on whether you know what's in it:
  - **A worktree this session created, whose work is committed and merged** — just remove it, no need to ask: `git worktree remove <path>`, `git branch -d <branch>`, then `git worktree prune`. You watched everything that went into it; there's nothing to discover.
  - **Any other worktree** — pre-existing, or turned up during a tidy-up. Check before offering: `git status --porcelain` for uncommitted work, and the commit count against the base for work that never landed. Report what you find and let me pick.
  - **Never add `--force` or `-D` on your own.** A clean, merged worktree removes without them, so needing one means git found something you didn't expect — that refusal is the safety net, and past it uncommitted work is unrecoverable. Surface it and ask.
