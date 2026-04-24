# FASE 8 — Informe

> **Output**: `audit/<timestamp>/REPORT.md`
> **Tiempo**: 15–30 min
> **Depende de**: outputs de fases 1–7

---

## Objetivo

Consolidar todos los findings en un único informe **accionable** para el usuario (o para Code si va a implementar fixes).

---

## Estructura del REPORT.md

```markdown
# Auditoría — <PROYECTO> — <FECHA>

## Resumen ejecutivo
- Áreas auditadas: <lista>
- Findings: P0:N P1:N P2:N P3:N
- 3 cosas más urgentes:
  1. <finding-id> — <título 1 línea>
  2. ...
  3. ...
- Riesgo global: 🟢 / 🟡 / 🔴 con justificación

## Scope acordado
<copiar de scope.md>

## Findings por prioridad

### 🔴 P0 — fix antes de seguir
<por cada finding: id, título, archivo:línea, descripción 1 párrafo, repro, fix, esfuerzo>

### 🟠 P1 — fix esta semana
...

### 🟡 P2 — fix este sprint
...

### ⚪ P3 — deuda técnica
...

## Findings por área
- **Auth**: <conteo + ids>
- **DB**: ...
- **APIs**: ...
- **Frontend**: ...
- **Visual**: ...
- **Config**: ...
- **Cruce**: ...

## Lo que NO se auditó (y por qué)
<de scope.md sección OUT, + cualquier área bloqueada>

## Riesgos no cuantificados
<cosas que el auditor SOSPECHA pero no pudo verificar>

## Patrones nuevos detectados
<bugs que NO estaban en patterns/known-bugs.md y deberían añadirse>

## Próximos pasos sugeridos
1. ...
2. ...

## Anexos
- scope.md
- 02-static.md, 03-domain.md, ..., 07-visual.md
- logs/, screenshots/
```

---

## Reglas

1. **Toda finding tiene `templates/finding.md`** — sin excepciones. Sin repro = no es finding.
2. **Resumen ejecutivo cabe en una pantalla**. Si no, está mal escrito.
3. **Severidades consistentes** entre fases. Si la misma cosa es P1 en Fase 3 y P2 en Fase 7 → unificar.
4. **No mezclar opinión arquitectónica con findings**. Refactors propuestos van en una sección "Recomendaciones" separada, no como findings.
5. **Riesgo global** justificado:
   - 🟢: ningún P0, ≤2 P1, ningún área crítica fallando.
   - 🟡: 1 P0 acotado o varios P1.
   - 🔴: múltiples P0, o P1 en áreas críticas (auth, datos, dinero).

---

## Actualizar memoria institucional

Tras el informe:

```bash
# Patrones nuevos detectados → añadir a patterns/known-bugs.md o interaction-traps.md
$EDITOR /Users/rafita/.claude/skills/fullstack-audit/patterns/known-bugs.md
```

Cada bug nuevo encontrado se documenta como patrón **abstracto** (no específico del proyecto) con:
- Descripción del patrón
- Cómo detectarlo (grep o análisis)
- Por qué se escapa a auditorías clásicas
- Fix recomendado
- Caso real (con cita anonimizada si hace falta)

Esto hace que la próxima auditoría **empiece por buscar este patrón**.

---

## Antipatrones

- ❌ Informe sin priorización (todo P1 = nada P1).
- ❌ Findings sin repro ("creo que falla X").
- ❌ Ocultar las áreas que no se auditaron — listarlas explícitamente.
- ❌ No actualizar `patterns/` — pierdes la memoria de lo aprendido.
