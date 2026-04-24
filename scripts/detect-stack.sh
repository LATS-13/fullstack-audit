#!/usr/bin/env bash
# detect-stack.sh — autodetecta el stack del proyecto en cwd
# Output: markdown a stdout. Pipe a archivo si quieres.

set -e
ROOT="${1:-$PWD}"
cd "$ROOT"

echo "# Stack detectado en \`$ROOT\`"
echo ""

# ----- Lenguajes -----
echo "## Lenguajes"
declare -A LANGS
[ -f package.json ] && LANGS[node]=1
[ -f pyproject.toml ] || [ -f requirements.txt ] || [ -f setup.py ] && LANGS[python]=1
[ -f Cargo.toml ] && LANGS[rust]=1
[ -f go.mod ] && LANGS[go]=1
[ -f pom.xml ] || [ -f build.gradle ] && LANGS[java]=1
[ -f Gemfile ] && LANGS[ruby]=1
[ -f composer.json ] && LANGS[php]=1
ls *.csproj 2>/dev/null | head -1 >/dev/null && LANGS[dotnet]=1
[ "${#LANGS[@]}" -eq 0 ] && echo "- (ninguno conocido detectado)" || \
  for l in "${!LANGS[@]}"; do echo "- $l"; done
echo ""

# ----- Frameworks -----
echo "## Frameworks"
if [ -f package.json ]; then
  jq -r '.dependencies + .devDependencies | keys[]?' package.json 2>/dev/null | while read dep; do
    case "$dep" in
      nuxt|next|@sveltejs/kit|astro|@remix-run/*|vite|vue|react|svelte) echo "- $dep" ;;
      express|fastify|@nestjs/core|hono) echo "- $dep" ;;
      better-sqlite3|pg|mysql2|mongodb|@supabase/*|prisma|drizzle-orm|kysely|typeorm) echo "- $dep" ;;
      better-auth|next-auth|lucia|@supabase/auth-helpers-*|passport*) echo "- $dep" ;;
      playwright|cypress|vitest|jest) echo "- $dep" ;;
    esac
  done
fi
[ -f manage.py ] && echo "- django"
grep -l "fastapi" requirements.txt pyproject.toml 2>/dev/null && echo "- fastapi"
grep -l "flask" requirements.txt pyproject.toml 2>/dev/null && echo "- flask"
echo ""

# ----- DB -----
echo "## Base de datos"
[ -d migrations ] || [ -d db/migrations ] || [ -d server/database/migrations ] && echo "- migraciones presentes"
find . -name "*.sqlite*" -not -path "*/node_modules/*" 2>/dev/null | head -3
grep -rEn "DATABASE_URL|DB_HOST|MONGO_URI|SUPABASE_URL" .env.example 2>/dev/null | head -10
echo ""

# ----- Auth -----
echo "## Auth"
grep -rEn "auth|session|token|cookie" middleware/ server/middleware/ 2>/dev/null | head -5 | awk -F: '{print "- "$1":"$2}'
echo ""

# ----- Hosting -----
echo "## Hosting"
[ -f railway.json ] || [ -f railway.toml ] && echo "- Railway"
[ -f vercel.json ] && echo "- Vercel"
[ -f netlify.toml ] && echo "- Netlify"
[ -f wrangler.toml ] && echo "- Cloudflare Workers/Pages"
[ -f fly.toml ] && echo "- Fly.io"
[ -f render.yaml ] && echo "- Render"
[ -f Dockerfile ] && echo "- Docker"
[ -f docker-compose.yml ] || [ -f docker-compose.yaml ] && echo "- docker compose"
ls -la /etc/systemd/system/*.service 2>/dev/null | head -3
ls ~/Library/LaunchAgents/*.plist 2>/dev/null | head -5
echo ""

# ----- Tests -----
echo "## Tests"
find . -type d \( -name "tests" -o -name "test" -o -name "__tests__" -o -name "e2e" \) \
  -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null | head -10
grep -rEn '"test"|"e2e"' package.json 2>/dev/null | head -5
echo ""

# ----- Tamaño -----
echo "## Tamaño"
LOC=$(find . -type f \( -name "*.ts" -o -name "*.js" -o -name "*.vue" -o -name "*.py" -o -name "*.cs" -o -name "*.go" -o -name "*.rs" \) \
  -not -path "*/node_modules/*" -not -path "*/.git/*" -not -path "*/dist/*" -not -path "*/.nuxt/*" 2>/dev/null \
  | xargs wc -l 2>/dev/null | tail -1 | awk '{print $1}')
FILES=$(find . -type f \( -name "*.ts" -o -name "*.js" -o -name "*.vue" -o -name "*.py" -o -name "*.cs" -o -name "*.go" -o -name "*.rs" \) \
  -not -path "*/node_modules/*" -not -path "*/.git/*" -not -path "*/dist/*" -not -path "*/.nuxt/*" 2>/dev/null | wc -l)
echo "- Archivos código: $FILES"
echo "- LOC aprox: $LOC"
echo ""

# ----- Git -----
if [ -d .git ]; then
  echo "## Git"
  echo "- Branch: $(git branch --show-current)"
  echo "- HEAD: $(git rev-parse --short HEAD) — $(git log -1 --pretty=format:'%s')"
  echo "- Último commit: $(git log -1 --pretty=format:'%ad' --date=relative)"
  echo "- Commits últimos 14d: $(git log --since='14 days ago' --oneline | wc -l)"
fi
