#!/usr/bin/env bash
# pre-push-hook.sh — git hook que bloquea push si hay problemas P0 críticos.
#
# Corre rápido (<5s). Solo chequeos estáticos baratos:
#   1. Env vars usadas en código que NO están en .env.example
#   2. console.log/debugger olvidados en archivos staged recientes
#   3. Patrones tóxicos conocidos (ver patterns/known-bugs.md)
#
# Para checks más pesados → lanzar skill completo: fullstack-audit.
#
# Bypass manual: git push --no-verify

set -e
RED='\033[0;31m'
YEL='\033[1;33m'
GRN='\033[0;32m'
NC='\033[0m'

SKILL_DIR="${SKILL_DIR:-$HOME/.claude/skills/fullstack-audit}"
FAIL=0

echo "→ fullstack-audit pre-push checks..."

# 1. Env vars huérfanas (críticas)
if [ -f ".env.example" ]; then
  USED=$(grep -rhoE 'process\.env\.[A-Z_][A-Z0-9_]+|import\.meta\.env\.[A-Z_][A-Z0-9_]+|useRuntimeConfig\(\)\.[a-zA-Z_][a-zA-Z0-9_]+' \
    --include='*.ts' --include='*.js' --include='*.vue' --include='*.mjs' \
    server/ composables/ utils/ lib/ pages/ components/ 2>/dev/null \
    | sed -E 's/.*\.([A-Za-z_][A-Za-z0-9_]+)$/\1/' \
    | sort -u || true)

  DECLARED=$(grep -oE '^[A-Z_][A-Z0-9_]+' .env.example 2>/dev/null | sort -u || true)

  MISSING=""
  for var in $USED; do
    # Skip common Nuxt runtime config conventions (lowercase)
    [[ "$var" =~ ^[a-z] ]] && continue
    if ! echo "$DECLARED" | grep -qx "$var"; then
      MISSING="$MISSING $var"
    fi
  done

  if [ -n "$MISSING" ]; then
    echo -e "${RED}✘ Env vars usadas en código SIN estar en .env.example:${NC}"
    for v in $MISSING; do echo "   - $v"; done
    FAIL=1
  fi
fi

# 2. console.log / debugger en archivos que van en este push
COMMITS_RANGE=""
while read local_ref local_sha remote_ref remote_sha; do
  if [ "$remote_sha" = "0000000000000000000000000000000000000000" ]; then
    COMMITS_RANGE="$local_sha"
  else
    COMMITS_RANGE="$remote_sha..$local_sha"
  fi
done

if [ -n "$COMMITS_RANGE" ]; then
  CHANGED=$(git diff --name-only "$COMMITS_RANGE" 2>/dev/null | grep -E '\.(ts|js|vue|mjs)$' || true)
  if [ -n "$CHANGED" ]; then
    LOGS=$(echo "$CHANGED" | xargs grep -lE '^\s*(console\.log|debugger)' 2>/dev/null || true)
    if [ -n "$LOGS" ]; then
      echo -e "${YEL}⚠ console.log / debugger en archivos de este push:${NC}"
      echo "$LOGS" | sed 's/^/   - /'
      # warn only, no fail
    fi
  fi
fi

# 3. Patrones tóxicos del catálogo (si existe)
if [ -f "$SKILL_DIR/patterns/known-bugs.md" ] && [ -n "$CHANGED" ]; then
  # Busca patrones marcados como P0 en known-bugs.md (convención: `grep:\`patrón\``)
  PATTERNS=$(grep -E '^\s*grep:\s*`' "$SKILL_DIR/patterns/known-bugs.md" 2>/dev/null \
    | sed -E 's/.*grep:\s*`([^`]+)`.*/\1/' || true)
  for p in $PATTERNS; do
    HITS=$(echo "$CHANGED" | xargs grep -lE "$p" 2>/dev/null || true)
    if [ -n "$HITS" ]; then
      echo -e "${YEL}⚠ patrón tóxico detectado:${NC} $p"
      echo "$HITS" | sed 's/^/   - /'
    fi
  done
fi

if [ $FAIL -eq 1 ]; then
  echo ""
  echo -e "${RED}Push bloqueado por checks críticos. Arréglalo o usa:${NC}"
  echo "   git push --no-verify"
  exit 1
fi

echo -e "${GRN}✓ pre-push OK${NC}"
exit 0
