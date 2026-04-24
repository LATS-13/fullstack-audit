# Catálogo: trampas de interacción

> Bugs que aparecen SOLO al combinar dos cambios o módulos que en aislado funcionan bien. Esta es la categoría que más se escapa a auditorías clásicas.

---

## I-001 — Cliente con fallback a endpoint que el servicio cerró

**Disparador**: el servicio backend deprecó/cerró un endpoint. El cliente (otro repo o módulo) tenía un fallback a ese endpoint. La condición principal del cliente falla → cae al fallback → 404/410 → silenciosamente vacío.

**Cómo detectar en Fase 4**:
1. Listar endpoints eliminados o con cambio de status code en la ventana.
2. Buscar todos los clientes (grep paths). Incluir clientes en otros repos/proyectos.
3. Verificar que ningún cliente lo invoca.

**Caso real**: PharmaSuite — `oracle-bridge` cerró `/api/debug/query` (sprint 0). Cliente Nuxt en `oracle.ts` tenía fallback a ese endpoint. Resultado: pestaña Ventas vacía cuando faltaba `BRIDGE_API_KEY`.

---

## I-002 — Migración DB cambia tipo, código viejo asume el anterior

**Disparador**: migración cambia INT → STRING (o nullable → not null). Código viejo asume el tipo antiguo y falla.

**Cómo detectar**:
1. Diff de migraciones en la ventana.
2. Para cada columna modificada, grep todos los lecturas/escrituras.

---

## I-003 — Refactor de endpoint rompe el frontend (sin TS error)

**Disparador**: backend cambia el shape del response (renombra campo, cambia anidación). TS server compila. Frontend espera el shape viejo, recibe `undefined` en runtime.

**Cómo detectar**:
1. Diff de tipos compartidos / OpenAPI.
2. Si no hay tipos compartidos → es **un finding por sí mismo** (falta de contrato tipado).

---

## I-004 — Auth cambiada en un middleware, otro middleware lo asume distinto

**Disparador**: se cambia formato de cookie/token en `middleware/auth.ts`. Otro middleware (`portal-auth.ts`) sigue asumiendo el formato anterior. Bypass o lock-out según el caso.

**Cómo detectar**: en sistemas multi-auth, cualquier cambio en uno verifica que NO afecta al otro.

---

## I-005 — Default vacío + retry agresivo = avalancha

**Disparador**: endpoint A devuelve `[]` por error silencioso. Frontend interpreta "vacío" como "necesito recargar" y dispara retry cada N segundos. El servicio caído recibe avalancha.

**Cómo detectar**: Fase 6 (degradación) — apagar servicio externo y observar comportamiento del frontend en network tab.

---

## I-006 — Feature flag ON en staging, OFF en prod (o al revés)

**Disparador**: feature funciona en staging porque flag está ON. En prod está OFF y el código asume que el feature está activo (sin chequeo defensivo) → null pointer.

**Cómo detectar**: Fase 5 — listar feature flags en cada entorno y comparar.

---

## I-007 — Servicio externo rota credencial, no se actualiza en el cliente

**Disparador**: el equipo del servicio externo rota su API key compartida. Solo se actualiza en algunos clientes. Otros siguen con la vieja → 401.

**Cómo detectar**: Fase 5 — para cada secret de servicio externo, verificar que está rotado consistentemente y documentado el ciclo.

---

## I-008 — Cron desincronizado de migración

**Disparador**: migración renombra tabla de `users` a `accounts`. Cron job nocturno (que no se redeployó al mismo tiempo) sigue leyendo `users` → falla silencioso (logs de cron poco vigilados).

**Cómo detectar**: Fase 5 — listar todos los cron jobs / scheduled tasks y verificar versión del código que ejecutan.

---

## I-009 — Cambio de timezone en backend afecta cálculos en frontend

**Disparador**: backend pasa de devolver fechas en UTC a local. Frontend asume UTC y restaura/parsea mal → reportes con día anterior/posterior.

**Cómo detectar**: Fase 4 — buscar cambios en serialización de fechas; Fase 6 — verificar fechas críticas en respuestas.

---

## I-010 — Cliente ignora versionado del servidor

**Disparador**: backend implementa versionado por header (`API-Version: 2024-04-01`). Cliente no envía el header → backend sirve "default" que es la versión vieja. Cliente recibe shape antiguo, código nuevo del cliente lo interpreta mal.

**Cómo detectar**: Fase 4 — buscar usos del header de versión.

---

## I-011 — Caché desactualizada tras migración de schema

**Disparador**: app cachea respuesta JSON. Schema cambia. Cache TTL no expirada → servimos datos con shape viejo.

**Cómo detectar**: Fase 6 — limpiar caché tras cualquier cambio de shape detectado en Fase 4.

---

## I-012 — Hot reload tapa bug que solo aparece en cold start

**Disparador**: dev server con hot reload mantiene estado entre cambios. Bug que solo aparece al inicializar from scratch (orden de migraciones, plugins, conexiones) se enmascara.

**Cómo detectar**: Fase 6 — al menos UN smoke debe ser tras `kill && start` limpio.

---

## I-013 — Permisos del proceso cambian con el deploy

**Disparador**: en local el proceso corre como user con acceso a `/var/log/app/`. En el servidor corre como `NetworkService` sin permisos → log silencioso.

**Cómo detectar**: Fase 5 — verificar usuario que ejecuta el proceso en cada entorno + permisos sobre carpetas críticas.

---

## I-014 — Dependencia indirecta upgrade rompe módulo legacy

**Disparador**: `npm install` actualiza una sub-dependencia. Módulo legacy que dependía del comportamiento viejo rompe.

**Cómo detectar**: Fase 4 — diff de `package-lock.json` / `yarn.lock` además del package.json.

---

## Cómo añadir una trampa nueva

Tras detectar un bug de interacción que NO está aquí:

1. Aislar **el disparador** (qué condición lo provoca).
2. Documentar **cómo detectarlo proactivamente** (qué cruzar en Fase 4 para verlo antes).
3. Anotar **caso real** anonimizado.
4. Si el patrón también puede aparecer en aislado (no requiere interacción), va en `known-bugs.md`.
