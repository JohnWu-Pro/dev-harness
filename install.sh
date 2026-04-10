#!/usr/bin/env bash
# install.sh — copies dev-harness pipeline files into ~/.claude/
# Run this from the repo root after cloning.

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

echo "Installing dev-harness pipeline to $CLAUDE_DIR..."

# Create target directories if they don't exist
mkdir -p "$CLAUDE_DIR/commands"
mkdir -p "$CLAUDE_DIR/agents"
mkdir -p "$CLAUDE_DIR/skills/repo-context"
mkdir -p "$CLAUDE_DIR/skills/repo-profile-builder"
mkdir -p "$CLAUDE_DIR/repos"

# Commands
cp "$REPO_DIR/commands/implement.md" "$CLAUDE_DIR/commands/implement.md"
echo "  ✓ commands/implement.md"

# Agents
for f in "$REPO_DIR/agents/"*.md; do
  cp "$f" "$CLAUDE_DIR/agents/"
  echo "  ✓ agents/$(basename "$f")"
done

# Skills
cp "$REPO_DIR/skills/repo-context/SKILL.md" "$CLAUDE_DIR/skills/repo-context/SKILL.md"
echo "  ✓ skills/repo-context/SKILL.md"
cp "$REPO_DIR/skills/repo-profile-builder/SKILL.md" "$CLAUDE_DIR/skills/repo-profile-builder/SKILL.md"
echo "  ✓ skills/repo-profile-builder/SKILL.md"

# Repo template (only if not already present — don't overwrite personal profiles)
if [ ! -f "$CLAUDE_DIR/repos/repo-template.md" ]; then
  cp "$REPO_DIR/repos/repo-template.md" "$CLAUDE_DIR/repos/repo-template.md"
  echo "  ✓ repos/repo-template.md"
else
  echo "  ~ repos/repo-template.md already exists, skipping"
fi

echo ""
echo "Done."
echo ""
echo "Next steps:"
echo "  1. Restart Claude and ask it to 'set up dev-harness for this repo'"
echo "  2. Review the repo profile it creates and edit as needed (it uses the template you just installed)."
echo "  3. Use the dev-harness commands to implement your stories/tasks, e.g.:"
echo "     /implement <TICKET-ID>|<TASK-ID> [<repo-name>]"
