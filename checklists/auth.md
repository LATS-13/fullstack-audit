# Checklist: Autenticación y sesiones

> Verificar cada bullet con archivo:línea. Si no aplica → N/A explícito.

## Passwords y credenciales

- [ ] Passwords hasheados con bcrypt/argon2/scrypt (NO md5/sha256/plain)
- [ ] Cost factor adecuado (bcrypt ≥10, argon2 OWASP defaults)
- [ ] Sin passwords/secrets en logs
- [ ] Sin credenciales por defecto en código (`admin/admin`)
- [ ] Reset de password con token de un solo uso, expiración corta
- [ ] Email/SMS de cambio de password al usuario afectado

## Sesiones / tokens

- [ ] Cookies de sesión: `HttpOnly`, `Secure` (en prod), `SameSite=Lax|Strict`
- [ ] Tokens con expiración razonable (access ≤1h si refresh existe; sesiones cookie ≤7d)
- [ ] Refresh tokens rotados al usar (one-time)
- [ ] Logout revoca el token server-side, no solo borra cookie
- [ ] JWT firmados con algoritmo seguro (NO `none`, NO HS256 con secret débil)
- [ ] Validación completa del JWT: expiración, issuer, audience
- [ ] PIN/códigos cortos: rate limit + lockout tras N intentos

## Autorización

- [ ] Cada endpoint protegido tiene middleware de auth, NO check ad-hoc en handler
- [ ] Cada acción verifica que el recurso pertenece al usuario (IDOR)
- [ ] Roles/permisos validados server-side, NO solo en frontend
- [ ] Endpoints de admin separados o con check explícito de rol
- [ ] Sin endpoints "internal" expuestos sin auth (debug, metrics, health con info sensible)

## Rate limiting

- [ ] Login con rate limit por IP + por usuario
- [ ] Endpoints de envío (email, SMS) con rate limit
- [ ] Endpoints públicos con rate limit anti-DDoS

## OAuth / SSO (si aplica)

- [ ] State parameter validado (CSRF en OAuth)
- [ ] Redirect URIs whitelist
- [ ] Tokens de tercero almacenados encriptados o no almacenados
- [ ] Scope mínimo solicitado

## Multi-auth (admin + portal, etc.)

- [ ] Sistemas de auth separados sin posibilidad de "salto" entre ellos
- [ ] Cookies/tokens con nombres distintos
- [ ] Middleware separado por sistema, sin caer en el del otro
- [ ] Logout de uno NO afecta sesiones del otro (salvo que sea el comportamiento deseado)

## CSRF / CORS

- [ ] CSRF tokens en mutaciones si se usan cookies de sesión
- [ ] CORS con whitelist de orígenes (NO `*` en endpoints autenticados)

## Auditoría / logs

- [ ] Logins fallidos logueados (con IP, sin password)
- [ ] Cambios de permisos / acciones críticas logueados
- [ ] Logs accesibles para investigar incidentes

## Edge cases

- [ ] Usuario borrado → sesiones invalidadas
- [ ] Cambio de password → otras sesiones invalidadas (opcional pero recomendado)
- [ ] Tokens caducados devuelven 401, no 500
