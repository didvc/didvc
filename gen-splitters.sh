#!/usr/bin/env bash
set -euo pipefail
W=1600 H=192 BG='#0D1117'
# Designs are drawn on a 96px-high grid; Y() stretches them 1.5x and centres them in H
Y() { echo $(( $1 * 3 / 2 + 24 )); }
OUT_DIR="$(dirname "$0")/assets"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
c() { echo "rgba(139,148,158,$1)"; }   # #8B949E at opacity $1

# render <out> <fade-left px> <fade-right px> <draw args...>
render() {
  local out=$1 fl=$2 fr=$3; shift 3
  convert -size ${W}x${H} xc:none -fill none -strokewidth 2 "$@" "$TMP/strokes.png"
  convert -size ${W}x${H} xc: -fx "min(1, min(i/$fl, (w-1-i)/$fr))^1.6" "$TMP/mask.png"
  convert "$TMP/strokes.png" -alpha extract "$TMP/mask.png" -compose Multiply -composite "$TMP/alpha.png"
  convert -size ${W}x${H} xc:"$BG" \
    \( "$TMP/strokes.png" "$TMP/alpha.png" -alpha off -compose CopyOpacity -composite \) \
    -compose Over -composite -depth 8 -strip "$OUT_DIR/$out"
}

# 1: three shallow lines crossing right of center
render splitter-1.png 420 180 \
  -stroke "$(c .55)" -draw "line 60,$(Y 70) 1580,$(Y 34)" \
  -stroke "$(c .28)" -draw "line 520,$(Y -2) 1560,$(Y 82)" \
  -stroke "$(c .16)" -draw "line 980,$(Y 90) 1590,$(Y 58)"

# 2: thin skewed triangle with drafting-style overshooting edges
render splitter-2.png 220 220 \
  -stroke "$(c .40)" -draw "line 1539,$(Y 69) 39,$(Y 22)" \
  -stroke "$(c .24)" -draw "line 299,$(Y 6) 519,$(Y 90)" \
  -stroke "$(c .16)" -draw "line 1459,$(Y 64) 199,$(Y 86)"

# 3: parallel streaks with staggered starts/ends and irregular spacing
d3=()
for spec in "80 60 1180 .45" "360 44 1540 .22" "240 76 900 .16" "620 30 1420 .30" "980 66 1580 .12"; do
  set -- $spec; x1=$1 y1=$2 x2=$3 o=$4
  y2=$(awk -v a=$x1 -v b=$x2 -v y=$y1 'BEGIN{printf "%d", y-(b-a)*0.018}')
  d3+=(-stroke "$(c $o)" -draw "line $x1,$(Y $y1) $x2,$(Y $y2)")
done
render splitter-3.png 200 360 "${d3[@]}"
