# Checklist: Frontend (componentes, estado, rendering)

## Estados de UI

- [ ] Cada vista tiene los 4 estados definidos: loading, empty, error, success
- [ ] **Empty state con mensaje útil** (NO pantalla en blanco)
- [ ] Error state con acción ("Reintentar", "Contactar soporte")
- [ ] Loading: skeleton o spinner, NO contenido a medias

## Defensivo vs silencioso

- [ ] Defaults `[]` o `{}` en `useFetch` NO enmascaran errores — verificar en el catch que se loguea
- [ ] Errores de red mostrados al usuario, NO solo console.log
- [ ] Si el componente espera datos y no llegan: mostrar "No hay datos" o error, NUNCA pantalla vacía

## Manejo de fetch

- [ ] Cancelación al desmontar componente (AbortController)
- [ ] Reintentos manuales accesibles desde la UI
- [ ] Debouncing en búsquedas
- [ ] Caching cuando aplique (SWR, useFetch con key)

## Reactividad / estado

- [ ] Sin mutaciones directas de props
- [ ] Estado derivado vía computed/useMemo, NO estado duplicado
- [ ] Stores globales solo para estado verdaderamente global (auth, tema)
- [ ] Sin setIntervals/setTimeouts olvidados (cleanup en unmount)

## Formularios

- [ ] Validación client-side + server-side (NO solo client)
- [ ] Feedback de error por campo
- [ ] Disabled del submit mientras envía (anti doble submit)
- [ ] Reset/feedback tras éxito

## Imágenes / assets

- [ ] Lazy loading donde aplique
- [ ] Sizes / dimensiones para evitar layout shift
- [ ] Fallback si la imagen falla
- [ ] WebP/AVIF servidos con fallback

## Accesibilidad

- [ ] Labels en inputs (NO solo placeholder)
- [ ] Botones con texto o aria-label
- [ ] Contraste suficiente (WCAG AA mínimo)
- [ ] Navegación por teclado (focus visible, tab order)
- [ ] Roles ARIA donde la semántica lo requiera

## Performance

- [ ] Bundle size razonable (analizar con `vite-plugin-inspect` o equivalente)
- [ ] Code splitting por ruta
- [ ] Lazy load de componentes pesados (charts, editores)
- [ ] Sin render loops o re-renders innecesarios

## SEO (si aplica)

- [ ] `<title>` y meta description únicos por página
- [ ] OG tags
- [ ] Sitemap + robots.txt
- [ ] SSR/SSG donde tiene sentido

## Console / errores en runtime

- [ ] Sin warnings de Vue/React en producción
- [ ] Sin console.log en producción
- [ ] Sentry/Bugsnag/equivalente capturando errores no manejados

## Internacionalización (si aplica)

- [ ] Strings hardcoded extraídos a i18n
- [ ] Fechas/números formateados según locale
- [ ] Plural rules correctas
