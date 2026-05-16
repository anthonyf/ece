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
  ready: false,
  devServerSocket: null,

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
    Sandbox.setupDevServer();
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
      ffi: ECE.ffi,
      wasm_host: ECE.wasmHost
    };

    const { instance } = await WebAssembly.instantiate(wasmBytes, imports);
    ECE.wasm = instance.exports;

    Sandbox.envHandle = ECE.buildGlobalEnv();

    // Boot bootstrap from a multi-archive bundle
    ECE.globalEnvHandle = Sandbox.envHandle;
    ECE.loadArchiveBundleBase64(ECE_BOOTSTRAP_BUNDLE);
    ECE.wasm.mark_handles();
    Sandbox.ready = true;
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
    if (!Sandbox.ready || !ECE.wasm) {
      Sandbox.appendConsole("\nError: ECE runtime is still loading\n");
      return;
    }

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
    ECE.wasm.clear_yield_cont();
    ECE.wasm.set_yield_flag(0);
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
    ECE._refreshSingletonHandles();
    ECE._symCache = {};  // clear stale symbol handle cache
    if (!Sandbox.hasYieldCont()) {
      Sandbox.finishRun();
      return;
    }

    const w = ECE.wasm;
    try {
      // Resume the stored yield continuation with void
      const contHandle = w.get_yield_cont();
      w.clear_yield_cont();
      if (w.dbg_type(contHandle) === 7)
        w.call_continuation(contHandle, w.h_void());
      else
        w.call_ece_proc(contHandle, w.h_cons(ECE._hVoid, w.h_nil()));
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
    ECE._refreshSingletonHandles();
    ECE._symCache = {};  // clear stale symbol handle cache
    const filename = Sandbox.sourceFilename(progName);
    ECE._storeSet(filename, source);
    const compileProc = w.env_lookup(Sandbox.envHandle, ECE.internSym("eval-string-last"));
    const compileSource = "(car (compile-file->archive-result " +
      ECE._schemeStringLiteral(filename) + "))";
    const co = w.call_ece_proc(compileProc, w.h_cons(ECE.makeString(compileSource), ECE._hNil));
    ECE.runCodeObject(co);
  },

  sourceFilename(progName) {
    const stem = String(progName || "editor")
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, "-")
      .replace(/^-+|-+$/g, "") || "editor";
    return "__sandbox_run__/" + stem + ".scm";
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

  // ── Dev server WebSocket ──

  setupDevServer() {
    if (!window.ECE_DEV_WS_URL) return;
    Sandbox.connectDevServer(window.ECE_DEV_WS_URL);
  },

  connectDevServer(url) {
    if (typeof WebSocket === "undefined") {
      Sandbox.appendReplSystem(";; dev server unavailable: WebSocket is not supported");
      return;
    }
    const socket = new WebSocket(url);
    Sandbox.devServerSocket = socket;
    socket.addEventListener("open", () => {
      Sandbox.appendReplSystem(";; dev server connected");
    });
    socket.addEventListener("message", (event) => {
      Promise.resolve(Sandbox.handleDevServerMessage(String(event.data || "")))
        .catch(e => {
          Sandbox.appendReplSystem("Error: " + Sandbox.errorMessage(e));
        });
    });
    socket.addEventListener("error", () => {
      Sandbox.appendReplSystem(";; dev server WebSocket error");
    });
    socket.addEventListener("close", () => {
      if (Sandbox.devServerSocket === socket) Sandbox.devServerSocket = null;
      Sandbox.appendReplSystem(";; dev server disconnected");
    });
  },

  errorMessage(error) {
    return String(error && error.message ? error.message : error);
  },

  async handleDevServerMessage(raw) {
    let msg;
    try {
      msg = JSON.parse(raw);
    } catch(e) {
      Sandbox.appendReplSystem(";; dev server sent malformed JSON");
      return;
    }
    if (!msg) return;
    if (msg.type === "source-update" || msg.type === "eval-source") {
      Sandbox.applyDevServerSourceUpdate(
        String(msg.path || ""),
        String(msg.source || ""),
        msg.id ? String(msg.id) : null);
      return;
    }
    if (msg.type === "program-reload") {
      await Sandbox.applyDevServerProgramReload(
        String(msg.archiveUrl || ""),
        msg.zoneModuleUrl ? String(msg.zoneModuleUrl) : null,
        msg.manifestUrl ? String(msg.manifestUrl) : null);
    }
  },

  async applyDevServerProgramReload(archiveUrl, zoneModuleUrl, manifestUrl) {
    if (!Sandbox.ready || !ECE.wasm) {
      Sandbox.appendReplSystem("Error: ECE runtime is still loading");
      return;
    }
    if (!archiveUrl) {
      Sandbox.appendReplSystem("Error: program reload missing archive URL");
      return;
    }
    if (typeof ECE.reloadProgramFromUrls !== "function") {
      Sandbox.appendReplSystem(";; dev server unavailable: reloadProgramFromUrls is missing; rebuild sandbox assets");
      return;
    }
    const wasRunning = Sandbox.running;
    try {
      await ECE.reloadProgramFromUrls(archiveUrl, zoneModuleUrl, manifestUrl);
      Sandbox.appendReplSystem(";; program reloaded: " + archiveUrl);
      if (!wasRunning && (ECE.wasm.get_yield_flag() || Sandbox.hasYieldCont())) {
        Sandbox.running = true;
        document.getElementById("run-btn").textContent = "\u25A0 Stop";
        document.getElementById("run-btn").classList.add("stop");
        Sandbox.animationLoop();
      }
    } catch(e) {
      Sandbox.appendReplSystem("Error: " + Sandbox.errorMessage(e));
    }
  },

  sendDevServerResult(message) {
    const socket = Sandbox.devServerSocket;
    if (!socket || socket.readyState !== WebSocket.OPEN) return;
    socket.send(JSON.stringify(message));
  },

  applyDevServerSourceUpdate(path, source, requestId) {
    if (!Sandbox.ready || !ECE.wasm) {
      Sandbox.appendReplSystem("Error: ECE runtime is still loading");
      if (requestId) {
        Sandbox.sendDevServerResult({
          type: "eval-error",
          id: requestId,
          ok: false,
          path,
          error: "ECE runtime is still loading"
        });
      }
      return;
    }
    const w = ECE.wasm;
    const wasRunning = Sandbox.running;
    try {
      w.reset_handles();
      ECE._refreshSingletonHandles();
      ECE._symCache = {};
      const proc = w.env_lookup(Sandbox.envHandle, ECE.internSym("browser-dev-client-handle-source-update"));
      if (!proc) {
        Sandbox.appendReplSystem(";; dev server unavailable: browser dev-client helper is missing; rebuild sandbox assets");
        if (Sandbox.devServerSocket) {
          const socket = Sandbox.devServerSocket;
          Sandbox.devServerSocket = null;
          socket.close();
        }
        return;
      }
      const result = w.call_ece_proc(
        proc,
        w.h_cons(ECE.makeString(path),
                 w.h_cons(ECE.makeString(source), ECE._hNil)));
      const text = ECE._eceToJs(result);
      if (text) Sandbox.appendReplSystem(text);
      if (requestId) {
        Sandbox.sendDevServerResult({
          type: "eval-result",
          id: requestId,
          ok: true,
          path,
          result: text || ""
        });
      }
      if (!wasRunning && (ECE.wasm.get_yield_flag() || Sandbox.hasYieldCont())) {
        Sandbox.running = true;
        document.getElementById("run-btn").textContent = "\u25A0 Stop";
        document.getElementById("run-btn").classList.add("stop");
        Sandbox.animationLoop();
      }
    } catch(e) {
      const message = Sandbox.errorMessage(e);
      Sandbox.appendReplSystem("Error: " + message);
      if (requestId) {
        Sandbox.sendDevServerResult({
          type: "eval-error",
          id: requestId,
          ok: false,
          path,
          error: message
        });
      }
    }
  },

  appendReplSystem(text) {
    const entry = document.createElement("div");
    entry.className = "repl-entry";
    entry.innerHTML = '<div class="repl-result">' + Sandbox.escapeHtml(text) + '</div>';
    Sandbox.replOutputEl.appendChild(entry);
    Sandbox.replOutputEl.scrollTop = Sandbox.replOutputEl.scrollHeight;
  },

  evalRepl() {
    const input = Sandbox.replInputEl.value.trim();
    if (!input) return;
    if (!Sandbox.ready || !ECE.wasm) {
      const entry = document.createElement("div");
      entry.className = "repl-entry";
      entry.innerHTML = '<div class="repl-input-echo">' + Sandbox.escapeHtml(input) + '</div>' +
        '<div class="repl-result">Error: ECE runtime is still loading</div>';
      Sandbox.replOutputEl.appendChild(entry);
      Sandbox.replOutputEl.scrollTop = Sandbox.replOutputEl.scrollHeight;
      return;
    }

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

    // Only fresh yield state (not an existing animation's stored continuation)
    // should count as "this eval yielded" — so gate on !wasRunning below.
    const wasRunning = Sandbox.running;
    let yieldPending = false;
    try {
      // Use ECE's own reader and compiler via eval-string-last
      const evalStrLastProc = w.env_lookup(Sandbox.envHandle, ECE.internSym("eval-string-last"));
      const lastResult = w.call_ece_proc(evalStrLastProc, w.h_cons(ECE.makeString(input), ECE._hNil));
      // Print the last result using write (Scheme readable form)
      const rc = w.write_val(lastResult);
      if (rc === 0) replOutput += "Error: unbound variable";
      // rc===1 is void (silent), rc===2 means value was printed
      yieldPending = !wasRunning && (ECE.wasm.get_yield_flag() || Sandbox.hasYieldCont());
      if (yieldPending) {
        replOutput += (replOutput ? "\n" : "") + ";; yielded — animation resumed";
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

    if (yieldPending) {
      Sandbox.running = true;
      document.getElementById("run-btn").textContent = "\u25A0 Stop";
      document.getElementById("run-btn").classList.add("stop");
      Sandbox.animationLoop();
    }
  },

  escapeHtml(s) {
    return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
  }
};

// Boot on load
window.addEventListener("DOMContentLoaded", () => Sandbox.init());
