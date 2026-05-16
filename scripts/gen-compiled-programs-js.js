#!/usr/bin/env node
// Generate sandbox/ece-compiled.js from manifest entries and compiled .ecec files.
const fs = require("fs");

const manifest = fs.readFileSync("sandbox/programs/manifest.sexp", "utf-8");
const re = /name\s+"([^"]+)"\s+file\s+"([^"]+)"/g;
const entries = [];
let m;
while ((m = re.exec(manifest)) !== null) {
  const name = m[1];
  const archivePath = "sandbox/programs/" + m[2].replace(/\.scm$/, ".ecec");
  const base64 = fs.readFileSync(archivePath).toString("base64");
  entries.push("ECE_COMPILED[" + JSON.stringify(name) + "] = " +
    JSON.stringify(base64) + ";");
}

if (entries.length === 0) {
  throw new Error("sandbox program manifest did not contain any entries");
}

fs.writeFileSync("sandbox/ece-compiled.js",
  "// Pre-compiled ECE programs — auto-generated\n" +
  "const ECE_COMPILED = {};\n" +
  entries.join("\n") + "\n");
