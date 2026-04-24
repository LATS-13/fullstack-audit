# Template: Finding

> Cada finding del informe usa esta estructura. Sin estos campos, no es un finding válido (es ruido).

---

```markdown
### F<FASE>-<AREA>-<NN> — <título corto>

**Severidad**: P0 | P1 | P2 | P3
**Área**: auth | db | api | external | frontend | visual | config | cross-ref
**Archivo(s)**: `path/al/archivo.ts:LINEA`
**Detectado en**: Fase X

**Descripción**:
1–3 frases describiendo el problema. Qué hace el código mal y qué debería hacer.

**Impacto**:
1 frase: qué se rompe / qué riesgo introduce. Si es P0/P1, cuantificar (usuarios afectados, dinero, datos).

**Repro**:
```bash
# Pasos exactos para reproducir
curl -fsS http://localhost:3000/api/X
# Esperado: ...
# Actual: ...
```

**Fix sugerido**:
```diff
- código viejo
+ código nuevo
```
O texto si el fix es de config/proceso.

**Esfuerzo**: trivial (<30min) | bajo (1–4h) | medio (1–2 días) | alto (>2 días)

**Patrón**: P-NNN o I-NNN si matchea un patrón del catálogo. Si es nuevo → marcar para añadir a `patterns/`.
```

---

## Reglas

- **Severidad consistente** entre fases. Si el mismo bug aparece en Fase 3 y Fase 6, una sola entrada.
- **Repro concreto**. "Hacer click en X" no vale — comando, URL, estado de la BD.
- **Fix sugerido obligatorio** salvo en P3 ("nice to have, sin propuesta").
- **Esfuerzo realista**. Si no se sabe, marcar "?" — no maquillar.
- **Patrón si aplica**. Si el bug es nuevo, anotar al final del informe la propuesta de patrón nuevo para `known-bugs.md` o `interaction-traps.md`.

---

## Ejemplo

```markdown
### F03-API-04 — Endpoint /api/ventas/historico devuelve {datos:[]} en vez de 503 cuando el bridge falla

**Severidad**: P1
**Área**: api
**Archivo(s)**: `server/api/ventas/historico.get.ts:209-212`
**Detectado en**: Fase 3, confirmado en Fase 6

**Descripción**:
El catch genérico devuelve `{datos:[], resumen:{...}}` cuando `oracle.query()` lanza. La pestaña Ventas se queda vacía sin error visible al usuario, dificultando el diagnóstico.

**Impacto**:
Cualquier fallo del bridge Oracle (red, env var, query inválida) es invisible a usuarios y a Sentry. Tiempo medio de detección: días (alguien se da cuenta de que la pestaña no tiene datos).

**Repro**:
```bash
unset BRIDGE_API_KEY
npm run dev
curl -s http://localhost:3000/api/ventas/historico?periodo=mes | jq
# Esperado: 503 con {error: "..."}
# Actual: 200 con {datos: [], resumen: {totalActual:0, ...}}
```

**Fix sugerido**:
```diff
} catch (err) {
-  return { datos: [], resumen: { totalActual: 0, ... } }
+  logger.error({ err, periodo }, 'historico failed')
+  throw createError({ statusCode: 503, statusMessage: 'oracle unavailable' })
}
```

**Esfuerzo**: bajo (1–2h, replicar en los 5 endpoints similares).

**Patrón**: P-001 (catch silencioso con default vacío).
```
