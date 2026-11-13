#!/usr/bin/env bash
set -euo pipefail

# gh-clone: Clone GitHub repos to ~/workspace/github/<owner>/<repo>
# If repo exists locally, pull latest changes instead.

input="${1:-}"

if [ -z "$input" ]; then
    echo "Usage: gh-clone <owner/repo> | <https://github.com/owner/repo>" >&2
    exit 1
fi

# Strip trailing slash and .git suffix
input="${input%/}"
input="${input%.git}"

# Parse owner/repo from URL or shorthand
if [[ "$input" =~ ^https?://github\.com/([^/]+)/([^/]+)$ ]]; then
    owner="${BASH_REMATCH[1]}"
    repo="${BASH_REMATCH[2]}"
elif [[ "$input" =~ ^([^/]+)/([^/]+)$ ]]; then
    owner="${BASH_REMATCH[1]}"
    repo="${BASH_REMATCH[2]}"
else
    echo "Error: Could not parse '$input'. Expected formats:" >&2
    echo "  gh-clone owner/repo" >&2
    echo "  gh-clone https://github.com/owner/repo" >&2
    exit 1
fi

target="$HOME/workspace/github/$owner/$repo"

if [ -d "$target/.git" ]; then
    echo "Already exists at $target — pulling latest..."
    git -C "$target" pull --rebase
else
    echo "Cloning $owner/$repo to $target..."
    mkdir -p "$(dirname "$target")"
    git clone "https://github.com/$owner/$repo.git" "$target"
fi
