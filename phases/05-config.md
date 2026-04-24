# FASE 5 — Configuración (env vars, secrets, hosting)

> **Output**: `audit/<timestamp>/05-config.md`
> **Tiempo**: 10–30 min
> **Depende de**: scope.md (acceso a producción declarado)

---

## Por qué esta fase es obligatoria

Bugs invisibles a auditorías de código:
- Env var faltante en producción → fallback silencioso → feature rota sin error.
- Env var con valor distinto entre servicios → autenticación cruzada falla.
- Secret rotado en un sitio y no en otro.
- Feature flag activo en staging y no en prod (o al revés).
- DNS/red apuntando a host obsoleto.

**Lo que NO está en el repo es lo que más rompe.** Esta fase compara: lo que el código espera vs lo que está documentado vs lo que hay en producción.

---

## Pasos

### 1. Inventario de env vars usadas en código

```bash
bash scripts/env-check.sh > audit/$STAMP/env-inventory.md
```

El script:
- Recorre todo el código y extrae `process.env.X`, `os.environ['X']`, `getenv('X')`, `${{ env.X }}`, etc.
- Para cada var: archivos que la usan, valor por defecto si lo hay, criticidad inferida.

### 2. Inventario documentado

```bash
test -f .env.example && cat .env.example > audit/$STAMP/env-documented.txt
test -f .env.template && cat .env.template >> audit/$STAMP/env-documented.txt
test -f README.md && grep -A2 -i "env\|environment\|variable" README.md
```

### 3. Comparación

Tres listas:

- **A**: vars usadas en código
- **B**: vars documentadas (.env.example, README)
- **C**: vars en producción (Railway, Vercel, etc. — pedir al usuario o usar API)

Diferencias = findings:

- `A − B` (usada pero no documentada) → P2: añadir a .env.example
- `B − A` (documentada pero no usada) → P3: limpiar .env.example
- `A − C` (usada en código pero falta en producción) → **P0/P1**: feature rota o riesgo
- `C − A` (en producción pero no usada en código) → P3: secret huérfano

### 4. Acceso a producción

Si el usuario marcó en Fase 1 que tiene acceso a Railway / Vercel / etc., **pedir el listado**:

> "Necesito el listado de env vars de producción para cruzarlas con lo que el código espera. Opciones:
> - (A) Pega el listado (solo NOMBRES, no valores)
> - (B) Dame acceso CLI: `railway variables`, `vercel env ls`, `flyctl secrets list`
> - (C) Salto este check con asunción: 'todas las del .env.example están en prod'"

Default si el usuario salta: marcar finding F05-CONFIG-NN como "verificación de prod pendiente — alta probabilidad de bugs invisibles".

### 5. Secrets en repo

```bash
# git-secrets, trufflehog, o grep manual
grep -rEn "(api[_-]?key|secret|token|password|bearer)\s*[:=]\s*['\"][A-Za-z0-9_\-/+]{20,}" \
  --include="*.ts" --include="*.js" --include="*.py" --include="*.json" --include="*.yml" --include="*.yaml" \
  --exclude-dir=node_modules --exclude-dir=.git \
  | grep -v "process\.env\|os\.environ\|getenv\|example\|test\|mock"
```

Match real → **P0** y rotar el secret inmediatamente.

### 6. Infraestructura externa

Si aplica al stack:
- DNS / dominios (`dig <dominio>`, comparar con config esperada)
- HTTPS / certificados (caducidad)
- CDN / cache (purgas pendientes)
- Webhooks externos (URL apuntando a host correcto)
- Cron jobs / scheduled tasks (activos y al día)

### 7. Hosting health

Si hay acceso a CLI del hosting:

```bash
# Railway
railway status
railway logs --tail 200

# Vercel
vercel ls --json | head -100
vercel logs <deployment> -n 100

# Fly
flyctl status -a <app>
flyctl logs -a <app>
```

Buscar errores recientes, deploys fallidos, restarts inusuales.

---

## Output `05-config.md`

```markdown
# Fase 5 — Configuración

## Inventario
- Vars en código: N
- Vars documentadas: M
- Vars en producción: K (o "no verificado")

## Diferencias
- En código y NO en producción: <lista CRÍTICA>
- En código y NO documentadas: <lista>
- Documentadas y NO usadas: <lista>

## Secrets en repo: <N matches reales>

## Infra externa
- DNS: ✅/⚠️/❌
- HTTPS: caduca <fecha>
- Webhooks: <estado>
- Cron: <estado>

## Findings (F05-NN)
<usar templates/finding.md>
```

---

## Antipatrones

- ❌ Asumir que producción tiene lo mismo que `.env.example`.
- ❌ Saltar esta fase porque "no tengo acceso" — al menos documentar la asunción como finding.
- ❌ Confundir `.env.local` (dev) con `.env.production` (prod).
- ❌ No revisar deploys recientes en el dashboard del hosting.
