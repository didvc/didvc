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

OUT="part.html"
README="README.md"
START="<!-- projects:start -->"
END="<!-- projects:end -->"

> "$OUT"

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
    printf '[%s](%s)  \n' "$name" "$github_url"
    printf '%s  \n' "$description"
    printf '<sub>%s</sub>\n' "$topics"
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
