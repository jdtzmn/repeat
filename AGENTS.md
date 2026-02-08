# AGENTS.md

## Port worktree workflow

This repository is configured for `port` so contributors can use Port-managed git worktrees.

- Initialize once (already done): `port init`
- Create or enter a branch worktree: `port <branch-name>`
- List worktrees: `port list`
- Remove a worktree when done: `port remove <branch-name>`

Example:

```bash
port feature/habit-visualization
```

That opens a subshell in `.port/trees/feature-habit-visualization`.

## Notes for this repo

- This project is currently an iOS/Xcode app and does not rely on Docker Compose for local development.
- Use Port primarily for worktree management here.
- `port up` / `port down` are not required for the default workflow in this repository.

## Suggested dev flow in a worktree

1. `port <branch-name>`
2. Open `Repeat.xcodeproj` in that worktree path.
3. Run local checks as needed:
   - `make lint`
   - `make lint-format`
   - `make test`

## Beads workflow

Use `bd` as the task tracker for this repository.

- Check available tasks: `bd ready`
- View all tasks: `bd list --limit 20`
- Create a task: `bd create --title "..." --type task --priority 1`
- Claim/start a task: `bd update <id> --claim`
- Update status/notes: `bd update <id> --notes "..."`
- Close completed work: `bd close <id> --reason "..."`

Important:

- Do not use `bd edit` (interactive editor).
- Prefer `bd update` flags for non-interactive updates.
- Run `bd sync` after making multiple issue changes to flush JSONL/git state.
