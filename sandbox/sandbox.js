// ECE Sandbox — UI logic, WASM bridge, REPL, editor
"use strict";

const Sandbox = {
  canvas: null,
  ctx: null,
  consoleEl: null,
  editorEl: null,
  replInputEl: null,
  replOutputEl: null,
  running: false,
  envHandle: null,

  // ── Initialize ──

  async init() {
    Sandbox.canvas = document.getElementById("sandbox-canvas");
    Sandbox.ctx = Sandbox.canvas.getContext("2d");
    Sandbox.consoleEl = document.getElementById("console-output");
    Sandbox.editorEl = document.getElementById("editor-textarea");
    Sandbox.replInputEl = document.getElementById("repl-input");
    Sandbox.replOutputEl = document.getElementById("repl-output");

    Sandbox.setupTabs();
    Sandbox.setupAnchor();
    Sandbox.setupPrograms();
    Sandbox.setupRunStop();
    Sandbox.setupRepl();
    Sandbox.resizeCanvas();
    window.addEventListener("resize", Sandbox.resizeCanvas);

    // Canvas is now handled by browser-lib.scm via FFI

    // Wire display output to console div
    ECE.io.display_string = function(len) {
      const mem = new Uint16Array(ECE.wasm.memory.buffer, 0, len);
      const str = String.fromCharCode(...mem);
      Sandbox.appendConsole(str);
    };
    ECE.io.display_number = function(n) {
      Sandbox.appendConsole(String(n));
    };
    ECE.io.newline = function() {
      Sandbox.appendConsole("\n");
    };

    // Boot ECE
    Sandbox.setStatus("Loading ECE...");
    await Sandbox.bootECE();
    // Load pre-compiled programs
    if (typeof ECE_COMPILED !== "undefined") {
      Sandbox._compiledPrograms = ECE_COMPILED;
    }

    Sandbox.setStatus("Ready");
  },

  async bootECE() {
    // Decode WASM from base64
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

    Sandbox.envHandle = ECE.buildGlobalEnv();

    // Boot bootstrap from base64-encoded .ecec text
    for (const name of ["prelude", "compiler", "reader", "assembler", "compilation-unit", "browser-lib"]) {
      const text = (typeof atob === "function")
        ? atob(ECE_BOOTSTRAP[name])
        : Buffer.from(ECE_BOOTSTRAP[name], "base64").toString("binary");
      const spaceId = ECE.loadEcecText(text);
      ECE.wasm.run(spaceId, 0, Sandbox.envHandle);
    }
    // Mark all bootstrap handles as permanent so reset_handles() doesn't free them
    ECE.wasm.mark_handles();
  },

  // ── Console output ──

  appendConsole(text) {
    Sandbox.consoleEl.textContent += text;
    Sandbox.consoleEl.scrollTop = Sandbox.consoleEl.scrollHeight;
  },

  clearConsole() {
    Sandbox.consoleEl.textContent = "";
  },

  setStatus(msg) {
    document.getElementById("status-bar").textContent = msg;
  },

  // ── Tabs ──

  setupTabs() {
    document.querySelectorAll(".tab-btn").forEach(btn => {
      btn.addEventListener("click", () => {
        document.querySelectorAll(".tab-btn").forEach(b => b.classList.remove("active"));
        document.querySelectorAll(".tab-panel").forEach(p => p.classList.remove("active"));
        btn.classList.add("active");
        document.getElementById(btn.dataset.tab).classList.add("active");
      });
    });
  },

  // ── Anchor toggle ──

  setupAnchor() {
    const positions = ["right", "bottom", "left", "top"];
    let idx = positions.indexOf(localStorage.getItem("ece-anchor") || "right");
    if (idx < 0) idx = 0;
    Sandbox.applyAnchor(positions[idx]);

    document.getElementById("anchor-btn").addEventListener("click", () => {
      idx = (idx + 1) % positions.length;
      localStorage.setItem("ece-anchor", positions[idx]);
      Sandbox.applyAnchor(positions[idx]);
    });
  },

  applyAnchor(pos) {
    const container = document.getElementById("main-container");
    container.className = "main-container anchor-" + pos;
    setTimeout(Sandbox.resizeCanvas, 50);
  },

  // ── Canvas resize ──

  resizeCanvas() {
    if (!Sandbox.canvas) return;
    const rect = Sandbox.canvas.parentElement.getBoundingClientRect();
    Sandbox.canvas.width = rect.width;
    Sandbox.canvas.height = rect.height - 4;
  },

  // ── Programs dropdown ──

  setupPrograms() {
    const select = document.getElementById("program-select");
    ECE_PROGRAMS.forEach((prog, i) => {
      const opt = document.createElement("option");
      opt.value = i;
      opt.textContent = prog.name;
      select.appendChild(opt);
    });
    select.addEventListener("change", () => {
      const prog = ECE_PROGRAMS[select.value];
      if (prog) {
        Sandbox.editorEl.value = prog.source;
        Sandbox._editorOriginal = prog.source;
      }
    });
    // Load first program
    if (ECE_PROGRAMS.length > 0) {
      Sandbox.editorEl.value = ECE_PROGRAMS[0].source;
      Sandbox._editorOriginal = ECE_PROGRAMS[0].source;
    }
  },

  // ── Run / Stop ──

  setupRunStop() {
    document.getElementById("run-btn").addEventListener("click", () => {
      if (Sandbox.running) {
        Sandbox.stop();
      } else {
        Sandbox.run(Sandbox.editorEl.value);
      }
    });
  },

  run(source) {
    Sandbox.clearConsole();
    Sandbox.running = true;
    document.getElementById("run-btn").textContent = "\u25A0 Stop";
    document.getElementById("run-btn").classList.add("stop");

    // Get the selected program name for pre-compiled lookup
    const select = document.getElementById("program-select");
    const progName = select.options[select.selectedIndex]?.textContent || "";

    try {
      Sandbox.evalECE(source, progName);
    } catch(e) {
      Sandbox.appendConsole("\nError: " + e.message + "\n");
    }

    // Check for yield continuation — start animation loop
    if (ECE.wasm.get_yield_flag() || Sandbox.hasYieldCont()) {
      Sandbox.animationLoop();
    } else {
      Sandbox.finishRun();
    }
  },

  stop() {
    Sandbox.running = false;
    ECE.wasm.clear_yield_cont();
    ECE.wasm.set_yield_flag(0);
    document.getElementById("run-btn").textContent = "\u25B6 Run";
    document.getElementById("run-btn").classList.remove("stop");
  },

  finishRun() {
    Sandbox.running = false;
    document.getElementById("run-btn").textContent = "\u25B6 Run";
    document.getElementById("run-btn").classList.remove("stop");
  },

  hasYieldCont() {
    // Check if a yield continuation is stored (non-null, non-nil)
    const h = ECE.wasm.get_yield_cont();
    if (h <= 0) return false;
    const t = ECE.wasm.dbg_type(h);
    return t !== 0 && t !== 10;  // not null, not nil/void/#f
  },

  animationLoop() {
    if (!Sandbox.running) return;
    ECE.wasm.reset_handles();  // recycle temporary handles from last frame
    if (!Sandbox.hasYieldCont()) {
      Sandbox.finishRun();
      return;
    }

    const w = ECE.wasm;
    try {
      // Resume the stored yield continuation with void
      const contHandle = w.get_yield_cont();
      w.clear_yield_cont();
      const args = w.h_cons(ECE._hVoid, w.h_nil());
      w.call_ece_proc(contHandle, args);
    } catch(e) {
      Sandbox.appendConsole("\nError: " + e.message + "\n");
      Sandbox.finishRun();
      return;
    }

    // If the program yielded again, schedule another frame
    if (Sandbox.hasYieldCont()) {
      requestAnimationFrame(Sandbox.animationLoop.bind(Sandbox));
    } else {
      Sandbox.finishRun();
    }
  },

  // ── Eval ──

  evalECE(source, progName) {
    const w = ECE.wasm;
    w.reset_handles();  // recycle temporary handles from previous run
    // Try pre-compiled .ecec first (only if source hasn't been edited)
    const key = progName || "";
    const edited = Sandbox._editorOriginal !== undefined && source !== Sandbox._editorOriginal;
    if (!edited && Sandbox._compiledPrograms && Sandbox._compiledPrograms[key]) {
      const progData = Sandbox._compiledPrograms[key];
      const text = (typeof atob === "function")
        ? atob(progData)
        : Buffer.from(progData, "base64").toString("binary");
      const spaceId = ECE.loadEcecText(text);
      w.run(spaceId, 0, Sandbox.envHandle);
      return;
    }
    // Reset compilation state for fresh run
    w.reset_current_space();

    // Use ECE's own reader and compiler via eval-string
    const evalStrProc = w.env_lookup(Sandbox.envHandle, ECE.internSym("eval-string"));
    w.call_ece_proc(evalStrProc, w.h_cons(ECE.makeString(source), ECE._hNil));
  },

  // ── REPL ──

  setupRepl() {
    Sandbox.replInputEl.addEventListener("keydown", (e) => {
      if (e.key === "Enter" && (e.ctrlKey || e.metaKey)) {
        e.preventDefault();
        Sandbox.evalRepl();
      }
    });
    document.getElementById("repl-eval-btn").addEventListener("click", Sandbox.evalRepl);
  },

  evalRepl() {
    const input = Sandbox.replInputEl.value.trim();
    if (!input) return;

    const w = ECE.wasm;

    // Display input
    const entry = document.createElement("div");
    entry.className = "repl-entry";
    entry.innerHTML = '<div class="repl-input-echo">' + Sandbox.escapeHtml(input) + '</div>';

    // Capture output
    const oldAppend = Sandbox.appendConsole.bind(Sandbox);
    let replOutput = "";
    Sandbox.appendConsole = function(text) {
      replOutput += text;
    };

    try {
      // Use ECE's own reader and compiler via eval-string-last
      const evalStrLastProc = w.env_lookup(Sandbox.envHandle, ECE.internSym("eval-string-last"));
      const lastResult = w.call_ece_proc(evalStrLastProc, w.h_cons(ECE.makeString(input), ECE._hNil));
      // Print the last result using write (Scheme readable form)
      const rc = w.write_val(lastResult);
      if (rc === 0) replOutput += "Error: unbound variable";
      // rc===1 is void (silent), rc===2 means value was printed
    } catch(e) {
      replOutput += "Error: " + e.message;
    }

    Sandbox.appendConsole = oldAppend;

    if (replOutput) {
      entry.innerHTML += '<div class="repl-result">' + Sandbox.escapeHtml(replOutput) + '</div>';
    }

    Sandbox.replOutputEl.appendChild(entry);
    Sandbox.replOutputEl.scrollTop = Sandbox.replOutputEl.scrollHeight;
    Sandbox.replInputEl.value = "";
  },

  escapeHtml(s) {
    return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
  }
};

// Boot on load
window.addEventListener("DOMContentLoaded", () => Sandbox.init());
