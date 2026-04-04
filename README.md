# Dev Harness

Multi-agent Claude Code pipeline that completes a ticket end-to-end in one command.

## What it does

```
/implement <ticket-id> <repo-name>
# OR
/implement <task-id> <repo-name>
```

Runs 8 automated stages:

| Stage | Agent | What happens |
|---|---|---|
| 1 | `requirement-analyzer` + `dependency-analyzer` | Structured spec + Dependency check — in parallel |
| 2 | — | Create feature branch |
| 3 | `frontend-dev` + `backend-dev` | Implementation (parallel if full-stack) |
| 4 | `code-reviewer` | Code review, up to 3 iterations |
| 5 | `tester` | Tests written and run, up to 3 iterations |
| 6 | `git-agent` + `docs-agent` | Commit + docs proposal — in parallel |
| 7 | — | Docs approval (user confirms before anything is published) |
| 8 | `pr-preparer` | PR description written to `.dev-harness/pr/<task-id>.md` |

Output: local branch + `.dev-harness/pr/<task-id>.md` ready to copy into your PR.

---

## Installation

```bash
git clone <this-repo> ~/dev/work/dev-harness   # or wherever you cloned it
cd ~/dev/work/dev-harness
bash install.sh
```

`install.sh` copies everything into `~/.claude/`. It will not overwrite existing repo profiles.

---

## Setup: repo profiles

Each project needs a profile (saved at `~/.claude/repos/<repo-name>.md`). This tells the agents where the code lives, what stack it uses, naming conventions, git workflow, etc.

Run `/repo-profile-builder` from the target repo's directory — it analyzes the codebase and auto-generates a profile at `~/.claude/repos/<repo-name>.md`:

```
cd ~/dev/work/my-service
/repo-profile-builder
```

Then review the generated profile and fill in anything it couldn't detect (local paths, team conventions, etc.).

Profiles are personal (local paths differ per machine) — do not commit them to this repo.

---

## Requirements

- [Claude Code](https://claude.ai/claude-code) installed and authenticated
- Optional. Jira MCP configured (`mcp-atlassian`) — needed by `dependency-analyzer` and `requirement-analyzer`
- Optional. Figma MCP configured (optional) — used by `frontend-dev` when Figma links are present
- The target repo cloned locally at the path in your profile

---

## Files in this repo

```
commands/
  implement.md            — the /implement slash command (orchestrator)

agents/
  dependency-analyzer.md
  requirement-analyzer.md
  frontend-dev.md
  backend-dev.md
  code-reviewer.md
  tester.md
  git-agent.md
  docs-agent.md
  pr-preparer.md

skills/
  repo-context/
    SKILL.md            — auto-detects repo context from cwd; used by agents
  repo-profile-builder/
    SKILL.md            — analyzes a repo and generates a ~/.claude/repos/<name>.md profile

repos/
  repo-template.md      — template for creating a new repo profile
```

---

## Keeping up to date

```bash
git pull
bash install.sh
```

`install.sh` is idempotent — safe to re-run after pulling updates.
