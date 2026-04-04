---
name: repo-profile-builder
description: >
  Analyzes a local repository and auto-populates a repo profile file for the dev-harness pipeline.
  Writes the filled profile to ~/.claude/repos/<repo-name>.md so the repo is ready for /implement.
  Use this skill whenever a user wants to set up a new repo for the dev-harness pipeline, asks how to
  onboard a project, says "add this repo to dev-harness", or wants to create/generate a repo profile.
  Trigger even if the user just says "set up dev-harness for this repo" or "I want to use dev-harness here".
---

# repo-profile-builder

You are doing a one-time static analysis of a local repository to populate a repo profile for the
dev-harness agent pipeline. The goal is to fill in as much as possible from the code itself, mark
genuinely uncertain things as `[ CONFIRM ]`, and produce a profile the developer only needs to
spot-check rather than write from scratch.

Good detection is better than conservative blanks. If you can see it in the code, write it in.

---

## Step 1 — Identify the target repo

If a repo path or name was given explicitly, use it. Otherwise use the current working directory.

Confirm the path is a git repo:
```bash
git -C <path> rev-parse --show-toplevel
```

If this fails, tell the user the path is not a git repo and stop.

Set `repoPath` to the absolute local path. Set `repoName` to the directory name (last segment of the path).

---

## Step 2 — Discovery phase

Run all of these before writing anything. Collect the results — you'll draw on them in every section.

### Git info
```bash
git -C <repoPath> remote get-url origin        # remote URL
git -C <repoPath> branch -r                    # all remote branches
git -C <repoPath> log --oneline -20            # recent commit messages
git -C <repoPath> symbolic-ref refs/remotes/origin/HEAD  # default branch
```

### Directory structure
```bash
# Top-level layout (2 levels deep, excluding .git, node_modules, target, build)
find <repoPath> -maxdepth 2 -not -path '*/.git/*' -not -path '*/node_modules/*' \
  -not -path '*/target/*' -not -path '*/build/*' -not -path '*/.gradle/*' | sort
```

### Key config files to read (read whichever exist)
- `pom.xml` or `*/pom.xml` — Java version, Spring Boot version, dependencies, Maven plugins
- `*/mvnw` presence — Maven Wrapper available
- `build.gradle` or `build.gradle.kts` — Gradle stack
- `package.json` or `*/package.json` — Node/frontend stack
- `tsconfig.json` or `*/tsconfig.json` — TypeScript confirmation
- `.eslintrc*` or `*/eslintrc*` — ESLint config
- `.prettierrc*` — Prettier config
- `application.properties` or `*/application.properties` — Spring config, profiles
- `application.yml` or `*/application.yml` — Spring YAML config
- `docker-compose.yml` or `Dockerfile` — local infra
- `.github/workflows/*.yml` — CI pipeline
- `Jenkinsfile` — Jenkins pipeline
- `.github/pull_request_template.md` — PR template
- `checkstyle*.xml` — Checkstyle rules
- `CODE_REVIEW_GUIDELINES.md` or `CONTRIBUTING.md` — project conventions

### Sample source files
Pick 2–3 existing source files to infer patterns (controller, service, test):
```bash
# Find controller files
find <repoPath> -name "*Controller*.java" | head -3
# Find service files
find <repoPath> -name "*Service*.java" | head -2
# Find test files
find <repoPath> -name "*Test*.java" -o -name "*.test.tsx" -o -name "*.test.ts" | head -3
# Find migration files
find <repoPath> -name "*.sql" -path "*/migration*" -o -name "V*.sql" | head -3
```

Read 1–2 of each to see actual patterns (imports, annotations, naming, structure).

---

## Step 3 — Fill the template section by section

Use the evidence gathered in Step 2. For each field, either fill it in or mark it `[ CONFIRM ]`.
Only use `[ CONFIRM ]` when you genuinely cannot determine the value from what you've read.
When you mark `[ CONFIRM ]`, add a short hint: `[ CONFIRM ]` — check `<file>`.

### Section 1 — Overview

