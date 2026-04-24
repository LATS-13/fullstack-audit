# Fullstack Audit

Skill para Claude Code (y Cowork). Auditoría reproducible de cualquier app fullstack en 8 fases.

## Instalación

```bash
# Para que Code lo detecte automáticamente, debe estar en ~/.claude/skills/
cp -r /Users/rafita/skills/fullstack-audit ~/.claude/skills/

# Verificar
ls ~/.claude/skills/fullstack-audit/SKILL.md

# Permisos de ejecución a los scripts
chmod +x ~/.claude/skills/fullstack-audit/scripts/*.sh
chmod +x ~/.claude/skills/fullstack-audit/scripts/*.ts
```

## Cómo se invoca desde Code

```
> Audita PharmaSuite con el skill fullstack-audit. Scope: pestañas Ventas, Incentivos. Profundidad: media.
```

Code detecta el skill por la descripción del frontmatter en `SKILL.md` y lo carga.

## Cómo se invoca desde Cowork

Igual, pero Cowork puede tener limitaciones de permisos para escribir en `~/.claude/skills/`. Si pasa, mantener una copia editable en `/Users/rafita/skills/fullstack-audit/` y sincronizar manualmente.

## Estructura

```
fullstack-audit/
├── SKILL.md                    # entrypoint (Code lo lee primero)
├── README.md                   # esto
├── phases/
│   ├── 01-scope.md
│   ├── 02-static.md
│   ├── 03-domain.md
│   ├── 04-cross-ref.md
│   ├── 05-config.md
│   ├── 06-runtime.md
│   ├── 07-visual.md
│   └── 08-report.md
├── checklists/
│   ├── auth.md
│   ├── db.md
│   ├── api.md
│   ├── external.md
│   ├── frontend.md
│   └── visual.md
├── patterns/
│   ├── known-bugs.md           # catálogo evolutivo — actualizar tras cada audit
│   └── interaction-traps.md    # bugs de interacción
├── templates/
│   └── finding.md
└── scripts/
    ├── run-audit.sh            # orquestador (entrypoint manual)
    ├── detect-stack.sh         # autodetect del stack
    ├── env-check.sh            # comparación env vars código vs .env.example
    ├── smoke-endpoints.sh      # cURL batch con verificación de shape
    └── visual-check.ts         # Playwright + screenshots + a11y básica
```

## Outputs

Cada auditoría escribe a `<proyecto>/audit/<YYYY-MM-DD-HHMM>/`:

```
audit/2026-04-24-1530/
├── scope.md
├── stack.md
├── 02-static.md
├── 03-domain.md
├── 04-cross-ref.md
├── 05-config.md
├── 06-runtime.md
├── 07-visual.md
├── 07-visual/             # screenshots
├── REPORT.md              # informe final
└── logs/
```

## Mantenimiento

Tras cada auditoría, **actualizar `patterns/`** con los bugs nuevos encontrados como patrones abstractos. Esto hace que el skill sea cada vez mejor.

Si una checklist se queda corta para un stack, añadir bullets o crear nueva checklist en `checklists/<area>.md`.

## Filosofía

1. Scope explícito antes que cobertura completa.
2. Reproducción obligatoria por finding.
3. Memoria institucional vía patrones.
4. Estático **+** dinámico **+** visual **+** config. Ninguno solo basta.
5. La fase de Cruce (04) es la que más bugs reales pilla — no saltarla.

---

## Automatización (3 niveles)

### 1. Regla en CLAUDE.md (ya instalado)

Claude Code propone auditoría automáticamente en los disparadores (sprint de fixes, pre-deploy, cambios en auth/DB/externos). Sección `## PROTOCOLO DE AUDITORÍA` en `~/.claude/CLAUDE.md`.

### 2. Git hook pre-push (por proyecto)

Checks rápidos (<5s) antes de cada push: env vars huérfanas, console.log, patrones tóxicos.

```bash
cd <proyecto>
bash ~/.claude/skills/fullstack-audit/scripts/install-hooks.sh
```

Bypass puntual: `git push --no-verify`

### 3. GitHub Action (por repo)

Corre fases 2+4+5 en cada PR y comenta el REPORT.md como sticky comment.

```bash
cd <proyecto>
bash ~/.claude/skills/fullstack-audit/scripts/install-github-action.sh
git add .github/workflows/fullstack-audit.yml
git commit -m "ci: fullstack-audit workflow"
git push
```
