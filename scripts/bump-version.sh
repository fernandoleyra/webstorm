#!/usr/bin/env bash
# Usage: bash scripts/bump-version.sh [major|minor|patch]
# Default: patch bump

set -euo pipefail

PART="${1:-patch}"
CURRENT=$(grep '"version"' plugin.json | sed 's/.*"\([0-9.]*\)".*/\1/')
IFS='.' read -ra PARTS <<< "$CURRENT"

MAJOR="${PARTS[0]}"
MINOR="${PARTS[1]}"
PATCH="${PARTS[2]}"

case "$PART" in
  major) MAJOR=$((MAJOR+1)); MINOR=0; PATCH=0 ;;
  minor) MINOR=$((MINOR+1)); PATCH=0 ;;
  patch) PATCH=$((PATCH+1)) ;;
  *) echo "Usage: bash scripts/bump-version.sh [major|minor|patch]"; exit 2 ;;
esac

NEW="$MAJOR.$MINOR.$PATCH"

# Update plugin.json
sed -i '' "s/\"version\": \"$CURRENT\"/\"version\": \"$NEW\"/" plugin.json

# Update README badge
sed -i '' "s/version-$CURRENT-/version-$NEW-/g" README.md 2>/dev/null || true

# Update marketplace.json (must stay in sync or /plugin reports "already at latest")
sed -i '' "s/\"version\": \"$CURRENT\"/\"version\": \"$NEW\"/" .claude-plugin/marketplace.json

echo "Bumped: $CURRENT → $NEW"
git add plugin.json README.md .claude-plugin/marketplace.json
git commit -m "chore: bump version to $NEW"
