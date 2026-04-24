# Checklist: Visual / CSS / responsive

## Layout

- [ ] Sin scroll horizontal en NINGUNA pantalla a 320/375/768/1280/1920
- [ ] Cards/contenedores sin overflow visible (texto cortado, bordes rotos)
- [ ] Grid/flex con gap consistente
- [ ] Padding/margin coherente entre secciones similares

## Componentes con N variable

- [ ] Listas largas con scroll o paginación
- [ ] **Charts/barras escalan al número real de items** (no `min-width` fijo que rompa con N grande — caso clásico: gráfico mensual con 31 días vs trimestral con 92)
- [ ] Tablas con scroll horizontal en mobile o cambio de layout (cards)
- [ ] Tags/chips que envuelven, no desbordan

## Texto

- [ ] Sin overflow de texto sin `text-overflow: ellipsis` ni `word-break`
- [ ] `white-space: nowrap` solo donde tiene sentido
- [ ] Tamaño de fuente legible en mobile (≥14px body)
- [ ] Line-height suficiente (1.4–1.6 para body)

## Color y contraste

- [ ] Contraste WCAG AA (4.5:1 texto normal, 3:1 texto grande)
- [ ] No depender SOLO del color para información (rojo=error → también icono o texto)
- [ ] Estados hover/focus/active visibles
- [ ] Tema oscuro / claro coherente (si aplica)

## Estados

- [ ] Loading skeletons del mismo shape que el contenido final
- [ ] Empty state diseñado, NO pantalla vacía
- [ ] Error state con icono + mensaje + acción
- [ ] Disabled vs loading vs read-only diferenciables visualmente

## Touch targets (mobile)

- [ ] Botones/links ≥44x44px
- [ ] Espaciado entre targets ≥8px
- [ ] Sin gestos exclusivos (cada acción tiene botón visible)

## Imágenes / iconos

- [ ] Sin distorsión (object-fit: cover o contain según caso)
- [ ] Iconos coherentes en tamaño y peso
- [ ] Alt text en imágenes informativas

## Animaciones

- [ ] Sin animaciones >300ms en transiciones funcionales
- [ ] Respeto a `prefers-reduced-motion`
- [ ] Sin parpadeos / flash

## Z-index

- [ ] Modales por encima de todo
- [ ] Tooltips por encima de modales (si aplica)
- [ ] Sin solapamientos inesperados (botones tapados por nav, etc.)

## Print (si aplica)

- [ ] Stylesheet de print que oculta nav/sidebar
- [ ] Colores legibles en B/N

## Branding / coherencia

- [ ] Tipografía consistente
- [ ] Colores del design system (sin hex sueltos)
- [ ] Border-radius coherente (o ausencia de él, si es la decisión)
- [ ] Sombras coherentes

## Multi-resolución / multi-densidad

- [ ] @1x, @2x, @3x para iconos críticos
- [ ] Layouts que respiran a partir de 1440px (no centrados con espacio gigante a los lados sin contenido)
