#!/usr/bin/env node
// Generate sandbox/ece-programs.js from sandbox/programs/manifest.sexp
// Reads the manifest for program names and file references,
// uses JSON.stringify for safe escaping (handles backticks, ${}, etc.)
const fs = require("fs");

const manifest = fs.readFileSync("sandbox/programs/manifest.sexp", "utf-8");
const re = /name\s+"([^"]+)"\s+file\s+"([^"]+)"/g;
const programs = [];
let m;
while ((m = re.exec(manifest)) !== null) {
  const name = m[1];
  const source = fs.readFileSync("sandbox/programs/" + m[2], "utf-8");
  programs.push({ name, source });
}
const entries = programs.map(p =>
  "  { name: " + JSON.stringify(p.name) + ", source: " + JSON.stringify(p.source) + " }"
).join(",\n");
fs.writeFileSync("sandbox/ece-programs.js",
  "// ECE Canned Programs — auto-generated from sandbox/programs/manifest.sexp\n" +
  "const ECE_PROGRAMS = [\n" + entries + "\n];\n");
