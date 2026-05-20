#!/usr/bin/env bash
# Usage: bash tests/sniff-test.sh <prototype-dir>
# Returns: 0 if no HIGH findings, 1 if any HIGH findings
# Writes: <prototype-dir>/_ai-tells.md

set -euo pipefail

PROTO_DIR="${1:-}"
if [ -z "$PROTO_DIR" ] || [ ! -d "$PROTO_DIR" ]; then
  echo "Usage: bash tests/sniff-test.sh <prototype-dir>"
  exit 2
fi

REPORT_FILE="$PROTO_DIR/_ai-tells.md"
HIGH=0
MEDIUM=0
FINDINGS=()

check() {
  local severity="$1"
  local pattern="$2"
  local description="$3"
  local matches
  matches=$(grep -rn "$pattern" "$PROTO_DIR" \
    --include="*.html" --include="*.css" --include="*.js" 2>/dev/null \
    | grep -v "_ai-tells.md" || true)
  if [ -n "$matches" ]; then
    FINDINGS+=("[$severity] $description")
    while IFS= read -r line; do
      FINDINGS+=("  $line")
    done < <(echo "$matches" | head -3)
    FINDINGS+=("")
    if [ "$severity" = "HIGH" ]; then HIGH=$((HIGH+1)); else MEDIUM=$((MEDIUM+1)); fi
  fi
}

check "HIGH" "font-family:.*Inter"               "Forbidden typeface: Inter"
check "HIGH" "font-family:.*system-ui"            "Forbidden fallback-as-primary: system-ui"
check "HIGH" "\-apple\-system"                    "Forbidden fallback-as-primary: -apple-system"
check "HIGH" "class=\"[^\"]*slate-[0-9]"          "Forbidden Tailwind color: slate-*"
check "HIGH" "class=\"[^\"]*zinc-[0-9]"           "Forbidden Tailwind color: zinc-*"
check "HIGH" "class=\"[^\"]*indigo-[0-9]"         "Forbidden Tailwind color: indigo-*"
check "HIGH" "class=\"[^\"]*purple-[0-9]"         "Forbidden Tailwind color: purple-*"
check "HIGH" "class=\"[^\"]*violet-[0-9]"         "Forbidden Tailwind color: violet-*"
check "HIGH" "from-purple"                        "Forbidden gradient: purple-*"
check "HIGH" "from-pink"                          "Forbidden gradient: pink-*"
check "HIGH" "rounded-2xl.*shadow-lg\|shadow-lg.*rounded-2xl" "Forbidden card pattern"
check "HIGH" "lucide"                             "Forbidden icon library: Lucide"
check "HIGH" "heroicons"                          "Forbidden icon library: Heroicons"
check "HIGH" "font-awesome"                       "Forbidden icon library: Font Awesome"
check "HIGH" "Transform your"                     "Forbidden copy: 'Transform your...'"
check "HIGH" "Built for "                         "Forbidden copy: 'Built for...'"
check "HIGH" "The future of"                      "Forbidden copy: 'The future of...'"
check "HIGH" "Empower your"                       "Forbidden copy: 'Empower your...'"

HERO_HTML=$(grep -n "hero\|<header" "$PROTO_DIR"/*.html 2>/dev/null || true)
if echo "$HERO_HTML" | grep -q "text-center"; then
  FINDINGS+=("[MEDIUM] Centered hero detected — verify this matches the compositional commandment.")
  FINDINGS+=("")
  MEDIUM=$((MEDIUM+1))
fi

{
  echo "# AI-Tell Sniff Test"
  echo ""
  echo "**Prototype:** \`$PROTO_DIR\`  **Date:** $(date +%Y-%m-%d)"
  echo "**HIGH:** $HIGH  **MEDIUM:** $MEDIUM"
  echo ""
  if [ "${#FINDINGS[@]}" -eq 0 ]; then
    echo "✓ No AI-tell patterns detected."
  else
    echo "## Findings"
    echo ""
    for line in "${FINDINGS[@]}"; do echo "$line"; done
  fi
} > "$REPORT_FILE"

echo "Report → $REPORT_FILE  |  HIGH: $HIGH  MEDIUM: $MEDIUM"
[ "$HIGH" -eq 0 ]
