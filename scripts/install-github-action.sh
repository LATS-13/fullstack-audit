#!/usr/bin/env bash
# install-github-action.sh — copia el workflow al proyecto.
# Uso: cd <proyecto> && bash ~/.claude/skills/fullstack-audit/scripts/install-github-action.sh

set -e
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$SKILL_DIR/templates/github-action.yml"

if [ ! -d ".git" ]; then
  echo "✘ No es un repo git"
  exit 1
fi

mkdir -p .github/workflows
TARGET=".github/workflows/fullstack-audit.yml"

if [ -e "$TARGET" ]; then
  echo "⚠ Ya existe $TARGET — backup → $TARGET.bak"
  cp "$TARGET" "$TARGET.bak"
fi

cp "$SRC" "$TARGET"
echo "✓ workflow instalado: $TARGET"
echo "  Commit y push. La action correrá en el próximo PR."
echo "  Edita la URL del skill en el step 'Clone fullstack-audit skill' si lo tienes en repo propio."
