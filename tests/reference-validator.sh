#!/usr/bin/env bash
# Usage: bash tests/reference-validator.sh "Stripe, https://bloomberg.com, Bauhaus, modern"
# Returns: 0 if all accepted, 1 if any rejected

set -euo pipefail

INPUT="${1:-}"
if [ -z "$INPUT" ]; then
  echo "Usage: bash tests/reference-validator.sh \"ref1, ref2, ...\""
  exit 2
fi

REJECT_LIST=(
  "modern" "clean" "minimal" "minimalist" "sleek" "professional"
  "elegant" "simple" "sophisticated" "premium" "luxury" "fresh"
  "bold" "dynamic" "innovative" "creative" "unique" "stylish"
)

ACCEPTED=0
REJECTED=0

IFS=',' read -ra REFS <<< "$INPUT"
for ref in "${REFS[@]}"; do
  ref=$(echo "$ref" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  [ -z "$ref" ] && continue

  REJECT=false
  REJECT_REASON=""

  ref_lower=$(echo "$ref" | tr '[:upper:]' '[:lower:]')
  for adj in "${REJECT_LIST[@]}"; do
    if [ "$ref_lower" = "$adj" ]; then
      REJECT=true
      REJECT_REASON="Vague adjective. Use a URL, named brand, named designer, typeface, movement, or era."
      break
    fi
  done

  if [ "$REJECT" = "false" ]; then
    word_count=$(echo "$ref" | wc -w | tr -d ' ')
    if [ "$word_count" -eq 1 ] && ! echo "$ref" | grep -qE "^https?://"; then
      char_count=${#ref}
      if [ "$char_count" -lt 7 ] && ! echo "$ref" | grep -qE "[A-Z0-9]"; then
        REJECT=true
        REJECT_REASON="Single short lowercase word '$ref' looks like an adjective. Provide a proper name, URL, movement, or era."
      fi
    fi
  fi

  if [ "$REJECT" = "true" ]; then
    echo "REJECTED: \"$ref\" — $REJECT_REASON"
    REJECTED=$((REJECTED+1))
  else
    echo "ACCEPTED: \"$ref\""
    ACCEPTED=$((ACCEPTED+1))
  fi
done

echo ""
echo "Summary: $ACCEPTED accepted, $REJECTED rejected"
[ "$REJECTED" -eq 0 ]
