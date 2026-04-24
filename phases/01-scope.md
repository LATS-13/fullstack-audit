# FASE 1 — Scope

> **Output**: `audit/<timestamp>/scope.md`
> **Tiempo**: 5–10 min con el usuario
> **Salida**: contrato escrito de qué se audita y qué NO

---

## Por qué importa

Sin scope, las auditorías se vuelven prosa exploratoria. Con scope, son entregables verificables.

Esta fase es **obligatoria** y se hace **siempre con el usuario delante**. Sin acuerdo del usuario, no se pasa a la fase 2.

---

## Pasos

### 1. Detectar stack

```bash
bash scripts/detect-stack.sh > audit/$STAMP/stack.md
```

El script identifica:
- Lenguajes y frameworks (front + back + bridges)
- DBs y sus migraciones
- Auth
- Hosting / servicios
- Tests existentes
- Tamaño aproximado (LOC, archivos)

### 2. Listar cambios recientes

```bash
git log --since="$WINDOW" --pretty=format:'%h %ad %s' --date=short \
  > audit/$STAMP/recent-commits.txt

git diff --stat $(git rev-parse HEAD~30) HEAD \
  > audit/$STAMP/recent-diff-stat.txt
```

Default `WINDOW="14 days ago"`. El usuario puede ampliarlo o reducirlo.

### 3. Preguntar al usuario (todo en UN mensaje, no goteando)

> Antes de empezar la auditoría, necesito acordar el scope. Responde a estos puntos:
>
> **A. Áreas a auditar** (escoge una o varias):
>   - [ ] Auth y sesiones
>   - [ ] Capa de datos (DB, migraciones, queries)
>   - [ ] APIs / endpoints HTTP
>   - [ ] Servicios externos (bridges, integraciones, colas)
>   - [ ] Frontend (componentes, estado, rendering)
>   - [ ] CSS / visual / responsive
>   - [ ] Configuración de producción (env vars, secrets, hosting)
>   - [ ] Lógica de negocio específica: ____________
>
> **B. Áreas explícitamente FUERA del scope** (lo que NO quieres que toque):
>
> **C. Profundidad**:
>   - [ ] Rápida (~30 min): solo estático + cruce + config
>   - [ ] Media (~2h): + runtime + visual ligero
>   - [ ] Profunda (~medio día): + visual completo + reproducciones manuales
>
> **D. Ventana de cambios a cruzar**:
>   - últimos N commits, o desde una fecha
>
> **E. Servicios externos disponibles** (¿puedo levantarlos en local?):
>   - [ ] BD (qué tipo, cómo)
>   - [ ] Bridges / APIs externas
>   - [ ] Auth de terceros
>
> **F. Acceso a producción**:
>   - [ ] Tengo logs accesibles
>   - [ ] Tengo dashboard de hosting (Railway, Vercel, etc.)
>   - [ ] Tengo acceso a env vars de producción

### 4. Escribir `scope.md`

Plantilla:

```markdown
# Scope de auditoría — <PROYECTO> — <FECHA>

## Stack detectado
<resumen de stack.md>

## Áreas IN scope
- ...

## Áreas OUT of scope
- ...

## Profundidad: <rápida|media|profunda>

## Ventana de cambios: <X commits | desde DATE>

## Servicios disponibles en local
- ...

## Acceso a producción
- ...

## Riesgos conocidos del proyecto
<de patterns/known-bugs.md, los que aplican a este stack>

## Tiempo estimado: <h>
```

### 5. Confirmar con el usuario antes de pasar a Fase 2

> "Scope acordado. Empiezo la Fase 2 (Estático). ¿Adelante?"

Sin ese OK, no continuar.

---

## Antipatrones

- ❌ "Audito toda la app". → Sin scope = sin entregable claro.
- ❌ Empezar a leer código sin haber acordado qué leer.
- ❌ Asumir profundidad por defecto sin preguntar.
- ❌ Saltarse la lista de áreas OUT — son las que más bugs traen cuando se cuelan en futuras fases.
