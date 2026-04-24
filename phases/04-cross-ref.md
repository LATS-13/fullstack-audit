# FASE 4 — Cruce de cambios recientes vs código legacy

> **Output**: `audit/<timestamp>/04-cross-ref.md`
> **Tiempo**: 20–60 min
> **Depende de**: scope.md (ventana de commits), git history

---

## Por qué esta fase existe

**Bugs de interacción** son la categoría que MÁS se escapa a las auditorías clásicas. Cada cambio reciente, leído en aislado, parece correcto. Pero combinado con código legacy, rompe contratos invisibles.

Caso real (PharmaSuite, abril 2026):
- Sprint 0 cierra `/api/debug/query` en el bridge .NET → devuelve HTTP 410.
- Cliente Nuxt en `oracle.ts` tiene fallback a ese mismo endpoint.
- Cuando falta `BRIDGE_API_KEY` en producción, el cliente cae al fallback → 410 → catch silencioso → pestaña vacía sin error visible.
- Cada pieza por separado pasa cualquier auditoría. La interacción no.

Esta fase **busca exactamente eso**.

---

## Pasos

### 1. Lista de archivos tocados en la ventana

```bash
WINDOW="${WINDOW:-14 days ago}"
git log --since="$WINDOW" --name-only --pretty=format: \
  | sort -u | grep -v '^$' \
  > audit/$STAMP/changed-files.txt
```

### 2. Para cada archivo cambiado: encontrar consumidores

```bash
while read f; do
  basename=$(basename "$f")
  # buscar imports/requires/grep simples del archivo
  matches=$(grep -rEn "['\"\.]${basename%.*}\b" --include="*.ts" --include="*.js" --include="*.vue" --include="*.py" \
            --exclude-dir=node_modules --exclude-dir=.git . | grep -v "^${f}:")
  if [ -n "$matches" ]; then
    echo "## $f"
    echo "$matches"
    echo ""
  fi
done < audit/$STAMP/changed-files.txt > audit/$STAMP/consumers.md
```

Para cada consumidor, **revisar manualmente** si el cambio rompe algún contrato.

### 3. Cambios en APIs / endpoints

```bash
# Endpoints añadidos/modificados/borrados
git log --since="$WINDOW" -p --all -- 'server/api/**' '**/routes.ts' '**/Program.cs' '**/urls.py' \
  | grep -E '^(\+\+\+|\-\-\-|\+app\.|@@|\-app\.|\+router\.|\-router\.)' \
  > audit/$STAMP/api-diff.txt
```

Para cada endpoint **eliminado o con status code cambiado**:
- Buscar TODOS los clientes (Nuxt server/, frontend fetch(), tests E2E, scripts externos)
- Verificar que ninguno asume el contrato viejo
- Verificar que el cambio se documentó (changelog, migration guide, o aviso al usuario)

### 4. Cambios en schemas DB

```bash
# Migraciones añadidas en la ventana
git log --since="$WINDOW" --name-only --pretty=format: -- 'migrations/**' '**/database.ts' '**/schema.sql' \
  | sort -u | grep -v '^$'
```

Para cada migración:
- ¿Algún código lee la columna/tabla **antes** de aplicarla? (race en orden de deploy)
- ¿Alguna query usa el schema antiguo?
- ¿Hay `default` o backfill para datos existentes?

### 5. Cambios en config / contratos compartidos

```bash
git log --since="$WINDOW" --name-only --pretty=format: \
  -- '.env.example' '**/types.ts' '**/constants.ts' '**/config.ts' \
  | sort -u | grep -v '^$'
```

Cualquier cambio en types compartidos → buscar consumers desactualizados.

### 6. Cruce contra `patterns/interaction-traps.md`

Recorrer `patterns/interaction-traps.md` (catálogo de patrones de bug de interacción ya vistos) y verificar uno por uno si aplica al diff actual.

---

## Output `04-cross-ref.md`

```markdown
# Fase 4 — Cruce de cambios

## Ventana
desde <DATE> hasta HEAD — N commits, M archivos tocados

## Diff por área
- APIs modificadas: <lista>
- Endpoints eliminados: <lista>
- Migraciones nuevas: <lista>
- Types compartidos: <lista>

## Consumidores potencialmente rotos
<por cada cambio crítico, lista de consumers + análisis>

## Findings (F04-NN)
<usar templates/finding.md>

## Patrones de interacción matcheados
<de patterns/interaction-traps.md>
```

---

## Antipatrones

- ❌ Mirar solo los archivos cambiados sin sus consumidores.
- ❌ Asumir que un endpoint borrado "ya nadie lo usaba" sin grep.
- ❌ Cambios en types declarados como "no rompen runtime" — TS compila pero la lógica puede romperse.
- ❌ Saltar migraciones DB porque "ya están aplicadas en local".
