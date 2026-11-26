#!/usr/bin/env bash
# Re-captures the gallery screenshots in example/screenshots.
#
# The example tests render the gallery at 1440x1000 and write PNGs to /tmp.
# This script backs up the current screenshots to build/screenshots/before/
# so changes can be compared, runs the tests, and copies the new images in.
#
# Rive artwork needs the native runtime. Without it the tests fall back to
# static drawings and Rive assertions fail, so set it up once beforehand:
#   dart run rive_native:setup --verbose --clean --platform linux
#
# Usage: tool/update_screenshots.sh
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
shots="$root/example/screenshots"
before="$root/build/screenshots/before"

gallery=(light static select combobox navigation dark workspace feedback material)

rm -rf "$before"
mkdir -p "$before"
cp "$shots"/*.png "$before"/

for name in "${gallery[@]}"; do rm -f "/tmp/detent-gallery-$name.png"; done
rm -f /tmp/detent-component-detail.png

status=0
(cd "$root/example" && flutter test test/gallery_test.dart test/component_review_test.dart) || status=$?

copied=0
for name in "${gallery[@]}"; do
  if [[ -f "/tmp/detent-gallery-$name.png" ]]; then
    cp "/tmp/detent-gallery-$name.png" "$shots/$name.png"
    copied=$((copied + 1))
  else
    echo "missing: /tmp/detent-gallery-$name.png" >&2
  fi
done
if [[ -f /tmp/detent-component-detail.png ]]; then
  cp /tmp/detent-component-detail.png "$shots/component-detail.png"
  copied=$((copied + 1))
fi

echo "Updated $copied screenshots in example/screenshots (previous copies in build/screenshots/before)."
if [[ $status -ne 0 ]]; then
  echo "Some tests failed (exit $status); check the images before committing." >&2
fi
exit "$status"
