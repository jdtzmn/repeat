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
