#!/usr/bin/env bash
# env-check.sh — inventario de env vars usadas en código vs documentadas
# Output: markdown a stdout

set -e
ROOT="${1:-$PWD}"
cd "$ROOT"

echo "# Inventario de variables de entorno"
echo ""

# ----- Vars usadas en código -----
TMPDIR=$(mktemp -d)
USED="$TMPDIR/used.txt"

# Node / TS / JS
grep -rEhno "process\.env\.([A-Z][A-Z0-9_]*)" \
  --include="*.ts" --include="*.js" --include="*.vue" --include="*.mjs" --include="*.cjs" \
  --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=.nuxt --exclude-dir=dist . 2>/dev/null \
  | sed 's/.*process\.env\.//' >> "$USED" || true

# import.meta.env
grep -rEhno "import\.meta\.env\.([A-Z][A-Z0-9_]*)" \
  --include="*.ts" --include="*.js" --include="*.vue" \
  --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=.nuxt --exclude-dir=dist . 2>/dev/null \
  | sed 's/.*import\.meta\.env\.//' >> "$USED" || true

# Python
grep -rEhno "(os\.environ\[?['\"]?|os\.getenv\(['\"]?|getenv\(['\"]?)([A-Z][A-Z0-9_]*)" \
  --include="*.py" --exclude-dir=.venv --exclude-dir=venv --exclude-dir=.git . 2>/dev/null \
  | grep -oE "[A-Z][A-Z0-9_]+" >> "$USED" || true

# .NET
grep -rEhno "Environment\.GetEnvironmentVariable\([\"']([A-Z][A-Z0-9_]*)" \
  --include="*.cs" --exclude-dir=bin --exclude-dir=obj . 2>/dev/null \
  | sed -E 's/.*GetEnvironmentVariable\(["'\'']//' | sed 's/[\"\'"'"'].*//' >> "$USED" || true

# Limpiar y dedupe
sort -u "$USED" | grep -E "^[A-Z][A-Z0-9_]+$" > "$TMPDIR/used-clean.txt"
USED_COUNT=$(wc -l < "$TMPDIR/used-clean.txt")

# ----- Vars documentadas -----
DOC="$TMPDIR/doc.txt"
> "$DOC"
for f in .env.example .env.template .env.sample env.example .env.example.local; do
  [ -f "$f" ] && grep -E "^[A-Z][A-Z0-9_]+=" "$f" 2>/dev/null | cut -d= -f1 >> "$DOC"
done
sort -u "$DOC" > "$TMPDIR/doc-clean.txt"
DOC_COUNT=$(wc -l < "$TMPDIR/doc-clean.txt")

# ----- Comparación -----
echo "## Resumen"
echo "- Vars usadas en código: **$USED_COUNT**"
echo "- Vars documentadas (.env.example etc.): **$DOC_COUNT**"
echo ""

echo "## Usadas en código y NO documentadas"
echo "_(añadir a .env.example)_"
echo ""
comm -23 "$TMPDIR/used-clean.txt" "$TMPDIR/doc-clean.txt" | sed 's/^/- /'
echo ""

echo "## Documentadas y NO usadas"
echo "_(limpiar de .env.example)_"
echo ""
comm -13 "$TMPDIR/used-clean.txt" "$TMPDIR/doc-clean.txt" | sed 's/^/- /'
echo ""

echo "## Todas las usadas (con archivos donde aparecen)"
echo ""
while read var; do
  echo "### \`$var\`"
  grep -rEln "process\.env\.$var\b|import\.meta\.env\.$var\b|os\.environ\[?['\"]?$var\b|os\.getenv\(['\"]?$var\b|getenv\(['\"]?$var\b|GetEnvironmentVariable\(['\"]?$var\b" \
    --include="*.ts" --include="*.js" --include="*.vue" --include="*.py" --include="*.cs" \
    --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=.nuxt --exclude-dir=dist . 2>/dev/null \
    | sed 's/^/- /'
  echo ""
done < "$TMPDIR/used-clean.txt"

rm -rf "$TMPDIR"
