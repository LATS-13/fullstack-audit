# FASE 7 — Visual (Playwright)

> **Output**: `audit/<timestamp>/07-visual/*.png` + `07-visual.md`
> **Tiempo**: 15–45 min
> **Depende de**: 06-runtime.md (servicios up)

---

## Por qué esta fase existe

Bugs visuales que ningún grep pilla:
- Overflow de elementos (barras de gráfico cortadas, listas desbordadas)
- Texto sobre texto (z-index mal)
- Contraste insuficiente (texto verde sobre fondo verde)
- Mobile roto (botones 1px, scroll horizontal)
- Estados vacíos sin mensaje (pantalla en blanco vs "No hay datos")
- Spinners infinitos

---

## Pasos

### 1. Definir rutas a capturar

De scope.md o consensuado con usuario. Incluir:
- Ruta principal de cada módulo IN scope
- Estados: con datos, vacío, error, loading
- Por cada breakpoint relevante: mobile (375), tablet (768), desktop (1280)

### 2. Ejecutar captura

```bash
npx playwright install chromium  # primera vez
node scripts/visual-check.ts \
  --base http://localhost:3000 \
  --routes audit/$STAMP/routes.json \
  --output audit/$STAMP/07-visual/
```

`routes.json`:
```json
[
  { "name": "dashboard", "url": "/", "auth": "admin" },
  { "name": "ventas-mes", "url": "/ventas?periodo=mes", "auth": "admin" },
  { "name": "ventas-semana", "url": "/ventas?periodo=semana", "auth": "admin" },
  { "name": "portal-login", "url": "/portal/login", "auth": null },
  { "name": "portal-inicio", "url": "/portal/inicio", "auth": "portal" }
]
```

El script para cada ruta:
- Login si `auth` está definido
- Espera `networkidle` + 1s extra (animaciones)
- Captura PNG por breakpoint
- Captura console errors y network failures
- Detecta overflow horizontal (`document.documentElement.scrollWidth > window.innerWidth`)
- Detecta elementos clickables solapados o de <44px en mobile

### 3. Estados vacíos / error

Para cada ruta crítica, forzar:
- Estado vacío (sin datos en BD, o filtros que no devuelven nada)
- Estado de error (apagar BD/bridge)

Capturar también esos estados.

### 4. Revisión humana

Las imágenes se revisan visualmente (por Code abriendo, o por Cowork si tiene capacidad). Anotar findings:
- Elementos cortados
- Solapamientos
- Contraste pobre
- Falta de feedback en estado vacío/error

### 5. Comparación contra baseline (opcional)

Si existe `baseline/` con screenshots previos, hacer diff visual:

```bash
node scripts/visual-diff.ts \
  --baseline audit/baseline/ \
  --current audit/$STAMP/07-visual/ \
  --output audit/$STAMP/07-visual/diffs/
```

Cualquier regresión visual → finding P2.

### 6. Accesibilidad básica

```bash
node scripts/a11y-check.ts --routes audit/$STAMP/routes.json
```

Usa axe-core. Reportar issues serious/critical.

---

## Output `07-visual.md`

```markdown
# Fase 7 — Visual

## Capturas
- 07-visual/dashboard-desktop.png
- 07-visual/dashboard-mobile.png
- 07-visual/ventas-mes-desktop.png    ⚠️ overflow detectado
- 07-visual/ventas-mes-mobile.png     ❌ barras solapadas
...

## Console errors
| Ruta | Errores |
|------|---------|
| /ventas | 0 |
| /portal | 1 (favicon 404 — P3) |

## Network failures
- (ninguno)

## Overflow horizontal
- /ventas?periodo=mes desktop: scrollWidth 1450 > 1280 → F07-CSS-01

## Estados vacíos sin feedback
- /portal/nominas (empleada sin nóminas) → pantalla en blanco → F07-EMPTY-01

## A11y
- /ventas: 2 critical (contraste), 5 serious

## Findings (F07-NN)
```

---

## Antipatrones

- ❌ Saltar mobile porque "es admin tool" — admin también se abre desde móvil a veces.
- ❌ Capturar solo estado feliz (con datos) — los estados vacío/error son donde más bugs visuales hay.
- ❌ No revisar console.log del navegador — muchos bugs solo se ven ahí.
- ❌ Subjetividad sin criterios — usar checklist `checklists/visual.md`.