| Field | How to detect |
|---|---|
| Repo name | Directory name of `repoPath` |
| Local path | `repoPath` |
| GitHub remote | From `git remote get-url origin` |
| Purpose | Infer from README, CONTRIBUTING.md, or repo name — make a reasonable guess and mark `[ CONFIRM ]` |
| Domain | `backend` if only pom.xml; `frontend` if only package.json; `full-stack` if both |
| Team / org | From GitHub remote URL (org portion) — mark `[ CONFIRM ]` for the team name |
| Primary Jira project key | Look in recent commit messages for a pattern like `PROJ-1234` — extract the prefix. If none, mark `[ CONFIRM ]` |

### Section 2 — Tech Stack

**Backend** (if pom.xml / build.gradle exists):
- Language: Java (if pom.xml) or Kotlin (if .kts)
- Java version: look for `<java.version>` or `<maven.compiler.source>` in pom.xml, or `sourceCompatibility` in gradle
- Framework: Spring Boot if `spring-boot-starter-parent` in pom.xml; plain Spring MVC if `spring-webmvc` without Boot
- Framework version: `<parent><version>` in pom.xml for Spring Boot
- Build tool: Maven (with or without wrapper based on `mvnw` presence) or Gradle
- Database: look for `mssql`, `postgresql`, `mysql`, `h2` driver deps in pom.xml
- Database access: look for `spring-data-jpa`, `jdbctemplate`, `mybatis`, `hibernate` deps
- Cache: look for `spring-data-redis`, `caffeine`, `ehcache` deps
- Auth: look for `spring-security`, `oauth2`, `jwt` deps
- Message queue: look for `kafka`, `rabbitmq`, `activemq`, `transactionoutbox` deps
- Key libraries: list notable non-framework dependencies (Lombok, MapStruct, Flyway, Liquibase, etc.)

**Frontend** (if package.json exists):
- Language: TypeScript if `typescript` in deps; JavaScript otherwise
- Framework: React if `react` dep; Vue if `vue`; Angular if `@angular/core`; plain JSP if no package.json in a Spring MVC project
- Framework version: from `react` version in package.json
- Package manager: check for `yarn.lock` (Yarn), `pnpm-lock.yaml` (pnpm), `package-lock.json` (npm)
- State management: look for `redux`, `zustand`, `recoil`, `@tanstack/react-query`, `mobx` in deps
- Styling: look for `tailwindcss`, `styled-components`, `@emotion`, `sass`, `.css` patterns in source
- Component library: look for `@mui`, `antd`, `@chakra-ui`, `@radix-ui` in deps
- Key libraries: Jest, React Testing Library, ESLint, Axios, etc.

### Section 3 — Project Structure

Generate an annotated tree from the `find` output. Group directories and annotate the obvious ones:
- `api/` or `src/main/java/` → backend source
- `ui/` or `frontend/` or `src/` (if React project) → frontend source
- `src/test/` → tests
- `.github/workflows/` → CI pipelines
- `src/main/resources/` → config files
- `db/migration/` or `resources/db/` → database migrations

For the key directories table, list only the most important 5–8 paths.

### Section 4 — Architecture Patterns

Read 1–2 controller files and 1–2 service files to infer:
- Request flow: trace the annotation chain (`@RestController` → `@Service` → `@Repository`, etc.)
- DTO mapping: look for dedicated mapper classes, MapStruct, or inline mapping in controllers
- Logging: look for `@Slf4j`, `LoggerFactory`, `log.info` patterns
- Error handling: look for `@ControllerAdvice` / `@ExceptionHandler` classes
- Transaction management: look for `@Transactional` usage
- Frontend patterns: read a component or two to see hooks vs class components, data fetching style

Mark things `[ CONFIRM ]` only for things that genuinely need runtime verification (pagination shape,
exact error response format, etc.).

### Section 5 — Naming Conventions

Sample filenames and class names from actual source files to fill these in. Most of these are
determinable from file listing alone — PascalCase files = components, camelCase = utilities, etc.
Infer database table naming from migration files or entity `@Table` annotations.

### Section 6 — Code Style

