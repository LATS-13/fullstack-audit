#!/usr/bin/env bash
# run-audit.sh — orquesta una auditoría completa
# Uso: cd <proyecto> && bash <ruta-skill>/scripts/run-audit.sh [scope-rapida|media|profunda]

set -e
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEPTH="${1:-media}"
STAMP=$(date +%Y-%m-%d-%H%M)
AUDIT_DIR="audit/$STAMP"

mkdir -p "$AUDIT_DIR"
echo "STAMP=$STAMP" > "$AUDIT_DIR/.env"
echo "DEPTH=$DEPTH" >> "$AUDIT_DIR/.env"
echo "SKILL_DIR=$SKILL_DIR" >> "$AUDIT_DIR/.env"

echo "[run-audit] STAMP=$STAMP DEPTH=$DEPTH"
echo "[run-audit] Lee la SKILL.md y las phases/ secuencialmente."
echo "[run-audit] Output en: $AUDIT_DIR"
echo ""
echo "Este script NO ejecuta las fases automáticamente — está pensado"
echo "para que Claude (Code o Cowork) las pilote leyendo cada phase/*.md"
echo "y delegue ejecución de scripts/ cuando aplique."
echo ""
echo "Pasos sugeridos para Claude:"
echo "  1. cat $SKILL_DIR/SKILL.md"
echo "  2. cat $SKILL_DIR/phases/01-scope.md  → consensuar scope con usuario"
echo "  3. bash $SKILL_DIR/scripts/detect-stack.sh > $AUDIT_DIR/stack.md"
echo "  4. cat $SKILL_DIR/phases/02-static.md → ejecutar checks → $AUDIT_DIR/02-static.md"
echo "  5. ... (fases 3-7)"
echo "  6. cat $SKILL_DIR/phases/08-report.md → consolidar → $AUDIT_DIR/REPORT.md"
echo ""
echo "Si quieres ejecutar fases automáticas (estática + config), corre:"
echo "  bash $SKILL_DIR/scripts/detect-stack.sh > $AUDIT_DIR/stack.md"
echo "  bash $SKILL_DIR/scripts/env-check.sh > $AUDIT_DIR/env-inventory.md"
