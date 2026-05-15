#!/bin/bash

# Test script to validate sorting logic for FreeRDP tag comparison
# This reproduces and tests the 'comm' sorting issue

set -e

echo "=== FreeRDP Tag Sorting Test ==="
echo ""

# Create test data with realistic FreeRDP version tags
echo "Creating test tag files..."
cat > /tmp/upstream_tags.txt << 'EOF'
v3.0.0-beta1
v3.0.0
v2.11.2
v2.11.1
v2.11.0
v3.0.0-rc1
v2.11.3
EOF

cat > /tmp/local_tags.txt << 'EOF'
v2.11.0
v2.11.1
v3.0.0-beta1
EOF

echo "Upstream tags (initial):"
cat /tmp/upstream_tags.txt
echo ""
echo "Local tags (initial):"
cat /tmp/local_tags.txt
echo ""

# Test 1: Sort with -V (version sort)
echo "Test 1: Sorting with 'sort -u -V'..."
sort -u -V /tmp/upstream_tags.txt > /tmp/upstream_tags_sorted.txt
sort -u -V /tmp/local_tags.txt > /tmp/local_tags_sorted.txt

echo "Upstream sorted:"
cat /tmp/upstream_tags_sorted.txt
echo ""
echo "Local sorted:"
cat /tmp/local_tags_sorted.txt
echo ""

# Test 2: Use comm to find new tags
echo "Test 2: Running 'comm -23' to find new tags..."
if comm -23 /tmp/upstream_tags_sorted.txt /tmp/local_tags_sorted.txt > /tmp/new_tags.txt 2>&1; then
  echo "✓ comm succeeded"
  echo "New tags:"
  cat /tmp/new_tags.txt
else
  echo "✗ comm failed - files may not be in consistent sorted order"
  exit 1
fi
echo ""

# Test 3: Count new tags
echo "Test 3: Counting new tags..."
NEW_COUNT=$(grep -c . /tmp/new_tags.txt 2>/dev/null || echo 0)
echo "New (unseen) tags: $NEW_COUNT"
echo ""

# Test 4: Decision logic
echo "Test 4: Decision logic..."
if [ "$NEW_COUNT" -gt 0 ]; then
  MODE="new"
  cp /tmp/new_tags.txt /tmp/tags_to_build.txt
  echo "→ Building $NEW_COUNT new tag(s):"
  cat /tmp/tags_to_build.txt
else
  MODE="fallback"
  tail -3 /tmp/upstream_tags_sorted.txt > /tmp/tags_to_build.txt
  echo "→ Fallback: building latest 3 upstream tags:"
  cat /tmp/tags_to_build.txt
fi
echo ""

# Test 5: JSON output
echo "Test 5: Creating JSON output..."
TAGS_JSON=$(grep -v '^$' /tmp/tags_to_build.txt | jq -R . | jq -sc .)
BUILD_COUNT=$(grep -c . /tmp/tags_to_build.txt 2>/dev/null || echo 0)

echo "tags_to_build=$TAGS_JSON"
echo "mode=$MODE"
echo "has_tags=$([ "$BUILD_COUNT" -gt 0 ] && echo true || echo false)"
echo ""

# Test 6: Verify output
echo "Test 6: Verifying outputs..."
if [ -z "$TAGS_JSON" ] || [ "$TAGS_JSON" == "null" ]; then
  echo "✗ FAILED: TAGS_JSON is empty or null"
  exit 1
else
  echo "✓ TAGS_JSON valid: $TAGS_JSON"
fi

echo ""
echo "=== All Tests Passed ==="
