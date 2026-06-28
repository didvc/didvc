#!/usr/bin/env bash
set -euo pipefail

# Repo slug | docs URL
REPOS=(
  "didvc/c2pa|https://didvc.github.io/c2pa/"
  "didvc/agent.txtar|https://didvc.github.io/agent.txtar/"
  "didvc/simple-ots|https://didvc.github.io/simple-ots/"
  "didvc/rtx-manual-to-md|https://didvc.github.io/rtx-manual-to-md/"
  "didvc/astro-html-editor|https://didvc.github.io/astro-html-editor/"
  "didvc/http-status-monitor|https://didvc.github.io/http-status-monitor/"
)

OUT="part.html"
README="README.md"
START="<!-- projects:start -->"
END="<!-- projects:end -->"

> "$OUT"

for entry in "${REPOS[@]}"; do
  repo="${entry%%|*}"
  docs_url="${entry##*|}"
  name="${repo#*/}"
  github_url="https://github.com/$repo"

  echo "Fetching $repo..." >&2
  info=$(gh api "repos/$repo" --jq '{description: .description, topics: .topics}')
  description=$(echo "$info" | jq -r '.description')
  topics=$(echo "$info" | jq -r '.topics | join(" · ")')

  {
    printf '**[%s](%s)** · [docs ↗](%s)  \n' "$name" "$github_url" "$docs_url"
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
