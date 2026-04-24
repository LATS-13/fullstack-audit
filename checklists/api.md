# Checklist: APIs / endpoints HTTP

## Validación de input

- [ ] Cada endpoint valida body/query/params (Zod, Joi, Pydantic, etc.)
- [ ] Tipos correctos (números no son strings, fechas parseadas)
- [ ] Tamaños máximos en strings y arrays
- [ ] Sanitización de input que va a HTML/SQL/shell

## Status codes

- [ ] 200 solo para éxito real (NO 200 con `{error: ...}` en body)
- [ ] 201 para creaciones, 204 para deletes sin retorno
- [ ] 400 input inválido, 401 no auth, 403 sin permiso, 404 no existe, 409 conflicto
- [ ] 422 si se distingue de 400 (validación vs sintaxis)
- [ ] 5xx solo para errores del servidor, no para "el usuario hizo algo mal"

## Error handling

- [ ] Errores con mensaje útil al cliente, sin filtrar stack/internals
- [ ] Errores logueados server-side con contexto (correlation id, user id, request)
- [ ] Sin endpoints que devuelvan defaults silenciosos (`return []` en catch genérico)
- [ ] Errores de validación con detalle de qué campo falla
- [ ] Sin propagar errores de BD/servicios externos al cliente sin transformar

## Idempotencia y concurrencia

- [ ] PUT/DELETE idempotentes
- [ ] POST con riesgo de doble click protegidos (Idempotency-Key o lock optimista)
- [ ] Locks pesimistas con timeout y try/finally para liberarlos
- [ ] Sin race conditions en endpoints de mutación crítica (pagos, órdenes)

## Paginación y límites

- [ ] Endpoints que devuelven listas tienen LIMIT/OFFSET o cursor
- [ ] Default limit razonable (≤100)
- [ ] Max limit hardcodeado server-side (NO confiar en cliente)

## Rate limiting

- [ ] Endpoints públicos con rate limit
- [ ] Endpoints caros (export, search) con rate limit más estricto
- [ ] Headers `X-RateLimit-*` o equivalentes

## Headers de seguridad

- [ ] CORS configurado correctamente (whitelist)
- [ ] CSP en respuestas HTML
- [ ] HSTS, X-Content-Type-Options, X-Frame-Options
- [ ] No leak de versión del server

## Servicios externos

- [ ] Llamadas con `timeout` (NO indefinido)
- [ ] Retries con backoff (NO retry inmediato infinito)
- [ ] Circuit breaker en servicios inestables
- [ ] Fallback documentado: degradación o error claro, NO default silencioso

## Logging

- [ ] Cada request loguea: method, path, status, duración, user-id si auth
- [ ] Errores 5xx con stack
- [ ] Sin loguear bodies con datos sensibles (passwords, tokens, PII)
- [ ] Correlation ID propagado entre servicios

## Documentación

- [ ] OpenAPI/Swagger o equivalente, al menos para endpoints públicos
- [ ] Cambios breaking documentados (changelog, version en path/header)
- [ ] Endpoints deprecados marcados con `Deprecation` y `Sunset` headers

## Endpoints peligrosos

- [ ] No endpoints `/debug`, `/admin`, `/internal` accesibles en producción sin auth
- [ ] Endpoint `/health` no expone secrets ni topología
- [ ] Endpoint de métricas (Prometheus) protegido o solo en red interna
