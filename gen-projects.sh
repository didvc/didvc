#!/usr/bin/env bash
set -euo pipefail

# Repo slug, optionally "|description" to override the GitHub one
REPOS=(
  "voca-synth/my-synthv-list"
  "anime-research/manga-vastai|Reproduction: orchestrating educational yonkoma (4-panel manga) production with Stable Diffusion on Vast.ai"
  "didvc/lpchart"
  "didvc/dead-mans-ping"
  "didvc/simple-desktop-replay"
  "didvc/better-super-simple-highlighter"
)

# Repo slug -> screenshot URL (optional)
declare -A IMAGES=(
  ["voca-synth/my-synthv-list"]="https://raw.githubusercontent.com/voca-synth/my-synthv-list/main/docs/screenshots/hero.png"
  ["anime-research/manga-vastai"]="https://raw.githubusercontent.com/anime-research/manga-vastai/main/outputs/runs/m10_gijutsushi/sheets/w39_mizunomichi__lettered__deltas.jpg"
  ["didvc/lpchart"]="https://raw.githubusercontent.com/didvc/lpchart/master/docs/images/browser.png"
  ["didvc/dead-mans-ping"]="https://raw.githubusercontent.com/didvc/dead-mans-ping/main/assets/demo-server.png"
  ["didvc/simple-desktop-replay"]="https://raw.githubusercontent.com/didvc/simple-desktop-replay/main/images/viewer-live.png"
  ["didvc/better-super-simple-highlighter"]="https://raw.githubusercontent.com/didvc/better-super-simple-highlighter/main/resources/screenshots/02-colour-picker.png"
)

OUT="part.html"
README="README.md"
START="<!-- projects:start -->"
END="<!-- projects:end -->"

> "$OUT"

first=1
for entry in "${REPOS[@]}"; do
  repo="${entry%%|*}"
  override=""
  [[ "$entry" == *"|"* ]] && override="${entry#*|}"
  name="${repo#*/}"
  github_url="https://github.com/$repo"

  echo "Fetching $repo..." >&2
  info=$(gh api "repos/$repo" --jq '{description: .description, topics: .topics}')
  description=$(echo "$info" | jq -r '.description')
  [[ -n "$override" ]] && description="$override"
  topics=$(echo "$info" | jq -r '.topics | join(" · ")')

  {
    if [[ -z "$first" ]]; then
      printf '<hr>\n\n'
    fi
    first=""
    printf '[%s](%s)  \n' "$name" "$github_url"
    printf '%s  \n' "$description"
    printf '<sub>%s</sub>\n' "$topics"
    image="${IMAGES[$repo]:-}"
    if [[ -n "$image" ]]; then
      printf '\n<img src="%s" alt="%s" width="480">\n' "$image" "$name"
    fi
    printf '\n'
  } >> "$OUT"
done

echo "Generated $OUT" >&2

python3 - "$README" "$OUT" "$START" "$END" <<'PY'
import sys, re

readme_path, part_path, start, end = sys.argv[1:]

with open(readme_path) as f:
    readme = f.read()
with open(part_path) as f:
    part = f.read()

pattern = re.compile(re.escape(start) + r'.*?' + re.escape(end), re.DOTALL)

if not pattern.search(readme):
    print(f"ERROR: markers not found in {readme_path}", file=sys.stderr)
    sys.exit(1)

replacement = f'{start}\n{part.rstrip()}\n{end}'
updated = pattern.sub(replacement, readme)

with open(readme_path, 'w') as f:
    f.write(updated)

print(f"Updated {readme_path}")
PY
