# Checklist: Base de datos

## Migraciones

- [ ] Versionadas (numeradas o con timestamp)
- [ ] Idempotentes (`CREATE TABLE IF NOT EXISTS`, `ALTER TABLE ADD COLUMN IF NOT EXISTS`)
- [ ] Reversibles o con plan de rollback documentado
- [ ] Aplicadas automáticamente al startup o vía CI, NO manual
- [ ] Tabla `schema_migrations` o equivalente para tracking
- [ ] Migraciones grandes (NOT NULL en tabla con datos) tienen backfill plan
- [ ] Sin DROP COLUMN sin verificar que ningún código lee esa columna

## Schema

- [ ] PKs definidas en cada tabla
- [ ] FKs con ON DELETE/ON UPDATE explícitos
- [ ] Índices en columnas usadas frecuentemente en WHERE/JOIN/ORDER BY
- [ ] Sin índices duplicados o huérfanos
- [ ] Tipos adecuados (INT vs BIGINT, VARCHAR(N) razonable, TIMESTAMP WITH TZ)
- [ ] Constraints (NOT NULL, UNIQUE, CHECK) donde corresponde
- [ ] Sin columnas "todo en uno" (JSON gigante donde debería haber tabla relacional)

## Queries

- [ ] Sin SQL concatenado con strings (usar bind params)
- [ ] Sin `SELECT *` en código de producción (riesgo al añadir columnas)
- [ ] Queries N+1 detectadas y corregidas (eager loading o JOIN)
- [ ] LIMIT en endpoints que devuelven listas (paginación)
- [ ] Transacciones donde hay múltiples mutaciones relacionadas
- [ ] Rollback en catch de transacciones

## Conexiones

- [ ] Pool de conexiones configurado (no abrir/cerrar por request)
- [ ] Timeouts configurados (connection, query, idle)
- [ ] Reconexión automática tras fallo transitorio
- [ ] Métricas de pool expuestas (active, idle, waiting)

## Backups

- [ ] Backups automáticos configurados
- [ ] Frecuencia adecuada al RPO del negocio
- [ ] Retención documentada
- [ ] **Restore probado al menos una vez**
- [ ] Backups en ubicación distinta al primario (otra región/proveedor)
- [ ] Backups encriptados si contienen datos sensibles

## Datos sensibles

- [ ] PII/PHI encriptado at-rest (DB-level o app-level)
- [ ] Sin secretos en BD en plano (API keys de terceros)
- [ ] Logs no incluyen datos sensibles de filas (solo IDs)

## Multi-tenant (si aplica)

- [ ] Cada query filtra por tenant_id
- [ ] Tests automáticos que verifiquen aislamiento entre tenants
- [ ] Sin endpoints que devuelvan datos cross-tenant

## Performance

- [ ] EXPLAIN/ANALYZE de queries críticas pasado al menos una vez
- [ ] Slow query log activo en producción
- [ ] Sin queries que escaneen tablas grandes sin índice

## Compatibilidad legacy (si hay BD heredada como Oracle 11g)

- [ ] Driver/cliente compatible con la versión real
- [ ] Sintaxis SQL compatible (sin features de versiones modernas)
- [ ] Charset / NLS configurado correctamente
- [ ] Pool con límite acorde a la licencia/recursos del servidor legacy
