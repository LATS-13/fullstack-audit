# FASE 2 — Análisis estático

> **Output**: `audit/<timestamp>/02-static.md`
> **Tiempo**: 15–40 min según tamaño del repo
> **Depende de**: scope.md de Fase 1

---

## Objetivo

Encontrar bugs sin ejecutar la app. Cubre:
- Errores de lint/types
- Patrones tóxicos conocidos (catch silencioso, any sin justificar, console.log, secretos hardcoded, etc.)
- Patrones del catálogo `patterns/known-bugs.md`
- Dependencias outdated o con CVEs
- Code smells (archivos enormes, funciones de >100 líneas, duplicación obvia)

---

## Pasos

### 1. Lint y typecheck

Detectar comandos:

```bash
# Node
test -f package.json && jq -r '.scripts | to_entries[] | "\(.key): \(.value)"' package.json
# Python
test -f pyproject.toml && grep -A20 '\[tool\.' pyproject.toml
test -f .flake8 -o -f setup.cfg && echo "flake8 detectado"
# Go, Rust, etc. — ver scripts/detect-stack.sh
```

Ejecutar todos los que existan:

```bash
npm run lint 2>&1 | tee audit/$STAMP/lint.log
npm run typecheck 2>&1 | tee audit/$STAMP/typecheck.log    # o tsc --noEmit
ruff check . 2>&1 | tee audit/$STAMP/ruff.log
mypy . 2>&1 | tee audit/$STAMP/mypy.log
```

Si NO hay lint/typecheck configurado → finding P2: "proyecto sin lint/typecheck CI".

### 2. Patrones tóxicos genéricos (grep masivo)

Cada match es un candidato a finding (no automático — requiere revisión humana del contexto):

```bash
# Catch silencioso (devuelve default sin loguear)
grep -rn "catch.*{[^}]*return\s*\(\[\]\|null\|undefined\|''\|{}\)" --include="*.ts" --include="*.js" --include="*.vue"

# any sin justificar
grep -rn ":\s*any\b" --include="*.ts" --include="*.vue" | grep -v "// any: "

# console.log/print abandonados
grep -rn "console\.\(log\|debug\|info\)" --include="*.ts" --include="*.js" --include="*.vue"
grep -rn "print(" --include="*.py"

# Secretos hardcoded (rough)
grep -rEn "(api[_-]?key|secret|token|password)\s*[:=]\s*['\"][A-Za-z0-9_\-]{20,}" \
  --include="*.ts" --include="*.js" --include="*.py" --include="*.json" \
  --exclude-dir=node_modules --exclude-dir=.git

# TODO/FIXME/HACK/XXX
grep -rEn "(TODO|FIXME|HACK|XXX)\b" --include="*.ts" --include="*.js" --include="*.vue" --include="*.py"

# SQL injection candidato (concatenación con variable)
grep -rEn "(query|exec|execute)\(\s*['\"][^'\"]*['\"]\s*\+" --include="*.ts" --include="*.js" --include="*.py"

# eval / Function() / dangerouslySetInnerHTML
grep -rEn "\b(eval|new Function|dangerouslySetInnerHTML)\b" --include="*.ts" --include="*.js" --include="*.vue"

# fetch sin timeout/abort
grep -rn "fetch(" --include="*.ts" --include="*.js" | grep -v "AbortSignal\|timeout"

# Promise sin await ni .catch
# (más complejo — opcional, requiere AST)
```

Output: `audit/$STAMP/static-patterns.md` con cada categoría y resultados.

### 3. Patrones del catálogo `patterns/known-bugs.md`

Para cada patrón documentado que aplique al stack detectado, ejecutar su query y reportar matches.

Ejemplo (de `patterns/known-bugs.md` → "Fallback silencioso a endpoint deprecado"):

```bash
# Buscar fallbacks legacy en clientes HTTP
grep -rn "debug\|legacy\|fallback" --include="*.ts" server/ | grep -i "endpoint\|url\|path"
```

### 4. Dependencias

```bash
# npm
npm outdated --json > audit/$STAMP/npm-outdated.json
npm audit --json > audit/$STAMP/npm-audit.json 2>&1

# pip
pip list --outdated --format=json > audit/$STAMP/pip-outdated.json
pip-audit -f json > audit/$STAMP/pip-audit.json 2>&1
```

CVEs críticos o high → finding P0/P1.

### 5. Code smells estructurales

```bash
# Archivos > 500 líneas (revisar si son god files)
find . -name "*.ts" -o -name "*.vue" -o -name "*.py" \
  | xargs wc -l 2>/dev/null | sort -rn | awk '$1 > 500' | head -30 \
  > audit/$STAMP/large-files.txt

# Funciones > 100 líneas (proxy: bloques entre llaves grandes)
# Opcional, requiere AST. Como mínimo detectar archivos sospechosos.
```

### 6. Tipos faltantes en boundaries críticos

Para TypeScript:

```bash
# Endpoints API sin tipo de retorno explícito
grep -rEn "defineEventHandler\(.*=>\s*\{" --include="*.ts" server/api/ | grep -v ":\s*Promise<"
```

---

## Output `02-static.md`

```markdown
# Fase 2 — Análisis estático

## Resumen
- Lint: <X errores, Y warnings>
- Typecheck: <X errores>
- Dependencias outdated: <N>, CVEs: <P0:N P1:N>
- Patrones tóxicos: <N candidatos>
- Code smells: <N archivos >500 LOC>

## Findings (con id F02-NN)
<usar templates/finding.md por cada uno>

## Logs adjuntos
- lint.log, typecheck.log, ruff.log, mypy.log
- static-patterns.md
- npm-outdated.json, npm-audit.json
- large-files.txt
```

Cada finding apunta a archivo:línea, severidad, fix sugerido.

---

## Antipatrones

- ❌ Reportar cada match de grep como finding sin revisar contexto.
- ❌ Saltar `patterns/known-bugs.md` "porque ya conozco la app".
- ❌ Pasar a Fase 3 si lint/typecheck no compila — arreglarlo primero.