Look for:
- `checkstyle.xml` or `checkstyle-*.xml` → Checkstyle present
- `.eslintrc*` / `eslint.config*` → ESLint, often Airbnb or project-specific config
- `.prettierrc*` → Prettier
- Jacoco plugin in pom.xml → coverage tool and possibly minimum
- `sonar-project.properties` or Sonar plugin → SonarQube
- Git hooks in `package.json` scripts (husky, lint-staged) → auto-format on commit

### Section 7 — Testing

Look for:
- Backend: JUnit 4 vs JUnit 5 in pom.xml deps, Mockito, test directories, naming of existing test files
- Frontend: Jest in package.json, `@testing-library/react`, Cypress, Playwright
- Maven profiles named `test`, `integration-test`, `long-running-tests`, `FullBuild`, `FastBuild` in pom.xml
- Existing `.run/` IntelliJ configs for test types

For run commands, produce the actual commands that work for this repo (based on build tool and Maven
Wrapper presence).

### Section 8 — Git Conventions

From `git log --oneline -20`, identify:
- Commit message format (look for conventional commits `feat:`, ticket-prefix `PROJ-123 description`, etc.)
- Jira ticket prefix (if found)
From `git branch -r`, identify:
- Main branch (`main` vs `master` vs `trunk`)
- Integration branch (`dev`, `develop`, `staging`, etc.)
- Branch naming pattern from existing branches
Look for `.github/pull_request_template.md` for PR template.

### Sections 9–13

Fill these from what you've found:
- **9 (API)**: scan a controller file for `@RequestMapping` base paths to establish URL patterns
- **10 (Env/Config)**: list all `application*.properties` / `application*.yml` files found; check for `.env` files, docker-compose
- **11 (CI/CD)**: read `.github/workflows/*.yml` or `Jenkinsfile` — extract trigger conditions, deploy targets
- **12 (Security)**: list security-relevant deps found (Spring Security, OAuth2, audit libs); mark specifics `[ CONFIRM ]`
- **13 (Feature flags)**: look for Optimizely, LaunchDarkly, Unleash deps or imports

### Section 14 — Agent-Specific Notes

Use everything you've found to give each agent a useful starting point:

- **Requirement Analyzer**: note the Jira key (if detected), any domain-specific requirements visible in the codebase (PHI annotations, audit requirements)
- **Frontend Dev**: note design system / component library location from source structure; whether a mock server exists (`mock`, `msw`, `json-server` deps); `[ CONFIRM ]` Figma link
- **Backend Dev**: note whether SQL review prompt exists (`.github/prompts/`); whether PHI audit annotations are present; migration tool (Flyway/Liquibase); build commands
- **Code Reviewer**: note checklist files found (`CODE_REVIEW_GUIDELINES.md`, `CONTRIBUTING.md`); automated checks that are already wired up
- **Tester**: note how to run tests (commands from Section 7); any IntelliJ `.run/` configs found; database setup files for integration tests
- **Git Agent**: branch base (from Section 8); any symlink setup (`git config core.symlinks`) if symlinks detected in the repo
- **Docs Agent**: whether Javadoc/JSDoc generation is in the build; `[ CONFIRM ]` Confluence space

---

## Step 4 — Write the profile

Write the completed profile to `~/.claude/repos/<repoName>.md`.

Use this header (not the template's boilerplate):
```
# Repo Profile — <repoName>

> Generated from static analysis of `<repoPath>`.
> Sections marked `[ CONFIRM ]` require manual verification from the developer.
```

Follow with all 14 sections, filled in as completely as possible.

---

## Step 5 — Report to the user

After writing the file, print:

```
Profile written to: ~/.claude/repos/<repoName>.md

Auto-detected:
  ✓ <list of fields that were filled in confidently>

Needs confirmation ([ CONFIRM ] items):
  • <field> — <what to check and where>
  • ...

Next steps:
  1. Open ~/.claude/repos/<repoName>.md and verify the [ CONFIRM ] items above.
  2. Run: /implement <TICKET-ID> <repoName>
```

Keep the "needs confirmation" list short and actionable — group related items if there are many.
