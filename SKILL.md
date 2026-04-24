---
name: fullstack-audit
description: Auditoría completa de aplicaciones fullstack (web/desktop) en 8 fases — scope, estático, dominio, cruce de cambios, config, runtime, visual, informe. Úsalo cuando el usuario pida auditar una app, buscar bugs, revisar código tras cambios, validar antes de un deploy, o investigar un fallo recurrente. Cubre análisis estático + dinámico + visual + config de producción + cruce de cambios recientes con código legacy. Genérico — autodetecta el stack.
---

# Fullstack Audit

Protocolo de auditoría que NO se queda en lectura de código. Combina:

1. **Estático**: lint, types, grep de patrones tóxicos.
2. **Dominio**: checklists específicas por área (auth, DB, API, frontend, etc.).
3. **Cruce**: detecta bugs de interacción entre cambios recientes y código legacy.
4. **Config**: comparación `.env.example` ↔ código ↔ producción.
5. **Runtime**: levanta servicios, smoke endpoints, captura errores silenciosos.
6. **Visual**: Playwright + screenshots por breakpoint.
7. **Informe**: findings P0–P3 con repro y fix.

> **Regla nº1**: una auditoría sin scope explícito acaba siendo una auditoría incompleta. Empezar SIEMPRE por la Fase 1.

---

## Cuándo usar

- "Audita la app", "revisa el código", "encuentra bugs", "valida antes de deploy"
- "¿Qué se rompió?", "investiga por qué falla X"
- "Revisa este PR / sprint / release"
- Tras una refactorización grande o un sprint de fixes

## Cuándo NO usar

- Para resolver UN bug específico ya identificado → ir directo al fix
- Para diseñar arquitectura → no es lo que hace este skill
- Para code review de un commit pequeño → demasiada artillería

---

## Workflow

Ejecutar las fases EN ORDEN. Cada fase tiene su propio archivo en `phases/`:

| # | Fase | Archivo | Outputs |
|---|------|---------|---------|
| 1 | Scope | `phases/01-scope.md` | `audit/scope.md` |
| 2 | Estático | `phases/02-static.md` | `audit/02-static.md` |
| 3 | Dominio | `phases/03-domain.md` | `audit/03-domain.md` |
| 4 | Cruce de cambios | `phases/04-cross-ref.md` | `audit/04-cross-ref.md` |
| 5 | Configuración | `phases/05-config.md` | `audit/05-config.md` |
| 6 | Runtime / smoke | `phases/06-runtime.md` | `audit/06-runtime.md` |
| 7 | Visual (Playwright) | `phases/07-visual.md` | `audit/07-visual/*.png` + `.md` |
| 8 | Informe | `phases/08-report.md` | `audit/REPORT.md` |

Todas las fases escriben a `audit/<YYYY-MM-DD-HHMM>/` en la raíz del proyecto auditado.

---

## Cómo invocar

```
Audita PharmaSuite con el skill fullstack-audit.
Scope: pestañas Ventas, Incentivos, Portal. Últimos 7 días de commits.
```

Pasos que sigue Claude (Code o Cowork):

1. Lee `SKILL.md` (este archivo).
2. Lee `phases/01-scope.md` y crea `audit/scope.md` consensuado con el usuario.
3. Para cada fase 2–7: lee el `.md` correspondiente, ejecuta sus pasos, escribe su output.
4. Lee `phases/08-report.md` y produce `audit/REPORT.md`.
5. Actualiza `patterns/known-bugs.md` si aparecen patrones nuevos.

> **Cada fase puede ejecutarse aislada** si el usuario solo pide esa fase.

---

## Recursos

- `checklists/` — listas verificables por dominio (auth, db, api, frontend, visual, externos).
- `patterns/known-bugs.md` — catálogo de bugs ya vistos. Empezar cada fase 2 buscando estos.
- `patterns/interaction-traps.md` — patrones de bugs de interacción (clave para Fase 4).
- `scripts/` — utilidades ejecutables: detección de stack, env-check, smoke, visual.
- `templates/finding.md` — formato estándar de cada finding.

---

## Principios

1. **Scope explícito antes que cobertura completa**. Mejor 3 áreas bien que 10 mal.
2. **Reproducción obligatoria**. Finding sin pasos para reproducir = ruido.
3. **Output sobre prosa**. `archivo:línea`, comando para reproducir, fix sugerido. No ensayos.
4. **Memoria institucional**. Cada bug nuevo → `patterns/known-bugs.md`. La próxima auditoría empieza por esos.
5. **Cero confianza en config de producción**. Lo que NO está en el repo (env vars, secrets, valores en servidores externos) es la causa más común de bugs invisibles. Fase 5 es obligatoria.
6. **Estático no basta**. Levantar la app y al menos un screenshot por pestaña pilla bugs que ningún grep pilla.

---

## Stacks soportados (autodetect vía `scripts/detect-stack.sh`)

- **Web**: Nuxt, Next, Vite/Vue, React, Svelte, Astro, Remix
- **Backend**: Express, Fastify, NestJS, FastAPI, Flask, Django, Rails, Spring, .NET, Go (echo/gin)
- **Servicios**: WindowsService, systemd, LaunchAgent, Docker, PM2
- **DB**: SQLite, Postgres, MySQL, Oracle, Mongo, Supabase, Firebase
- **Auth**: Better Auth, NextAuth, Lucia, Passport, Supabase Auth, JWT artesanal, sesiones
- **Hosting**: Railway, Vercel, Netlify, Cloudflare, Render, Fly, AWS, GCP
- **Test E2E**: Playwright, Cypress

Las fases adaptan sus checks al stack detectado. Si un check no aplica → skip explícito.
