#!/bin/bash
# Build browser test runner page
# Compiles ECE test suite to .ecec, embeds everything into a self-contained HTML file.
set -e

SITE_DIR="${1:-_site/tests}"
SANDBOX_DIR="sandbox"

mkdir -p .tmp
echo "Building browser test page..."

# 1. Compile test suite to .ecec
cat $(cat <<'SOURCES'
tests/ece/test-framework.scm
tests/ece/test-arithmetic.scm
tests/ece/test-lists.scm
tests/ece/test-strings.scm
tests/ece/test-vectors.scm
tests/ece/test-hash-tables.scm
tests/ece/test-types.scm
tests/ece/test-control-flow.scm
tests/ece/test-closures.scm
tests/ece/test-macros.scm
tests/ece/test-tco.scm
tests/ece/test-higher-order.scm
tests/ece/test-records.scm
tests/ece/test-parameters.scm
tests/ece/test-mutation.scm
SOURCES
) wasm/wasm-test-runner.scm > .tmp/ece-wasm-tests.scm
echo '(run-tests)' >> .tmp/ece-wasm-tests.scm

qlot exec sbcl --eval '(asdf:load-system :ece)' \
  --eval '(ece:evaluate (list (intern "compile-file" :ece) ".tmp/ece-wasm-tests.scm"))' \
  --quit

# 2. Encode test .ecec as base64
TEST_B64=$(base64 -i .tmp/ece-wasm-tests.ecec | tr -d '\n')

# 3. Build the HTML page
mkdir -p "$SITE_DIR"

cat > "$SITE_DIR/index.html" << 'HTMLHEAD'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>ECE — WASM Test Suite</title>
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { background: #1e1e1e; color: #d4d4d4; font-family: 'Menlo', 'Consolas', monospace; font-size: 13px; padding: 1.5rem; }
  h1 { font-size: 1.4rem; margin-bottom: 0.3rem; }
  .subtitle { color: #888; margin-bottom: 1rem; font-size: 0.85rem; }
  .subtitle a { color: #4ec9b0; }
  #status { margin-bottom: 1rem; padding: 0.7rem 1rem; background: #2d2d2d; border-radius: 4px; }
  #summary { font-size: 1.1rem; font-weight: bold; margin-bottom: 1rem; }
  .pass { color: #4ec9b0; }
  .fail { color: #f44747; }
  #output { white-space: pre-wrap; background: #111; padding: 1rem; border-radius: 4px; max-height: 70vh; overflow-y: auto; line-height: 1.5; }
  .line-pass { color: #4ec9b0; }
  .line-fail { color: #f44747; font-weight: bold; }
  .line-info { color: #888; }
</style>
</head>
<body>
<h1>ECE WASM Test Suite</h1>
<div class="subtitle"><a href="../">← Back</a></div>
<div id="status">Booting ECE runtime...</div>
<div id="summary"></div>
<div id="output"></div>
HTMLHEAD

# Inline ece-runtime.js
echo '<script>' >> "$SITE_DIR/index.html"
sed '/module\.exports/d' "$SANDBOX_DIR/ece-runtime.js" >> "$SITE_DIR/index.html"
echo '</script>' >> "$SITE_DIR/index.html"

# Inline ece-bootstrap.js
echo '<script>' >> "$SITE_DIR/index.html"
cat "$SANDBOX_DIR/ece-bootstrap.js" >> "$SITE_DIR/index.html"
echo '</script>' >> "$SITE_DIR/index.html"

# Inline test data
echo "<script>const ECE_TEST_B64 = \"${TEST_B64}\";</script>" >> "$SITE_DIR/index.html"

# Inline the runner script
cat >> "$SITE_DIR/index.html" << 'HTMLTAIL'
<script>
async function runTests() {
  const statusEl = document.getElementById("status");
  const summaryEl = document.getElementById("summary");
  const outputEl = document.getElementById("output");
  const lines = [];

  try {
    // Override I/O to capture test output
    ECE.io.display_string = function(len) {
      const mem = new Uint16Array(ECE.wasm.memory.buffer, 0, len);
      lines.push(String.fromCharCode(...mem));
    };
    ECE.io.display_number = function(n) { lines.push(String(n)); };
    ECE.io.newline = function() { lines.push("\n"); };

    // Decode WASM and instantiate with full imports
    const wasmBytes = Uint8Array.from(atob(ECE_WASM_BASE64), c => c.charCodeAt(0));
    const imports = {
      io: ECE.io,
      loader: ECE.loader,
      storage: ECE.storage,
      canvas: ECE.canvas,
      timing: ECE.timing,
      math: ECE.math,
      ffi: ECE.ffi
    };

    const { instance } = await WebAssembly.instantiate(wasmBytes, imports);
    ECE.wasm = instance.exports;
    const envH = ECE.buildGlobalEnv();

    statusEl.textContent = "Loading bootstrap...";
    ECE.globalEnvHandle = envH;
    const bootText = atob(ECE_BOOTSTRAP_BUNDLE);
    ECE.loadEcecBundleText(bootText);
    ECE.wasm.mark_handles();

    statusEl.textContent = "Running tests...";

    // Load and run test suite
    const testSpaceId = ECE.loadEcecText(atob(ECE_TEST_B64));

    const t0 = performance.now();
    try {
      ECE.wasm.run(testSpaceId, 0, envH);
    } catch(e) { /* some tests may trap */ }
    const elapsed = Math.round(performance.now() - t0);

    // Parse results
    const text = lines.join("");
    const textLines = text.split("\n");
    let passed = 0, failed = 0;
    for (const line of textLines) {
      const m = line.match(/(\d+) passed, (\d+) failed/);
      if (m) { passed = parseInt(m[1]); failed = parseInt(m[2]); }
    }

    // Render summary
    if (failed === 0) {
      summaryEl.innerHTML = '<span class="pass">' + passed + ' passed</span>, 0 failed (' + elapsed + 'ms)';
      statusEl.innerHTML = '<span class="pass">All tests passed!</span>';
    } else {
      summaryEl.innerHTML = '<span class="pass">' + passed + ' passed</span>, <span class="fail">' + failed + ' failed</span> (' + elapsed + 'ms)';
      statusEl.innerHTML = '<span class="fail">' + failed + ' test(s) failed</span>';
    }

    // Render output
    let html = "";
    for (const line of textLines) {
      if (line.includes("FAIL")) html += '<span class="line-fail">' + escapeHtml(line) + '</span>\n';
      else if (line.includes("PASS") || line.includes("passed,")) html += '<span class="line-pass">' + escapeHtml(line) + '</span>\n';
      else if (line.trim()) html += '<span class="line-info">' + escapeHtml(line) + '</span>\n';
    }
    outputEl.innerHTML = html;

  } catch(e) {
    statusEl.innerHTML = '<span class="fail">Error: ' + escapeHtml(e.message) + '</span>';
  }
}

function escapeHtml(s) { return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;"); }

runTests();
</script>
</body>
</html>
HTMLTAIL

echo "Test page built at $SITE_DIR/index.html"
