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

    // Wire canvas imports to real canvas
    ECE.canvas = {
      clear() { Sandbox.ctx.clearRect(0, 0, Sandbox.canvas.width, Sandbox.canvas.height); },
      set_fill_color(r, g, b) { Sandbox.ctx.fillStyle = `rgb(${r},${g},${b})`; },
      fill_rect(x, y, w, h) { Sandbox.ctx.fillRect(x, y, w, h); },
      fill_circle(x, y, r) {
        Sandbox.ctx.beginPath();
        Sandbox.ctx.arc(x, y, r, 0, Math.PI * 2);
        Sandbox.ctx.fill();
      },
      draw_text(x, y) {
        // Text was written to linear memory by display_value
        const mem = new Uint16Array(ECE.wasm.memory.buffer, 0, 256);
        let len = 0;
        while (len < 256 && mem[len] !== 0) len++;
        const str = String.fromCharCode(...Array.from({length: len}, (_, i) => mem[i]));
        Sandbox.ctx.fillText(str, x, y);
      },
      width() { return Sandbox.canvas.width; },
      height() { return Sandbox.canvas.height; }
    };

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
      canvas: ECE.canvas
    };

    const { instance } = await WebAssembly.instantiate(wasmBytes, imports);
    ECE.wasm = instance.exports;

    Sandbox.envHandle = ECE.buildGlobalEnv();

    // Boot bootstrap from base64
    for (const name of ["prelude", "compiler", "reader", "assembler", "compilation-unit"]) {
      const bytes = Uint8Array.from(atob(ECE_BOOTSTRAP[name]), c => c.charCodeAt(0));
      const parsed = ECE.parseBinary(bytes);
      ECE.loadParsed(parsed);
      ECE.wasm.run(ECE.wasm.sym_id(ECE.internSym(parsed.spaceName)), 0, Sandbox.envHandle);
    }
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
    if (!Sandbox.hasYieldCont()) {
      Sandbox.finishRun();
      return;
    }

    try {
      // Resume the stored continuation
      const contHandle = ECE.wasm.get_yield_cont();
      ECE.wasm.clear_yield_cont();
      // Invoke continuation by running it — the continuation is an ECE value
      // We need to call it via the executor. Create a tiny space that invokes the continuation.
      // Actually, simpler: use the handle to get the continuation, then call it.
      // For now, just resume by running from the yield point.
      // TODO: proper continuation resume mechanism
    } catch(e) {
      Sandbox.appendConsole("\nError: " + e.message + "\n");
      Sandbox.finishRun();
      return;
    }

    requestAnimationFrame(Sandbox.animationLoop.bind(Sandbox));
  },

  // ── Eval ──

  evalECE(source, progName) {
    const w = ECE.wasm;
    // Try pre-compiled .ececb first (only if source hasn't been edited)
    const key = progName || "";
    const edited = Sandbox._editorOriginal !== undefined && source !== Sandbox._editorOriginal;
    if (!edited && Sandbox._compiledPrograms && Sandbox._compiledPrograms[key]) {
      const progData = Sandbox._compiledPrograms[key];
      const bytes = Uint8Array.from(atob(progData), c => c.charCodeAt(0));
      const parsed = ECE.parseBinary(bytes);
      ECE.loadParsed(parsed);
      w.run(w.sym_id(ECE.internSym(parsed.spaceName)), 0, Sandbox.envHandle);
      return;
    }
    // Runtime compilation: parse source in JS, eval each expression via ECE compiler
    const evalProc = w.env_lookup(Sandbox.envHandle, ECE.internSym("eval"));
    const exprs = Sandbox.parseScheme(source);
    for (const expr of exprs) {
      const eceExpr = Sandbox.buildECEValue(expr);
      w.call_ece_proc(evalProc, w.h_cons(eceExpr, ECE._hNil));
    }
  },

  // Simple S-expression parser (JS side)
  parseScheme(source) {
    let pos = 0;
    const exprs = [];
    while (pos < source.length) {
      skipWS();
      if (pos >= source.length) break;
      exprs.push(readExpr());
    }
    return exprs;

    function skipWS() {
      while (pos < source.length) {
        if (source[pos] === ';') { while (pos < source.length && source[pos] !== '\n') pos++; continue; }
        if (/\s/.test(source[pos])) { pos++; continue; }
        break;
      }
    }
    function readExpr() {
      skipWS();
      if (source[pos] === '(') return readList();
      if (source[pos] === "'") { pos++; return { type: "list", elems: [{ type: "sym", val: "quote" }, readExpr()] }; }
      if (source[pos] === '"') return readString();
      if (source[pos] === '#') return readHash();
      return readAtom();
    }
    function readList() {
      pos++; // skip (
      const elems = [];
      while (pos < source.length) {
        skipWS();
        if (source[pos] === ')') { pos++; return { type: "list", elems }; }
        elems.push(readExpr());
      }
      return { type: "list", elems };
    }
    function readString() {
      pos++; // skip "
      let s = "";
      while (pos < source.length && source[pos] !== '"') {
        if (source[pos] === '\\') { pos++; s += source[pos] === 'n' ? '\n' : source[pos] === 't' ? '\t' : source[pos]; }
        else s += source[pos];
        pos++;
      }
      pos++; // skip closing "
      return { type: "str", val: s };
    }
    function readHash() {
      pos++; // skip #
      if (source[pos] === 't') { pos++; return { type: "bool", val: true }; }
      if (source[pos] === 'f') { pos++; return { type: "bool", val: false }; }
      if (source[pos] === '\\') { pos++; const c = source[pos++]; return { type: "char", val: c.charCodeAt(0) }; }
      return { type: "sym", val: "#" + readAtomStr() };
    }
    function readAtomStr() {
      let s = "";
      while (pos < source.length && !/[\s()";]/.test(source[pos])) s += source[pos++];
      return s;
    }
    function readAtom() {
      const s = readAtomStr();
      const n = Number(s);
      if (!isNaN(n) && s !== "") return { type: "num", val: n };
      return { type: "sym", val: s };
    }
  },

  // Convert parsed JS AST to ECE WASM value (handle)
  buildECEValue(ast) {
    const w = ECE.wasm;
    switch (ast.type) {
      case "num": return Number.isInteger(ast.val) ? w.h_fixnum(ast.val) : w.h_float(ast.val);
      case "sym": return ECE.internSym(ast.val);
      case "str": return ECE.makeString(ast.val);
      case "bool": return ast.val ? ECE._hTrue : ECE._hFalse;
      case "char": return w.h_char(ast.val);
      case "list": {
        let result = ECE._hNil;
        for (let i = ast.elems.length - 1; i >= 0; i--) {
          result = w.h_cons(Sandbox.buildECEValue(ast.elems[i]), result);
        }
        return result;
      }
      default: return ECE._hNil;
    }
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
      // Parse and eval each expression, write the last result
      const evalProc = w.env_lookup(Sandbox.envHandle, ECE.internSym("eval"));
      const exprs = Sandbox.parseScheme(input);
      let lastResult = null;
      for (const expr of exprs) {
        const eceExpr = Sandbox.buildECEValue(expr);
        lastResult = w.call_ece_proc(evalProc, w.h_cons(eceExpr, ECE._hNil));
      }
      // Print the last result using write (Scheme readable form)
      if (lastResult !== null) {
        const rc = w.write_val(lastResult);
        if (rc === 0) replOutput += "Error: unbound variable";
        // rc===1 is void (silent), rc===2 means value was printed
      }
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
