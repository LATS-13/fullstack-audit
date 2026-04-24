# FASE 6 — Runtime / smoke

> **Output**: `audit/<timestamp>/06-runtime.md` + logs
> **Tiempo**: 20–60 min
> **Depende de**: scope.md (servicios disponibles), 05-config.md

---

## Objetivo

Levantar la app en local y verificar que cada endpoint crítico responde de verdad (no con default vacío silencioso). Capturar errores de runtime invisibles a estática.

---

## Pasos

### 1. Levantar servicios

Detectar comando de arranque:

```bash
# Node
jq -r '.scripts.dev // .scripts.start' package.json
# Python
test -f manage.py && echo "python manage.py runserver"
# Docker
test -f docker-compose.yml && echo "docker compose up -d"
```

Levantar **todo lo necesario** según el stack:
- Frontend
- Backend
- BD (si es local: Postgres en Docker, etc.)
- Servicios externos / mocks (si bridge real no accesible: levantar mock con responses canónicas)

```bash
# Ejemplo Nuxt + Oracle bridge mock
npm run dev > audit/$STAMP/dev.log 2>&1 &
NUXT_PID=$!
node scripts/oracle-bridge-mock.js > audit/$STAMP/bridge-mock.log 2>&1 &
BRIDGE_PID=$!

sleep 8  # esperar arranque
```

### 2. Healthcheck básico

```bash
curl -fsS http://localhost:3000/api/health | jq .
curl -fsS http://localhost:3000/api/_nuxt/healthcheck 2>/dev/null || true
```

Si no responde → finding P0 + abortar fase (revisar logs en `dev.log`).

### 3. Smoke de endpoints críticos

Definir lista de endpoints a probar (de scope.md o consensuado con usuario):

```bash
bash scripts/smoke-endpoints.sh \
  --base http://localhost:3000 \
  --endpoints audit/$STAMP/endpoints.txt \
  --output audit/$STAMP/smoke.md
```

`endpoints.txt`:
```
GET /api/ventas/kpis
GET /api/ventas/historico?periodo=mes
GET /api/incentivos/dashboard
POST /api/auth/login {"email":"test","password":"test"}
```

El script para cada endpoint:
- Hace la petición
- Mide latencia
- Comprueba status code esperado
- Comprueba **shape de la respuesta** (no `[]` ni `{datos: []}` cuando se esperan datos)
- Detecta defaults silenciosos (campos vacíos donde debería haber datos)

### 4. Auth smoke

Si auth está IN scope:
- Login con credenciales válidas → recibe cookie/token
- Login con inválidas → 401, no leak de info
- Acceso a ruta protegida sin token → 401
- Acceso con token caducado → 401
- Acceso con token de otro usuario → 403

### 5. Logs durante el smoke

Mientras corre el smoke, vigilar `audit/$STAMP/dev.log` y `bridge-mock.log`:

```bash
grep -iE "(error|exception|warn|fail|timeout|denied)" audit/$STAMP/dev.log \
  > audit/$STAMP/runtime-warnings.txt
```

Cualquier error en logs durante un smoke "exitoso" es un finding (la app esconde fallos).

### 6. Pruebas de degradación

Si scope incluye servicios externos:
- Apagar el servicio externo (BD, bridge) y repetir smoke crítico
- Verificar que la app degrada con error claro al usuario, no con default vacío

```bash
kill $BRIDGE_PID
sleep 2
curl -fsS http://localhost:3000/api/ventas/historico
# Esperado: 503 con mensaje útil. Si devuelve 200 con [] → finding P1.
```

### 7. Apagar todo

```bash
kill $NUXT_PID $BRIDGE_PID 2>/dev/null
```

---

## Output `06-runtime.md`

```markdown
# Fase 6 — Runtime smoke

## Servicios levantados
- Nuxt :3000 — OK
- Oracle bridge mock :3000 — OK
- DB SQLite local — OK

## Smoke
| Endpoint | Status | Latencia | Shape OK | Notas |
|----------|--------|----------|----------|-------|
| GET /api/ventas/kpis | 200 | 145ms | ✅ | |
| GET /api/ventas/historico | 200 | 320ms | ❌ | datos:[] inesperado |

## Auth
- Login válido: ✅
- Login inválido: ✅ 401
- Ruta protegida sin auth: ⚠️ 200 en vez de 401 → F06-AUTH-01

## Logs durante smoke
- 3 warnings, 1 error → ver runtime-warnings.txt

## Degradación
- Bridge caído + GET /ventas/historico → 200 con datos:[] (debería 503) → F06-DEGRADE-01

## Findings (F06-NN)
```

---

## Antipatrones

- ❌ Confiar en status 200 sin verificar shape (defaults vacíos enmascaran fallos).
- ❌ Smoke con datos seed perfectos → no representativo. Usar datos realistas.
- ❌ Saltar pruebas de degradación porque "el servicio siempre está up".
- ❌ No mirar los logs durante el smoke — los errores silenciosos solo aparecen ahí.
