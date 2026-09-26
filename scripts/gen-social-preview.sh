#!/usr/bin/env bash
set -euo pipefail

# GitHub social preview (1280x640): the background image with the tagline set on a
# golden-ratio slope (rise 0.618 per run, ~31.7deg) from bottom-left to top-right.
# The text is composited with Difference so it stays legible over both the dark sky
# and the white moon.

DIR="$(dirname "$0")/.."
SRC="$DIR/assets/image0a_ghbg0.png"
OUT="$DIR/social-preview.png"
FONT=/usr/share/fonts/truetype/ubuntu/UbuntuMono-R.ttf
ANGLE=328.3   # -31.7deg, atan(0.618)

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

convert "$SRC" -resize 1280x -gravity center -crop 1280x640+0+0 +repage "$TMP/base.png"

convert -size 1280x640 xc:none -font "$FONT" -fill white -gravity northwest \
  -pointsize 46 -annotate ${ANGLE}x${ANGLE}+58+440 '{ gen_z, cryptology, arts,' \
  -pointsize 46 -annotate ${ANGLE}x${ANGLE}+92+498 '  linguistics, provenance }' \
  -pointsize 24 -annotate ${ANGLE}x${ANGLE}+150+560 '©2026 Vulpes' \
  "$TMP/text.png"

convert "$TMP/base.png" "$TMP/text.png" -compose Difference -composite -strip "$OUT"

echo "Generated $OUT" >&2
