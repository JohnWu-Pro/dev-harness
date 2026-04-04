# /implement — Single-ticket pipeline

Run the full multi-agent pipeline for a ticket against a local repo.

A ticket may be a "User Story", a "Technical Story", or a "Defect".

**Usage:**
* `/implement <ticket-id> <repo-name>`, OR
* `/implement <task-id> <repo-name>`

**Example:**
* `/implement MEMBER-003 pickleball-club`, OR
* `/implement MEMBER-003.02 pickleball-club`

---

## Instructions

Parse `$ARGUMENTS` to extract:
- `ticketId` — the first argument (e.g. `MEMBER-003`)
- `taskId` — the first argument (e.g. `MEMBER-003.02`, in which the `ticketId` is `MEMBER-003` and the `subTaskSeq` is `02`)
- `repoName` — the second argument (e.g. `pickleball-club`)

If either argument is missing, stop and tell the user the correct usage.

If the first argument is `ticketId` (e.g. `MEMBER-003`) not `taskId` (e.g. `MEMBER-003.02`), go to Stage 1 (with the `ticketId`); otherwise, go to Stage 2 (with the parsed `ticketId` and `taskId`).

Read `~/.claude/repos/<repoName>.md` to load the repo context. If the file does not exist, stop and tell the user to create it from the template at `~/.claude/repos/repo-template.md`.

Store the full repo context content as `repoContext`.

**Extract scoped context slices from `repoContext`** (do this inline, once, before spawning any agents):
- `repoContextFrontend` — UI stack, component conventions, frontend paths, asset handling, frontend test setup
- `repoContextBackend` — server stack, API conventions, DB/ORM patterns, backend paths, backend test setup
- `repoContextGit` — repo path, base branch, commit message conventions
- `repoContextDocs` — Confluence space, doc locations, documentation conventions
- `repoContextPR` — PR template, target branch, review conventions

When a section fits multiple slices, include it in each. Error on the side of inclusion for ambiguous content.

---

## Stage 1 - Requirement Analyze and Dependency Check

Fetch the ticket from `docs/tickets.md` with all fields.

Spawn `requirement-analyzer` and `dependency-analyzer` in parallel (two Agent tool calls in the same response).

requirement-analyzer prompt:
```
Analyze {{ticketId}}.

REPO CONTEXT:
{{repoContext}}
```

dependency-analyzer prompt:
```
Analyze dependencies for {{ticketId}}.

REPO CONTEXT:
{{repoContextGit}}
```

Now wait for both agents to complete.
* If dependency-analyzer returns Verdict: BLOCKED — print the full DA report, tell the user the pipeline has been halted, and stop.
* Else-If requirement-analyzer output contains sub-tasks, prompt the user
  """
  Please review the spec and sub-tasks, and instruct the next step:
  1. Implement all sub-tasks one by one.
  2. Implement one sub-task (enter the two-digit sub-task sequence).
  3. Pause for now.
  """
