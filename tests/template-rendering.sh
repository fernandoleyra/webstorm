#!/usr/bin/env bash
# Usage: bash tests/template-rendering.sh <brief.md> <output-dir>

set -euo pipefail

BRIEF="${1:-}"
OUTPUT_DIR="${2:-}"
TEMPLATES_DIR="$(dirname "$0")/../skills/webstorm/templates"

if [ -z "$BRIEF" ] || [ ! -f "$BRIEF" ]; then
  echo "Usage: bash tests/template-rendering.sh <brief.md> <output-dir>"
  exit 2
fi

mkdir -p "$OUTPUT_DIR"

extract() {
  local key="$1"
  grep "^${key}:" "$BRIEF" 2>/dev/null | head -1 \
    | sed "s/^${key}: *//" | tr -d '"' || echo "MISSING_${key}"
}

render_template() {
  local tmpl="$1"
  local out="$2"
  sed \
    -e "s|{{project_name}}|$(extract project_name)|g" \
    -e "s|{{purpose}}|$(extract purpose)|g" \
    -e "s|{{audience}}|$(extract audience)|g" \
    -e "s|{{success_metric}}|$(extract success_metric)|g" \
    -e "s|{{pages}}|$(extract pages)|g" \
    -e "s|{{features}}|$(extract features)|g" \
    -e "s|{{tech_stack}}|$(extract tech_stack)|g" \
    -e "s|{{tokens_source}}|$(extract tokens_source)|g" \
    -e "s|{{brand_color_primary}}|$(extract brand_color_primary)|g" \
    -e "s|{{brand_color_secondary}}|$(extract brand_color_secondary)|g" \
    -e "s|{{brand_color_accent}}|$(extract brand_color_accent)|g" \
    -e "s|{{brand_color_neutral}}|$(extract brand_color_neutral)|g" \
    -e "s|{{brand_color_bg}}|$(extract brand_color_bg)|g" \
    -e "s|{{brand_color_surface}}|$(extract brand_color_surface)|g" \
    -e "s|{{brand_color_text}}|$(extract brand_color_text)|g" \
    -e "s|{{brand_color_text_muted}}|$(extract brand_color_text_muted)|g" \
    -e "s|{{brand_type_display}}|$(extract brand_type_display)|g" \
    -e "s|{{brand_type_body}}|$(extract brand_type_body)|g" \
    -e "s|{{brand_type_mono}}|$(extract brand_type_mono)|g" \
    -e "s|{{brand_radius_sm}}|$(extract brand_radius_sm)|g" \
    -e "s|{{brand_radius_md}}|$(extract brand_radius_md)|g" \
    -e "s|{{brand_radius_lg}}|$(extract brand_radius_lg)|g" \
    "$tmpl" > "$out"
}

render_template "$TEMPLATES_DIR/scaffold.md.tmpl"      "$OUTPUT_DIR/scaffold.md"
render_template "$TEMPLATES_DIR/workflow.md.tmpl"      "$OUTPUT_DIR/workflow.md"
render_template "$TEMPLATES_DIR/CLAUDE.root.md.tmpl"   "$OUTPUT_DIR/CLAUDE.md"
render_template "$TEMPLATES_DIR/tokens.css.tmpl"       "$OUTPUT_DIR/tokens.css"
cp "$TEMPLATES_DIR/.gitignore.tmpl" "$OUTPUT_DIR/.gitignore"

echo "Rendered to: $OUTPUT_DIR"

# Check for un-substituted placeholders (but skip lines with {{n}} which is prototype-specific)
UNSUBSTITUTED=$(grep -r "{{" "$OUTPUT_DIR" 2>/dev/null | grep -v "{{n}}" || true)
if [ -n "$UNSUBSTITUTED" ]; then
  echo ""
  echo "ERROR: Un-substituted placeholders found:"
  echo "$UNSUBSTITUTED"
  exit 1
fi
echo "✓ No unsubstituted placeholders."

# Compare against golden if it exists
GOLDEN_DIR="$(dirname "$0")/golden"
if [ -d "$GOLDEN_DIR" ]; then
  DIFFS=0
  for f in scaffold.md workflow.md CLAUDE.md tokens.css .gitignore; do
    [ -f "$GOLDEN_DIR/$f" ] || continue
    if ! diff -q "$GOLDEN_DIR/$f" "$OUTPUT_DIR/$f" > /dev/null 2>&1; then
      echo "DIFF: $f"
      diff "$GOLDEN_DIR/$f" "$OUTPUT_DIR/$f" | head -20 || true
      DIFFS=$((DIFFS+1))
    fi
  done
  if [ "$DIFFS" -eq 0 ]; then
    echo "✓ Matches golden output."
  else
    exit 1
  fi
fi
