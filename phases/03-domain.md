# FASE 3 — Auditoría por dominio

> **Output**: `audit/<timestamp>/03-domain.md`
> **Tiempo**: 30–90 min según áreas in scope
> **Depende de**: scope.md (áreas IN), 02-static.md

---

## Objetivo

Para cada área marcada IN scope en Fase 1, ejecutar su checklist específica y documentar findings.

---

## Cómo

Por cada área IN scope, leer la checklist correspondiente en `checklists/` y verificar **cada bullet**:

| Área | Checklist |
|------|-----------|
| Auth y sesiones | `checklists/auth.md` |
| DB / migraciones / queries | `checklists/db.md` |
| APIs / endpoints HTTP | `checklists/api.md` |
| Servicios externos / bridges | `checklists/external.md` |
| Frontend (componentes/estado) | `checklists/frontend.md` |
| CSS / visual / responsive | `checklists/visual.md` |

Cada bullet de la checklist se evalúa así:

- ✅ Cumple — anotar evidencia (archivo:línea o comando)
- ⚠️ Parcial — explicar qué falta
- ❌ No cumple — finding con severidad
- N/A — no aplica al stack

---

## Output `03-domain.md`

```markdown
# Fase 3 — Auditoría por dominio

## Auth (checklists/auth.md)
- [✅] Passwords hasheados con bcrypt/argon2 — `server/utils/auth.ts:42`
- [❌] Sin rate limit en login → F03-AUTH-01 (P1)
- [⚠️] Cookies HttpOnly pero sin SameSite=Strict → F03-AUTH-02 (P2)
- [N/A] OAuth flow — no se usa OAuth
...

## DB (checklists/db.md)
- [✅] Migraciones versionadas y idempotentes — `server/utils/database.ts`
- [❌] Sin índice en columna usada en WHERE frecuente → F03-DB-01 (P1)
...

## Findings detallados
<usar templates/finding.md>
```

---

## Reglas

1. **No saltarse bullets**. Si no aplica, marcar N/A explícitamente. Si no se puede verificar en esta sesión, marcar "BLOQUEADO" con motivo.
2. **Evidencia siempre**. Un ✅ sin archivo:línea no cuenta — pasa a ⚠️ o se reverifica.
3. **Severidad consistente**:
   - **P0**: bug que pierde dinero, datos, o expone usuarios. Fix antes de seguir.
   - **P1**: rompe funcionalidad o seguridad importante. Fix esta semana.
   - **P2**: degrada UX/perf/mantenibilidad. Fix este sprint.
   - **P3**: nice-to-have, deuda técnica baja prioridad.

---

## Antipatrones

- ❌ Auditar áreas que NO están en scope "porque ya que estoy".
- ❌ Marcar todo ✅ por familiaridad con el código sin volver a verificar.
- ❌ Dar findings sin archivo:línea ni comando para reproducir.
- ❌ Inventar checklist sobre la marcha — usar las de `checklists/`. Si falta una, **crearla en `checklists/` antes** de auditar (memoria institucional).