* Else, prompt the user
  """
  Please review the spec, and instruct the next step:
  1. Implement the ticket.
  2. Pause for now.

Wait for the user's reply. If the user select
* Implement all sub-tasks one by one:
  * Iterate each sub-task to run through the rest stages, supply the `ticketId` and `taskId` (derive from the `ticketId` and the sub-task sequence).
* Implement one sub-task:
  * Run through the rest stages for the specified sub-task, supply the `ticketId` and `taskId` (derive from the `ticketId` and the entered sub-task sequence).
* Implement the ticket:
  * Run through the rest stages for the ticket, supply the `ticketId` and `taskId` (same as the `ticketId`).
* Pause for now:
  * Do not proceed further.

---

## Stage 2 - Create Task Branch

Read spec from `docs/specs/<TICKET-ID>.md`.

Create the task branch:
```bash
cd <repoPath from repoContext>
git fetch origin
git checkout <baseBranch>
git pull origin <baseBranch>
git checkout -b task/{{taskId}}-<short-description>
```

Derive `<short-description>` from `taskSummary`: lowercase, hyphen-separated, max 5 words.

Store the branch name as `branchName`. If the branch already exists, check it out instead of failing.

Print: `Branch created: {{branchName}}`

Extract `domainTags` from the `## Domain Tags` line in the spec (e.g. `frontend`, `backend`, `fullstack`).

---

## Stage 3 — Implementation

Route based on `domainTags`:

**If tags include both `frontend` and `backend` (or tag is `fullstack`):**
Spawn `frontend-dev` AND `backend-dev` in parallel (two Agent tool calls in the same response):

frontend-dev prompt:
```
Implement {{taskId}}.

SPEC:
{{spec}}

REPO CONTEXT:
{{repoContextFrontend}}

You may only write files within the repo path specified in REPO CONTEXT. Do not write files outside this path.
```

backend-dev prompt:
```
Implement {{taskId}}.

SPEC:
{{spec}}

REPO CONTEXT:
{{repoContextBackend}}

You may only write files within the repo path specified in REPO CONTEXT. Do not write files outside this path.
```

Wait for both to complete. Store results as `feResult` and `beResult`.

**If tags include only `frontend`:**
Spawn `frontend-dev` only with the same prompt above. Store result as `feResult`. Set `beResult` to empty.

**If tags include only `backend`:**
Spawn `backend-dev` only with the same prompt above. Store result as `beResult`. Set `feResult` to empty.

---

## Stage 4 — Code Review Loop (max 3 iterations)

Set `reviewIteration` to 1.

**Loop:**

Spawn `code-reviewer` with this prompt:

```
Review the implementation for {{taskId}}.

SPEC:
{{spec}}

REPO CONTEXT:
{{repoContext}}

Discover what was changed by running:
  git -C <repoPath> diff origin/<baseBranch>...HEAD

Review the diff against the spec for correctness, security, and conventions.
```

Wait for result. Store as `reviewResult`.

Parse the verdict:
- If `Verdict: APPROVED` — continue to Stage 5.
- If `Verdict: CHANGES REQUESTED`:
  - If `reviewIteration` >= 3: halt, tell the user max review iterations reached and manual review is needed, stop.
  - Otherwise: increment `reviewIteration`. Re-run the relevant impl agents (frontend-dev if `[BLOCK]` comments reference frontend files, backend-dev if they reference backend files, both if both), passing the review feedback so they know exactly what to fix:

    frontend-dev re-run prompt (if applicable):
    ```
    Fix review issues in {{taskId}}.

    SPEC:
    {{spec}}

    REVIEW FEEDBACK (address all [BLOCK] comments):
    {{reviewResult}}

    REPO CONTEXT:
    {{repoContextFrontend}}

    Read the existing code before making changes. Only modify what the feedback requires.
    ```

    backend-dev re-run prompt (if applicable):
    ```
    Fix review issues in {{taskId}}.

    SPEC:
    {{spec}}

    REVIEW FEEDBACK (address all [BLOCK] comments):
    {{reviewResult}}

    REPO CONTEXT:
    {{repoContextBackend}}

    Read the existing code before making changes. Only modify what the feedback requires.
    ```

  Update `feResult` / `beResult` with the new output. Repeat the loop.

---

## Stage 5 — Test Loop (max 3 iterations)

Set `testIteration` to 1.

**Loop:**

Spawn `tester` with this prompt:

```
Test the implementation for {{taskId}}.

SPEC:
{{spec}}

REVIEW RESULT:
{{reviewResult}}

REPO CONTEXT:
{{repoContext}}

Discover what was changed by running:
  git -C <repoPath> diff origin/<baseBranch>...HEAD

Write and run tests against the spec's acceptance criteria.
```

Wait for result. Store as `testResult`.

Parse the result:
- If `Result: PASSED` — continue to Stage 6.
- If `Result: FAILED` or `Result: PARTIAL`:
  - If `testIteration` >= 3: halt, tell the user max test iterations reached and manual fixes are needed, stop.
  - Otherwise: increment `testIteration`. Re-run the impl agents assigned to the failures (check `Assigned to:` field in the test report), passing the failure details so they know what to fix:

    frontend-dev re-run prompt (if applicable):
    ```
    Fix test failures in {{taskId}}.

    SPEC:
    {{spec}}

    TEST FAILURES (fix these):
    {{testResult}}

    REPO CONTEXT:
    {{repoContextFrontend}}

    Read the existing code before making changes. Only modify what the failures require.
    ```

    backend-dev re-run prompt (if applicable):
    ```
    Fix test failures in {{taskId}}.

    SPEC:
    {{spec}}

    TEST FAILURES (fix these):
    {{testResult}}

    REPO CONTEXT:
    {{repoContextBackend}}

    Read the existing code before making changes. Only modify what the failures require.
    ```

  Update `feResult` / `beResult`. Then run code review on the updated code before re-testing:

  Spawn `code-reviewer` with:
  ```
  Review the updated implementation for {{taskId}} (post-test fix).

  SPEC:
  {{spec}}

  REPO CONTEXT:
  {{repoContext}}

  Discover what was changed by running:
    git -C <repoPath> diff origin/<baseBranch>...HEAD

  Focus on the changes made to fix the failing tests. Flag any new issues introduced.
  ```

  If the reviewer returns `Verdict: CHANGES REQUESTED`, apply the same re-implementation logic from Stage 4 before continuing. Update `reviewResult`. Then repeat the test loop.

---

## Stage 6 — Git + Docs (parallel)

Spawn `git-agent` AND `docs-agent` in parallel (two Agent tool calls in the same response).

git-agent prompt:
```
Commit the changes for {{taskId}}.

BRANCH (already created — do NOT create a new branch): {{branchName}}
CHILD TASK ID (use for commit message): {{childTaskId}}

SPEC (for commit message context only — do not re-implement):
{{spec}}

REPO CONTEXT:
{{repoContextGit}}

Use `git -C <repoPath> status` to discover changed files, then stage and commit them.
```

docs-agent prompt:
```
Update docs for {{taskId}}.

SPEC:
{{spec}}

REPO CONTEXT:
{{repoContextDocs}}

Read relevant changed files in the repo if you need implementation details.
```

Wait for both to complete. Store results as `gitResult` and `docsProposal`.

---

## Stage 7 — Docs Approval

Print the full `docsProposal` to the user.

**If the docs-agent returned `Documentation warranted: NO`:**
Set `docsResult` to the docs-agent's message and continue without pausing.

**If the docs-agent returned `Documentation warranted: YES`:**

Ask the user:

> The docs agent has proposed documentation updates for {{taskId}} (shown above).
> Reply with: **approve all**, **select items** (list which ones), or **skip**.

Wait for the user's reply.

- If the user replies **skip**: set `docsResult` to `"Documentation skipped by user."` and continue without spawning another agent.
- Otherwise: spawn `docs-agent` with the user's decision:

  ```
  Update docs for {{taskId}} — user decision: {{userDocsDecision}}

  ORIGINAL PROPOSAL:
  {{docsProposal}}

  SPEC:
  {{spec}}

  REPO CONTEXT:
  {{repoContextDocs}}
  ```

  Store the result as `docsResult`.

---

## Stage 8 — PR Preparer

Spawn `pr-preparer` with this prompt:

```
Prepare PR for {{taskId}}.

SPEC:
{{spec}}

REVIEW RESULT:
{{reviewResult}}

TEST RESULT:
{{testResult}}

GIT RESULT:
{{gitResult}}

DOCS RESULT:
{{docsResult}}

REPO CONTEXT:
{{repoContextPR}}

For implementation details, run:
  git -C <repoPath> diff origin/<baseBranch>...HEAD
```

Wait for result. Store as `prResult`.

The PR description is written to `.dev-harness/pr/{{taskId}}.md` by the pr-preparer agent.

---

## Final Summary

Print:

```
Pipeline complete for {{taskId}}.

Branch:          (from gitResult)
Commit:          (from gitResult)
PR description:  .dev-harness/pr/{{taskId}}.md

Review:          (APPROVED / iterations used)
Tests:           (PASSED / iterations used)
Docs:            (summary from docsResult)

Next step: Review the branch locally, then push and open a PR.
```
