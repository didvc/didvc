#!/usr/bin/env node
// Renders assets/splitter-{1,2,3}.png, the same designs as gen-splitters.sh. Requires ImageMagick 6 (`convert`).
import { execFileSync } from "node:child_process";
import { mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const OUT_DIR = join(dirname(fileURLToPath(import.meta.url)), "..", "assets");
const W = 1600;
const H = 192;
const BG = "#0D1117";

// Designs are drawn on a 96px-high grid; Y() stretches them 1.5x and centres them in H
const Y = (y) => Math.trunc((y * 3) / 2) + 24;
const c = (opacity) => `rgba(139,148,158,${opacity})`; // #8B949E at the given opacity
const line = (x1, y1, x2, y2, opacity) => ["-stroke", c(opacity), "-draw", `line ${x1},${Y(y1)} ${x2},${Y(y2)}`];

const convert = (...args) => execFileSync("convert", args, { stdio: "inherit" });

function render(out, fadeLeft, fadeRight, draws) {
  const tmp = mkdtempSync(join(tmpdir(), "splitter-"));
  try {
    const strokes = join(tmp, "strokes.png");
    const mask = join(tmp, "mask.png");
    const alpha = join(tmp, "alpha.png");
    convert("-size", `${W}x${H}`, "xc:none", "-fill", "none", "-strokewidth", "2", ...draws, strokes);
    convert("-size", `${W}x${H}`, "xc:", "-fx", `min(1, min(i/${fadeLeft}, (w-1-i)/${fadeRight}))^1.6`, mask);
    convert(strokes, "-alpha", "extract", mask, "-compose", "Multiply", "-composite", alpha);
    convert(
      "-size", `${W}x${H}`, `xc:${BG}`,
      "(", strokes, alpha, "-alpha", "off", "-compose", "CopyOpacity", "-composite", ")",
      "-compose", "Over", "-composite", "-depth", "8", "-strip", join(OUT_DIR, out),
    );
  } finally {
    rmSync(tmp, { recursive: true, force: true });
  }
}

// 1: three shallow lines crossing right of center
render("splitter-1.png", 420, 180, [
  ...line(60, 70, 1580, 34, 0.55),
  ...line(520, -2, 1560, 82, 0.28),
  ...line(980, 90, 1590, 58, 0.16),
]);

// 2: thin skewed triangle with drafting-style overshooting edges
render("splitter-2.png", 220, 220, [
  ...line(1539, 69, 39, 22, 0.4),
  ...line(299, 6, 519, 90, 0.24),
  ...line(1459, 64, 199, 86, 0.16),
]);

// 3: parallel streaks with staggered starts/ends and irregular spacing
const streaks = [
  [80, 60, 1180, 0.45],
  [360, 44, 1540, 0.22],
  [240, 76, 900, 0.16],
  [620, 30, 1420, 0.3],
  [980, 66, 1580, 0.12],
];
render(
  "splitter-3.png",
  200,
  360,
  streaks.flatMap(([x1, y1, x2, o]) => line(x1, y1, x2, Math.trunc(y1 - (x2 - x1) * 0.018), o)),
);

console.error(`Generated ${OUT_DIR}/splitter-{1,2,3}.png`);
