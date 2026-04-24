# Checklist: Servicios externos / bridges / integraciones

## Cliente HTTP

- [ ] Timeouts configurados (connect, read, total)
- [ ] Retries con backoff exponencial + jitter
- [ ] Max retries acotado (NO infinito)
- [ ] Circuit breaker en servicios inestables (open/half-open/closed)
- [ ] Pool de conexiones reusado (NO crear cliente nuevo por request)

## Auth a servicio externo

- [ ] API keys / tokens en env var, NO en código
- [ ] Rotación de secrets documentada
- [ ] Bearer token en `Authorization` header, NO en query string
- [ ] Validación al startup: si la key falta o es inválida, fallar RUIDOSAMENTE

## Manejo de errores

- [ ] Errores 4xx del servicio externo NO se reintenten (es bug propio)
- [ ] Errores 5xx + timeouts SÍ se reintenten con backoff
- [ ] Si el servicio cae: degradación con mensaje útil, NO default silencioso
- [ ] Logs incluyen: endpoint, status, latencia, body de error (truncado)

## Contratos

- [ ] Tipos del response del servicio externo definidos (no `any`)
- [ ] Validación del response antes de usarlo (Zod, etc.)
- [ ] Cambios en el servicio externo detectados (tests de contrato o smoke periódico)

## Fallbacks legacy

- [ ] **Sin fallbacks silenciosos a endpoints viejos del propio servicio externo** (clásico: cliente cae a `/api/v1` cuando `/api/v2` falla, sin avisar)
- [ ] Si hay fallback, es explícito y logueado al menos una vez por sesión
- [ ] Endpoints deprecados del servicio externo: cliente actualizado antes de que se cierren

## Bridges propios (microservicios internos)

- [ ] Healthcheck del bridge expuesto y monitoreado
- [ ] Versión del bridge expuesta en el healthcheck
- [ ] Auto-restart configurado (systemd, Windows Service, supervisord)
- [ ] Logs del bridge accesibles y rotados
- [ ] Despliegue idempotente con rollback
- [ ] Documentación de recovery en `RECOVERY.md` o similar

## Network

- [ ] VPN / tunnel verificado (ZeroTier, Tailscale, WireGuard)
- [ ] DNS estable (no IP hardcoded salvo necesidad explícita)
- [ ] TLS verificado (NO `rejectUnauthorized: false` en producción)

## Webhooks (entrantes)

- [ ] Firma del webhook verificada (HMAC con secret compartido)
- [ ] Idempotencia: misma notificación procesada 2 veces NO causa daño
- [ ] Respuesta rápida (encolar trabajo si tarda >2s)
- [ ] Reintentos del proveedor manejados

## Webhooks (salientes)

- [ ] Reintentos con backoff
- [ ] Dead letter queue tras N fallos
- [ ] Visibilidad: dashboard o logs para ver entregas

## Observabilidad

- [ ] Métricas de cada servicio externo: latencia p50/p99, error rate, throughput
- [ ] Alertas si error rate >umbral o latencia >umbral
- [ ] Trazas distribuidas (correlation id propagado)
