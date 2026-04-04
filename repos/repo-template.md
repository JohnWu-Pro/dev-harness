# Repo Profile — [REPO NAME]

> Template for documenting a repository used in the CTRL agent pipeline.
> Fill in all sections. Agents will reference this file to match existing patterns.
> Sections marked `[ CONFIRM ]` were not determinable from static analysis — verify manually.

---

## 1. Overview

| Field | Value |
|---|---|
| **Repo name** | |
| **Local path** | |
| **GitHub remote** | |
| **Purpose** | |
| **Domain** | frontend \| backend \| full-stack |
| **Team / org** | |
| **Primary Jira project key** | |

---

## 2. Tech Stack

### Backend
| Field | Value |
|---|---|
| **Language** | |
| **Version** | |
| **Framework** | |
| **Framework version** | |
| **Build tool** | |
| **Database** | |
| **Database access** | |
| **Cache** | |
| **Auth** | |
| **Message queue / async** | |
| **Key libraries** | |

### Frontend
| Field | Value |
|---|---|
| **Language** | |
| **Version** | |
| **Framework** | |
| **Framework version** | |
| **Package manager** | |
| **State management** | |
| **Styling approach** | |
| **Component library** | |
| **Key libraries** | |

---

## 3. Project Structure

```
<paste annotated directory tree here>
```

Key directories:
| Path | Purpose |
|---|---|
| | |

---

## 4. Architecture Patterns

### Backend
- [ CONFIRM ] Request flow: `Controller → ? → ?`
- [ CONFIRM ] DTO / model mapping strategy:
- [ CONFIRM ] Error handling pattern:
- [ CONFIRM ] Pagination pattern:
- [ CONFIRM ] Logging approach:
- [ CONFIRM ] Transaction management:

### Frontend
- [ CONFIRM ] Component structure pattern:
- [ CONFIRM ] Data fetching pattern (REST calls, hooks, etc.):
- [ CONFIRM ] State management pattern:
- [ CONFIRM ] Routing:
- [ CONFIRM ] Error boundary / error handling:

---

## 5. Naming Conventions

### Backend
| Element | Convention | Example |
|---|---|---|
| Classes | | |
| Methods | | |
| Variables | | |
| Constants | | |
| Packages | | |
| Test classes | | |
| Database tables | | |
| API endpoints | | |

### Frontend
| Element | Convention | Example |
|---|---|---|
| Components | | |
| Files (components) | | |
| Files (utilities) | | |
| Functions | | |
| Variables | | |
| Constants | | |
| Test files | | |
| CSS classes | | |

---

## 6. Code Style

### Backend
- Style guide:
- Formatter:
- Static analysis tools:
- Coverage tool:
- Coverage minimum:

### Frontend
- Style guide:
- Linter:
- Formatter:
- Coverage tool:
- Coverage minimum:

---

## 7. Testing

### Backend
| Test type | Framework | Location | Naming |
|---|---|---|---|
| Unit | | | |
| Integration | | | |
| Contract | | | |
| E2E | | | |
| Mutation | | | |

### Frontend
| Test type | Framework | Location | Naming |
|---|---|---|---|
| Unit | | | |
| Integration | | | |
| E2E | | | |

**Run commands:**
```bash
# Unit tests
# Integration tests
# Full suite
```

---

## 8. Git Conventions

| Field | Value |
|---|---|
| **Main branch** | |
| **Integration branch** | |
| **Branch naming** | |
| **Commit message format** | |
| **PR target branch** | |
| **PR template location** | |

**Branch examples:**
```
feat/PROJ-123-short-description
fix/PROJ-456-short-description
```

---

## 9. API Conventions (Backend)

| Field | Value |
|---|---|
| **Base URL pattern** | |
| **Versioning strategy** | |
| **Auth header** | |
| **Standard response shape** | |
| **Error response shape** | |
| **Pagination shape** | |

**Endpoint examples:**
```
GET  /api/<resource>
POST /api/<resource>
```

---

## 10. Environment & Config

| Field | Value |
|---|---|
| **Config files** | |
| **Secrets management** | |
| **Environment profiles** | |
| **Required local setup** | |
| **Local run command** | |
| **Local ports** | |

---

## 11. CI/CD

| Field | Value |
|---|---|
| **CI system** | |
| **Pipeline location** | |
| **Triggered by** | |
| **Deploy on push to** | |
| **Environments** | |
| **Security scans** | |

---

## 12. Security Requirements

- [ CONFIRM ] PHI / PII handling requirements:
- [ CONFIRM ] Audit logging required:
- [ CONFIRM ] Auth model (roles, permissions):
- [ CONFIRM ] Input validation framework:
- Required security checks before merge:

---

## 13. Feature Flags

| Field | Value |
|---|---|
| **System** | |
| **How to define a new flag** | |
| **How to remove a flag** | |
| **Flag constant location** | |

---

## 14. Agent-Specific Notes

### Requirement Analyzer
- Things to watch for in tickets for this repo:

### Frontend Dev
- Design system / component library location:
- Mock server available:
- Figma link for design system:

### Backend Dev
- SQL review required before commit:
- PHI audit annotation required:
- Entity / migration process:

### Code Reviewer
- Checklist file location:
- Automated checks that will catch violations (don't duplicate):

### Tester
- How to run the local DB for integration tests:
- Known flaky test areas:

### Git Agent
- Branch base: `dev` or `main`:
- Symlink setup required:

### Docs Agent
- Where API docs are generated:
- Confluence space for this repo:
