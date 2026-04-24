# Catálogo: bugs conocidos

> Cada bug nuevo encontrado en una auditoría se añade aquí como **patrón abstracto**. La próxima auditoría empieza buscando estos patrones en orden.

---

## P-001 — Catch silencioso con default vacío

**Patrón**:
```ts
try { return await api.get(...) } catch { return [] }
```

**Por qué se escapa**: el código compila, no lanza, el frontend muestra "0 datos" como si fuera real. Sin Sentry/logging, invisible.

**Detectar**:
```bash
grep -rEn "catch\s*(\([^)]*\))?\s*\{[^}]*return\s*(\[\]|null|undefined|\{\})" --include="*.ts" --include="*.js" --include="*.vue"
```

**Fix**: en `catch`, loguear (logger.error con stack) **y** distinguir error técnico (devolver 503/throw) de "0 resultados legítimos" (que devuelva [] solo si la API confirmó vacío).

**Caso real**: PharmaSuite — endpoints `/api/ventas/*` devolvían `{datos:[]}` en catch genérico → pestaña vacía sin error visible cuando faltaba `BRIDGE_API_KEY`.

---

## P-002 — Fallback silencioso a endpoint deprecado

**Patrón**:
```ts
const apiKey = process.env.API_KEY
if (apiKey) return secureCall()
return legacyDebugCall()  // ¡este endpoint puede haberse cerrado!
```

**Por qué se escapa**: el cliente parece "robusto" (tiene fallback). Pero si el legacy se cierra y la env var falta, todo rompe sin error visible.

**Detectar**: buscar paths "debug", "legacy", "v1", "old" en clientes HTTP.

**Fix**: eliminar el fallback. Si la condición principal falla → `throw` con mensaje claro.

**Caso real**: PharmaSuite — `oracle.ts` con fallback a `/api/debug/query`. Cerrado en bridge → 410 → catch silencioso → ventas vacías.

---

## P-003 — Env var faltante en producción, default en dev

**Patrón**:
```ts
const url = process.env.SERVICE_URL || 'http://localhost:3000'
```

**Por qué se escapa**: en dev funciona (cae al default). En prod usa el valor de la env var… si está. Si no, silenciosamente apunta a localhost (no existe en prod) y falla con error confuso.

**Detectar**:
```bash
grep -rEn "process\.env\.[A-Z_]+\s*\|\|\s*['\"]http" --include="*.ts" --include="*.js"
```

**Fix**: validación al startup → si falta env var crítica, **fallar el arranque** (NO usar default que enmascara).

---

## P-004 — Migración SQLite no idempotente

**Patrón**:
```sql
ALTER TABLE x ADD COLUMN y INTEGER  -- falla en re-arranque
```

**Por qué se escapa**: pasa el primer deploy. En el segundo (rollback + re-deploy o crash + restart con datos viejos) revienta.

**Detectar**: revisar cada migración por `ADD COLUMN`/`CREATE INDEX` sin `IF NOT EXISTS`.

**Fix**: SQLite admite `ADD COLUMN IF NOT EXISTS` desde 3.35; para versiones viejas envolver en try/catch o usar PRAGMA para detectar.

---

## P-005 — Borrar columna sin actualizar call sites

**Patrón**: migración elimina columna `X`, pero queda código que la lee y devuelve `undefined`.

**Por qué se escapa**: TS no marca error si el tipo se actualizó. El código que asume `row.X !== undefined` falla en runtime.

**Detectar**:
```bash
# Antes de borrar columna 'foo':
grep -rn '\.foo\b\|\["foo"\]\|"foo":' --include="*.ts"
```

**Fix**: deprecate primero (mantener columna, marcar `@deprecated`), borrar en migración posterior tras eliminar todos los call sites.

---

## P-006 — `min-width` fijo en flex con N variable

**Patrón**:
```css
.bar { min-width: 30px; flex: 1; }
```

**Por qué se escapa**: con pocos items cabe. Con N=31 (días del mes) desborda y se corta. Visual-only, no error.

**Detectar**: revisar `min-width` fijo en componentes que renderizan listas variables.

**Fix**: `min-width: 0` + `flex: 1 1 0` o usar `overflow-x: auto`.

**Caso real**: PharmaSuite — `VentasEvolucion.vue` cortaba el día 24+ del mes.

---

## P-007 — Validación numérica `!0 === true`

**Patrón**:
```ts
if (!precio) return  // ¡pasa con precio=0!
```

**Por qué se escapa**: revisión casual no lo ve. Solo se reproduce cuando el valor real es 0 (no null/undefined).

**Detectar**:
```bash
grep -rEn "if\s*\(\s*!\s*[a-zA-Z_]+\s*\)" --include="*.ts" --include="*.js"
```

**Fix**: `if (precio == null)` o validación explícita por tipo.

---

## P-008 — Lock liberado por timeout en vez de try/finally

**Patrón**:
```ts
acquireLock()
setTimeout(releaseLock, 5000)
await doWork()
```

**Por qué se escapa**: la mayoría del tiempo el work termina antes del timeout. Si tarda más, el lock se libera y otra cosa pisa el work en curso.

**Fix**: try/finally siempre.

---

## P-009 — Buscar registro por campo NO único

**Patrón**: buscar trade por ticker en vez de por `order_id`. En orb-trader esto causó duplicados / órdenes mal asignadas.

**Detectar**: en código de mutación crítica, verificar que se busca por PK/UUID.

---

## P-010 — Endpoint con 200 + `{error: ...}` en body

**Patrón**: el bridge devuelve 200 con `{error: "..."}` para que "el cliente decida". El cliente no lo decide y trata como éxito.

**Por qué se escapa**: status 200 pasa cualquier check superficial.

**Fix**: status code correcto (4xx/5xx) + body con detalle. Si por compatibilidad se mantiene 200, **el cliente debe revisar siempre `body.error`** y se documenta en la checklist del cliente.

---

## P-011 — Secrets en repo

**Patrón**: API keys / connection strings commiteados, aunque "solo en .env.example".

**Detectar**: ver `phases/05-config.md` paso 5.

**Fix**: rotar el secret YA. `.env.example` solo con placeholders.

---

## P-012 — CORS `*` en endpoints autenticados

**Patrón**: `Access-Control-Allow-Origin: *` + cookies de auth → CSRF gratis.

**Detectar**: grep en config de CORS.

---

## Cómo añadir un patrón nuevo

Tras una auditoría, si encontraste un bug que NO está aquí:

1. Reformúlalo como **patrón abstracto** (no específico al proyecto).
2. Añade entrada con: descripción, por qué se escapa, cómo detectarlo (preferiblemente comando reproducible), fix recomendado, caso real (anonimizado si hace falta).
3. Si el patrón es de **interacción** entre módulos → va en `interaction-traps.md` en su lugar.

## P-013 — Drift config prod vs repo (install scripts, env var naming)
- **Severidad:** P2
- **Contexto:** Windows service install scripts que quedan desincronizados con el estado real del servicio tras una intervención manual. Idem env vars renombradas en hosting pero no en código/`.env.example`.
- **Detección:** Fase 5 (config) — grep del nombre en scripts de instalación + comparación con estado actual.
- **Fix:** re-sync del archivo al estado real. Nunca al revés (no tocar prod para "aplicar" el script).
- **Visto en:** PharmaSuite oracle-bridge (F04-001, abril 2026).
