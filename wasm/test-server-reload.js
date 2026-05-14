#!/usr/bin/env node
// ECE server-mode reload integration test.
// Boots the WASM runtime from an HTTP-served app directory, reloads app.ecec
// with native-zone artifacts, overwrites those served files, and reloads from
// the same URLs again.

const fs = require("fs");
const path = require("path");
const ECE = require("./glue.js");

const [baseUrl, servedDir, nextDir, unitName, firstValueRaw, secondValueRaw] = process.argv.slice(2);
if (!baseUrl || !servedDir || !nextDir || !unitName || !firstValueRaw || !secondValueRaw) {
  console.error("Usage: node test-server-reload.js <base-url> <served-dir> <next-dir> <unit-name> <first> <second>");
  process.exit(1);
}

const firstValue = Number(firstValueRaw);
const secondValue = Number(secondValueRaw);
if (!/^[A-Za-z0-9_+\-*\/<>=!?$%&:.~^]+$/.test(unitName)) {
  console.error(`Unsafe unit name for Scheme symbol interpolation: ${unitName}`);
  process.exit(1);
}

function copyReloadArtifacts(fromDir, toDir) {
  for (const name of ["app.ecec", "app-zones.manifest", "app-zones.wasm"]) {
    fs.copyFileSync(path.join(fromDir, name), path.join(toDir, name));
  }
}

function eceEval(source) {
  return ECE.evalStringLast(source);
}

function executeRegisteredUnit() {
  return eceEval(`
    (let* ((unit (archive/registered-unit '${unitName}))
           (cos (hash-ref unit ':cos #f))
           (co (vector-ref cos 0)))
      (if (native-zone-registered? '${unitName} 0)
          (execute-code-object co)
          (error "native zone was not registered after reload")))`);
}

async function boot() {
  const imports = {
    io: ECE.io,
    loader: ECE.loader,
    storage: ECE.storage,
    canvas: ECE.canvas,
    timing: ECE.timing,
    math: ECE.math,
    ffi: ECE.ffi,
    wasm_host: ECE.wasmHost
  };

  const wasmResp = await fetch(`${baseUrl}/runtime.wasm`);
  const wasmBytes = await wasmResp.arrayBuffer();
  const { instance } = await WebAssembly.instantiate(wasmBytes, imports);
  ECE.wasm = instance.exports;
  ECE.globalEnvHandle = ECE.buildGlobalEnv();

  await ECE.fetchAndLoadArchiveBundle(`${baseUrl}/bootstrap.ecec`, { cache: "no-store" });
  ECE.wasm.mark_handles();
}

async function reloadAndAssert(expected) {
  await ECE.reloadProgramFromUrls(
    `${baseUrl}/app.ecec`,
    `${baseUrl}/app-zones.wasm`,
    `${baseUrl}/app-zones.manifest`);
  const result = ECE._eceToJs(executeRegisteredUnit());
  if (result !== expected) {
    throw new Error(`expected native reload result ${expected}, got ${JSON.stringify(result)}`);
  }
}

async function run() {
  await boot();
  await reloadAndAssert(firstValue);
  copyReloadArtifacts(nextDir, servedDir);
  await reloadAndAssert(secondValue);
  console.log(`PASS: Reloaded ${unitName} native-zone app from ${firstValue} to ${secondValue}`);
}

run().catch(e => {
  console.error("Server reload test error:", e.message);
  process.exit(1);
});
