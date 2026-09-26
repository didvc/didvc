#!/usr/bin/env node
// Regenerates the projects block in README.md from GitHub repo metadata (via `gh api`).
import { execFileSync } from "node:child_process";
import { readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

// description: overrides the GitHub one; image: screenshot shown under the entry
const REPOS = [
  {
    repo: "voca-synth/my-synthv-list",
    image: "https://raw.githubusercontent.com/voca-synth/my-synthv-list/main/docs/screenshots/hero.png",
  },
  {
    repo: "anime-research/manga-vastai",
    description:
      "Reproduction: orchestrating educational yonkoma (4-panel manga) production with Stable Diffusion on Vast.ai",
    image: "https://raw.githubusercontent.com/anime-research/manga-vastai/main/outputs/runs/m10_gijutsushi/sheets/w39_mizunomichi__lettered__deltas.jpg",
  },
  {
    repo: "didvc/lpchart",
    image: "https://raw.githubusercontent.com/didvc/lpchart/master/docs/images/browser.png",
  },
  {
    repo: "didvc/dead-mans-ping",
    image: "https://raw.githubusercontent.com/didvc/dead-mans-ping/main/assets/demo-server.png",
  },
  {
    repo: "didvc/simple-desktop-replay",
    image: "https://raw.githubusercontent.com/didvc/simple-desktop-replay/main/images/viewer-live.png",
  },
  {
    repo: "didvc/better-super-simple-highlighter",
    image: "https://raw.githubusercontent.com/didvc/better-super-simple-highlighter/main/resources/screenshots/02-colour-picker.png",
  },
];

const DIR = join(dirname(fileURLToPath(import.meta.url)), "..");
const OUT = join(DIR, "part.html");
const README = join(DIR, "README.md");
const START = "<!-- projects:start -->";
const END = "<!-- projects:end -->";

function fetchRepo(repo) {
  console.error(`Fetching ${repo}...`);
  const json = execFileSync("gh", ["api", `repos/${repo}`], { encoding: "utf8", maxBuffer: 16 << 20 });
  return JSON.parse(json);
}

const entries = REPOS.map(({ repo, description, image }) => {
  const info = fetchRepo(repo);
  const name = repo.split("/")[1];
  let entry =
    `[${name}](https://github.com/${repo})  \n` +
    `${description ?? info.description}  \n` +
    `<sub>${info.topics.join(" · ")}</sub>\n`;
  if (image) entry += `\n<img src="${image}" alt="${name}" width="480">\n`;
  return entry + "\n";
});

// Shown at the end of the "More" section
const CLOSING =
  "For all of my projects, if you're interested, they're category-organized at [sorry, still under construction. Maybe in a month or two.]";

// The first project stands alone under the heading; the rest fold into a collapsed "More" section
const part =
  entries[0] +
  "<details>\n<summary><h3>More</h3></summary>\n\n" +
  entries.slice(1).join("<hr>\n\n") +
  "<hr>\n\n" +
  CLOSING +
  "\n\n</details>\n";
writeFileSync(OUT, part);
console.error(`Generated ${OUT}`);

const readme = readFileSync(README, "utf8");
const start = readme.indexOf(START);
const end = readme.indexOf(END, start);
if (start === -1 || end === -1) {
  console.error(`ERROR: markers not found in ${README}`);
  process.exit(1);
}

const updated = readme.slice(0, start) + `${START}\n${part.trimEnd()}\n${END}` + readme.slice(end + END.length);
writeFileSync(README, updated);
console.log(`Updated ${README}`);
