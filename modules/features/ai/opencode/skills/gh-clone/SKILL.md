---
name: gh-clone
description: >
  Clone GitHub repos to local workspace for inspection.
  When agents need to examine code or docs from a GitHub project,
  use `gh-clone` to fetch the repo locally, then read local files.
---

# gh-clone — Clone GitHub repos to local workspace

## Purpose

Avoid re-fetching from GitHub repeatedly. Clone once to
`~/workspace/github/<owner>/<repo>` and work with local files.
If repo already exists, pull latest changes instead of re-cloning.

## Usage

```bash
# Via just (gj) — preferred for agents:
gj gh-clone <input>

# Direct command:
gh-clone <input>
```

## Input formats accepted

| Format | Example |
|--------|---------|
| `owner/repo` | `neovim/neovim` |
| Full URL | `https://github.com/neovim/neovim` |
| URL with `.git` | `https://github.com/neovim/neovim.git` |

## Behavior

- Clones to `~/workspace/github/<owner>/<repo>`
- If directory + `.git` exists: `git pull --rebase`
- Creates parent directories as needed
- Idempotent — safe to run repeatedly

## When to Use

- Need to inspect source code of a GitHub dependency
- Need to check documentation from a GitHub project
- Need to understand how another tool/library works
- Avoid hitting GitHub API/rate limits for repeated access
