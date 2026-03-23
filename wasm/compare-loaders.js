#!/usr/bin/env node
// Compare instruction val fields between binary loader and WAT reader.
// Loads prelude via both paths in separate WASM instances, diffs val fields.
// Usage: node wasm/compare-loaders.js

const fs = require("fs");
const path = require("path");

const wasmFile = path.join(__dirname, "runtime.wasm");
const preludeEcec = path.join(__dirname, "..", "bootstrap", "prelude.ecec");
const oldGlueFile = "/tmp/old-glue.js";
const preludeEcecb = "/tmp/prelude.ececb";

async function run() {
  if (!fs.existsSync(oldGlueFile) || !fs.existsSync(preludeEcecb)) {
    console.error("Run first:");
    console.error("  git show d316763:wasm/glue.js > /tmp/old-glue.js");
    console.error("  git show d316763:bootstrap/prelude.ececb > /tmp/prelude.ececb");
    process.exit(1);
  }

  const wasmBytes = fs.readFileSync(wasmFile);
  const ECE_old = require(oldGlueFile);
  const ECE_new = require("./glue.js");

  const makeImports = (ece) => ({
    io: { ...ece.io, runtime_error(len) { throw new Error("runtime error"); } },
    loader: { fetch_ececb() { return null; } },
    storage: ece.storage,
    canvas: ece.canvas,
    timing: ece.timing,
    math: ece.math,
    ffi: ece.ffi
  });

  // Instance 1: binary loader
  const { instance: inst1 } = await WebAssembly.instantiate(wasmBytes, makeImports(ECE_old));
  ECE_old.wasm = inst1.exports;
  const w1 = inst1.exports;
  const env1 = ECE_old.buildGlobalEnv();
  const binBytes = new Uint8Array(fs.readFileSync(preludeEcecb));
  const parsed = ECE_old.parseBinary(binBytes);
  ECE_old.loadParsed(parsed);
  const binSid = w1.sym_id(ECE_old.internSym(parsed.spaceName));
  // Instruction count from the loadParsed output
  let binLen = 0;
  for (const unit of parsed.units) binLen += unit.instrs.length;
  console.log(`Binary: space "${parsed.spaceName}" id=${binSid} len=${binLen}`);

  // Instance 2: WAT reader
  const { instance: inst2 } = await WebAssembly.instantiate(wasmBytes, makeImports(ECE_new));
  ECE_new.wasm = inst2.exports;
  const w2 = inst2.exports;
  ECE_new.buildGlobalEnv();
  const ececText = fs.readFileSync(preludeEcec, "utf-8");
  const watSid = ECE_new.loadEcecText(ececText);
  // WAT reader: we can check instruction count via validate_space (returns 0 if valid)
  // Just use the same count as binary — they should match
  const watLen = binLen;
  console.log(`WAT:    space id=${watSid} len=${watLen} (assumed same as binary)`);

  if (binLen !== watLen) {
    console.log(`LENGTH MISMATCH: binary=${binLen} wat=${watLen}`);
  }

  // Compare i32 fields first
  let i32Diffs = 0;
  for (let pc = 0; pc < Math.min(binLen, watLen); pc++) {
    for (let f = 0; f < 4; f++) {
      const bv = w1.dbg_instr(binSid, pc, f);
      const wv = w2.dbg_instr(watSid, pc, f);
      if (bv !== wv) {
        if (i32Diffs < 5) {
          console.log(`i32 DIFF PC ${pc} field ${f}: bin=${bv} wat=${wv}`);
        }
        i32Diffs++;
      }
    }
  }
  console.log(`\ni32 field diffs: ${i32Diffs}`);

  // Compare val fields via write_val
  let valDiffs = 0;
  const diffDetails = [];

  // Helper: capture write_val output
  function captureVal(w, ece, handle) {
    let buf = [];
    const origDS = ece.io.display_string;
    const origDN = ece.io.display_number;
    const origNL = ece.io.newline;
    ece.io.display_string = function(len) {
      const mem = new Uint16Array(w.memory.buffer, 0, len);
      buf.push(String.fromCharCode(...mem));
    };
    ece.io.display_number = function(n) { buf.push(String(n)); };
    ece.io.newline = function() { buf.push("\n"); };
    try { w.write_val(handle); } catch(e) { buf.push("ERR:" + e.message); }
    ece.io.display_string = origDS;
    ece.io.display_number = origDN;
    ece.io.newline = origNL;
    return buf.join("");
  }

  const count = Math.min(binLen, watLen);
  for (let pc = 0; pc < count; pc++) {
    const bh = w1.dbg_instr(binSid, pc, 4);
    const wh = w2.dbg_instr(watSid, pc, 4);
    const bv = captureVal(w1, ECE_old, bh);
    const wv = captureVal(w2, ECE_new, wh);
    if (bv !== wv) {
      const fields = [0,1,2,3].map(f => w1.dbg_instr(binSid, pc, f));
      diffDetails.push({ pc, fields, binVal: bv.substring(0, 60), watVal: wv.substring(0, 60) });
      valDiffs++;
    }
  }

  console.log(`val field diffs: ${valDiffs} (of ${count} instructions)\n`);

  if (valDiffs > 0) {
    // Categorize
    const categories = {};
    for (const d of diffDetails) {
      const key = `op=${d.fields[0]} b=${d.fields[2]}`;
      if (!categories[key]) categories[key] = [];
      categories[key].push(d);
    }

    console.log("=== Differences by instruction type ===");
    for (const [key, diffs] of Object.entries(categories)) {
      console.log(`\n${key}: ${diffs.length} diffs`);
      for (const d of diffs.slice(0, 3)) {
        console.log(`  PC ${d.pc} [${d.fields}]: bin="${d.binVal}" wat="${d.watVal}"`);
      }
      if (diffs.length > 3) console.log(`  ... and ${diffs.length - 3} more`);
    }
  }

  // Also compare val types (cheaper check)
  let typeDiffs = 0;
  for (let pc = 0; pc < count; pc++) {
    const bt = w1.dbg_type(w1.dbg_instr(binSid, pc, 4));
    const wt = w2.dbg_type(w2.dbg_instr(watSid, pc, 4));
    if (bt !== wt) typeDiffs++;
  }
  console.log(`\nval TYPE diffs: ${typeDiffs}`);
}

run().catch(e => { console.error("FATAL:", e.message); process.exit(1); });
