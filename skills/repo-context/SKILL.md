---
name: repo-context
description: >
  Loads codebase context from a repo profile in ~/.claude/repos/.
  Auto-detects the repo from the current working directory.
  Supports scoped output (frontend, backend, git, docs, pr, full).
  Use this skill whenever an agent or user needs to know about conventions,
  patterns, stack details, testing setup, git workflow, or any other
  repo-specific information — even if they don't say "repo-context" explicitly.
---

# repo-context skill

You are loading codebase context from a repo profile. Follow these steps precisely.

---

## Step 1 — Identify the repo name

**If a repo name was given explicitly** (e.g. `repo-context member-service backend`), use that name. Skip to Step 2.

**Otherwise, auto-detect from the current working directory:**

1. Read all files matching `~/.claude/repos/*.md` (exclude `repo-template.md`).
2. For each file, extract the `Local path` field from the Overview table (look for `**Local path**` in the markdown table).
3. Compare each local path against the current working directory (`cwd`). A match means the cwd starts with that path.
4. If multiple paths match (nested repos), use the most specific (longest) match.
5. If exactly one match is found, use that repo name (the filename without `.md`).
6. If no match is found, ask the user:
   > "I couldn't detect the repo from the current directory. Which one do you want?
   > Available: [list all profile names from ~/.claude/repos/, excluding repo-template]"
   Then stop and wait for the user's answer before continuing.

---

## Step 2 — Load the profile

Read `~/.claude/repos/<repoName>.md`.

If the file does not exist, respond:
> "No profile found for `<repoName>`. Create one by copying `~/.claude/repos/repo-template.md` to `~/.claude/repos/<repoName>.md` and filling in all sections."

Then stop.

---

## Step 3 — Determine the scope

Use the following scope-to-sections mapping:

| Scope | Sections to extract |
|---|---|
| `frontend` | §2 Tech Stack → Frontend, §3 Project Structure, §4 Architecture Patterns → Frontend, §5 Naming Conventions → Frontend, §6 Code Style → Frontend, §7 Testing → Frontend, §14 Agent-Specific Notes → Frontend Dev |
| `backend` | §2 Tech Stack → Backend, §3 Project Structure, §4 Architecture Patterns → Backend, §5 Naming Conventions → Backend, §6 Code Style → Backend, §7 Testing → Backend, §9 API Conventions, §12 Security Requirements, §13 Feature Flags, §14 Agent-Specific Notes → Backend Dev |
| `git` | §1 Overview (Repo name + Local path + Primary Jira project key only), §8 Git Conventions, §14 Agent-Specific Notes → Git Agent |
| `docs` | §1 Overview (Repo name + Purpose only), §14 Agent-Specific Notes → Docs Agent |
| `pr` | §1 Overview, §8 Git Conventions (PR target branch + PR template location only), §14 Agent-Specific Notes → Code Reviewer |
| `full` | All sections (§1 through §14) |
| *(none / default)* | §1 Overview, §2 Tech Stack, §3 Project Structure, §4 Architecture Patterns |

**If no scope was provided**, infer it from the user's question using these hints:
- Mentions "naming", "conventions", "style", "linting", "formatting", "component", "hook", "CSS" → `frontend`
- Mentions "API", "endpoint", "controller", "service", "entity", "database", "migration", "JPA", "SQL", "security", "PHI", "audit", "feature flag" → `backend`
- Mentions "commit", "branch", "PR", "pull request", "git", "push", "merge" → `git`
- Mentions "docs", "Confluence", "documentation" → `docs`
- Mentions "review", "checklist", "reviewer" → `pr`
- Mentions "full", "everything", "all", "complete profile" → `full`
- Mentions "test", "testing", "jest", "junit", "integration test" → include both frontend and backend testing sections (use `full` if unsure)
- General or unclear question → use default (§1–§4)

---

## Step 4 — Extract and return

Extract only the sections matching the scope from the loaded profile. Return them verbatim (preserve all markdown formatting, tables, code blocks).

**For human queries**, prepend a one-line header before the content:
```
## Repo context: <repoName> [<scope>]
```

**For agent use** (called programmatically from another agent or command), return the sections directly with no preamble or header.

---

## Invocation examples

```
# Human — auto-detect repo, infer scope from question
"what are the naming conventions here?"

# Human — explicit repo, infer scope from question
"show me the testing setup for os-person-service"

# Human — explicit repo and full scope
"give me the full context for web-core"

# Agent — explicit repo and scope (programmatic)
repo-context os-person-service backend

# Agent — explicit repo and scope
repo-context web-core git
```
