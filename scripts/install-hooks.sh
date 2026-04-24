#!/usr/bin/env bash
# install-hooks.sh — instala el pre-push hook en un repo git.
# Uso: cd <proyecto> && bash ~/.claude/skills/fullstack-audit/scripts/install-hooks.sh

set -e
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOK_SRC="$SKILL_DIR/scripts/pre-push-hook.sh"

if [ ! -d ".git" ]; then
  echo "✘ No es un repo git (no hay .git/)"
  exit 1
fi

mkdir -p .git/hooks
TARGET=".git/hooks/pre-push"

if [ -e "$TARGET" ] && [ ! -L "$TARGET" ]; then
  echo "⚠ Ya existe .git/hooks/pre-push (no es symlink). Backup → .git/hooks/pre-push.bak"
  mv "$TARGET" "$TARGET.bak"
fi

ln -sfn "$HOOK_SRC" "$TARGET"
chmod +x "$HOOK_SRC"

echo "✓ pre-push hook instalado: $TARGET → $HOOK_SRC"
echo "  Test: git push --dry-run"
echo "  Bypass: git push --no-verify"
