#!/usr/bin/env bash
# smoke-endpoints.sh — golpea una lista de endpoints y reporta resultados
# Uso:
#   smoke-endpoints.sh --base http://localhost:3000 --endpoints endpoints.txt --output smoke.md
#
# endpoints.txt formato (una línea por endpoint):
#   GET /api/health
#   GET /api/ventas/kpis
#   POST /api/auth/login {"email":"x@y.z","password":"123"}
#   GET /api/ventas/historico?periodo=mes EXPECT_NONEMPTY=datos
#
# Flags por endpoint:
#   EXPECT_STATUS=200          (default 200)
#   EXPECT_NONEMPTY=campo      (verifica que body.campo NO sea [], {}, null)
#   AUTH=cookie:portal_token   (envía cookie de auth)

set -e
BASE=""
ENDPOINTS=""
OUTPUT="/dev/stdout"
COOKIES_FILE=$(mktemp)

while [ $# -gt 0 ]; do
  case "$1" in
    --base) BASE="$2"; shift 2 ;;
    --endpoints) ENDPOINTS="$2"; shift 2 ;;
    --output) OUTPUT="$2"; shift 2 ;;
    --cookies) cp "$2" "$COOKIES_FILE"; shift 2 ;;
    *) echo "Flag desconocida: $1" >&2; exit 1 ;;
  esac
done

[ -z "$BASE" ] && { echo "Falta --base"; exit 1; }
[ -z "$ENDPOINTS" ] && { echo "Falta --endpoints"; exit 1; }
[ ! -f "$ENDPOINTS" ] && { echo "No existe $ENDPOINTS"; exit 1; }

{
  echo "# Smoke endpoints — $(date -Iseconds)"
  echo ""
  echo "Base: \`$BASE\`"
  echo ""
  echo "| Method | Path | Status | Latency | Shape | Notas |"
  echo "|--------|------|--------|---------|-------|-------|"

  while IFS= read -r line; do
    [ -z "$line" ] && continue
    [[ "$line" =~ ^# ]] && continue

    METHOD=$(echo "$line" | awk '{print $1}')
    PATH_=$(echo "$line" | awk '{print $2}')
    REST=$(echo "$line" | cut -d' ' -f3-)

    BODY=""
    if [[ "$REST" == \{* ]]; then
      BODY=$(echo "$REST" | grep -oE '^\{[^}]*\}' || true)
      REST=$(echo "$REST" | sed -E 's/^\{[^}]*\}\s*//')
    fi

    EXPECT_STATUS=200
    EXPECT_NONEMPTY=""
    for kv in $REST; do
      case "$kv" in
        EXPECT_STATUS=*) EXPECT_STATUS="${kv#*=}" ;;
        EXPECT_NONEMPTY=*) EXPECT_NONEMPTY="${kv#*=}" ;;
      esac
    done

    URL="${BASE}${PATH_}"
    START=$(date +%s%3N)
    if [ -n "$BODY" ]; then
      RESP=$(curl -sS -o /tmp/smoke-body -w "%{http_code}" -X "$METHOD" \
        -H "Content-Type: application/json" -d "$BODY" \
        --cookie-jar "$COOKIES_FILE" --cookie "$COOKIES_FILE" \
        "$URL" 2>&1) || RESP="000"
    else
      RESP=$(curl -sS -o /tmp/smoke-body -w "%{http_code}" -X "$METHOD" \
        --cookie-jar "$COOKIES_FILE" --cookie "$COOKIES_FILE" \
        "$URL" 2>&1) || RESP="000"
    fi
    END=$(date +%s%3N)
    LAT=$((END - START))

    NOTES=""
    SHAPE_OK="—"

    if [ "$RESP" != "$EXPECT_STATUS" ]; then
      NOTES="status esperado $EXPECT_STATUS, actual $RESP"
    fi

    if [ -n "$EXPECT_NONEMPTY" ] && [ "$RESP" = "200" ]; then
      VAL=$(jq -r ".${EXPECT_NONEMPTY}" /tmp/smoke-body 2>/dev/null || echo "ERROR")
      if [ "$VAL" = "[]" ] || [ "$VAL" = "{}" ] || [ "$VAL" = "null" ] || [ "$VAL" = "ERROR" ]; then
        SHAPE_OK="❌"
        NOTES="${NOTES} | .${EXPECT_NONEMPTY} vacío"
      else
        SHAPE_OK="✅"
      fi
    fi

    [ -z "$NOTES" ] && NOTES="—"
    echo "| $METHOD | \`$PATH_\` | $RESP | ${LAT}ms | $SHAPE_OK | $NOTES |"
  done < "$ENDPOINTS"
} > "$OUTPUT"

rm -f "$COOKIES_FILE" /tmp/smoke-body
echo "OK → $OUTPUT" >&2
