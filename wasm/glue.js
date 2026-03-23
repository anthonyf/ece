// ECE WebAssembly Runtime — JS Glue Layer
// ========================================
// Parses .ececb binary format and calls WASM builder functions.
// Provides I/O imports. Minimal JS — all logic is in WASM.

const ECE = {
  outputElement: null,
  wasm: null,  // WASM instance exports

  // ── I/O imports provided to WASM ──

  io: {
    display_string(len) {
      // Read UTF-16 chars from WASM linear memory
      const mem = new Uint16Array(ECE.wasm.memory.buffer, 0, len);
      const str = String.fromCharCode(...mem);
      if (ECE.outputElement) {
        ECE.outputElement.textContent += str;
      } else if (typeof process !== "undefined") {
        process.stdout.write(str);
      }
    },

    display_number(n) {
      const text = Number.isInteger(n) ? String(n) : String(n);
      if (ECE.outputElement) {
        ECE.outputElement.textContent += text;
      } else {
        process.stdout.write(text);
      }
    },

    newline() {
      if (ECE.outputElement) {
        ECE.outputElement.textContent += "\n";
      } else {
        process.stdout.write("\n");
      }
    },

    trace_pc(pc, handle) {
      // Debug trace — no-op in production
    },

    runtime_error(len) {
      const mem = new Uint16Array(ECE.wasm.memory.buffer, 0, len);
      const msg = String.fromCharCode(...mem);
      throw new Error(msg);
    }
  },

  loader: {
    fetch_ececb() { return null; }  // placeholder
  },

  // Canvas stubs (overridden by sandbox.js when canvas is available)
  canvas: {
    clear() {},
    set_fill_color(r, g, b) {},
    fill_rect(x, y, w, h) {},
    fill_circle(x, y, r) {},
    draw_text(x, y) {},
    width() { return 0; },
    height() { return 0; }
  },

  // Math (trig functions)
  math: {
    sin: Math.sin,
    cos: Math.cos
  },

  // Timing (performance.now for FPS etc.)
  timing: {
    performance_now() {
      return (typeof performance !== "undefined") ? Math.floor(performance.now()) : Date.now();
    },
    wall_clock_ms() {
      const d = new Date();
      return ((d.getHours() * 60 + d.getMinutes()) * 60 + d.getSeconds()) * 1000 + d.getMilliseconds();
    }
  },

  // localStorage-backed file storage (browser) / Map fallback (Node.js)
  _fileStore: new Map(),  // localStorage on browser, Map on Node.js
  _hasLocalStorage: (typeof localStorage !== "undefined" && typeof localStorage.setItem === "function"),
  _storeGet(key) {
    if (ECE._hasLocalStorage) return localStorage.getItem(key) || "";
    return ECE._fileStore.get(key) || "";
  },
  _storeSet(key, val) {
    if (ECE._hasLocalStorage) localStorage.setItem(key, val);
    else ECE._fileStore.set(key, val);
  },
  storage: {
    read(fname_len) {
      const mem = new Uint16Array(ECE.wasm.memory.buffer);
      const fname = String.fromCharCode(...Array.from({length: fname_len}, (_, i) => mem[i]));
      const content = ECE._storeGet(fname);
      const offset = fname_len;
      for (let i = 0; i < content.length; i++) {
        mem[offset + i] = content.charCodeAt(i);
      }
      return content.length;
    },
    write(fname_len, content_offset_bytes, content_len) {
      const mem = new Uint16Array(ECE.wasm.memory.buffer);
      const fname = String.fromCharCode(...Array.from({length: fname_len}, (_, i) => mem[i]));
      const content_offset = content_offset_bytes / 2;
      const content = String.fromCharCode(...Array.from({length: content_len}, (_, i) => mem[content_offset + i]));
      ECE._storeSet(fname, content);
    }
  },

  // ── JavaScript FFI bridge ──
  // JS handle table: maps i32 indices to JS values.
  // Index 0 is reserved (null/undefined).

  _jsHandles: [null],  // slot 0 = null
  _jsFreeList: [],     // recycled indices

  _jsAlloc(val) {
    if (ECE._jsFreeList.length > 0) {
      const idx = ECE._jsFreeList.pop();
      ECE._jsHandles[idx] = val;
      return idx;
    }
    const idx = ECE._jsHandles.length;
    ECE._jsHandles.push(val);
    return idx;
  },

  _jsGet(idx) {
    return ECE._jsHandles[idx];
  },

  _jsFree(idx) {
    if (idx > 0) {
      ECE._jsHandles[idx] = null;
      ECE._jsFreeList.push(idx);
    }
  },

  // Read a UTF-16 string from WASM linear memory
  _readMem(ptr, len) {
    const mem = new Uint16Array(ECE.wasm.memory.buffer, ptr, len);
    return String.fromCharCode(...mem);
  },

  // Convert an ECE value handle to a JS value (for FFI arg marshalling)
  _eceToJs(handle) {
    const w = ECE.wasm;
    const t = w.dbg_type(handle);
    switch (t) {
      case 12: return ECE._jsGet(w.js_ref_idx(handle));  // js-ref → unwrap
      case 1:  return w.fixnum_val(handle);               // fixnum → number
      case 5:  return w.float_val(handle);                // float → number
      case 4:  {                                          // string → JS string
        const len = w.string_len(handle);
        w.string_to_mem(handle);
        return ECE._readMem(0, len);
      }
      case 0:  return null;                               // null/nil → null
      default: {
        // Check for booleans (i31 special tags)
        if (t === 10) {
          // other-i31: could be #t, #f, void, nil, eof
          // Use handle comparison
          if (handle === ECE._hTrue) return true;
          if (handle === ECE._hFalse) return false;
          return null;
        }
        return null;
      }
    }
  },

  // Walk an ECE list handle and convert each element to JS
  _eceListToJsArray(listHandle) {
    const w = ECE.wasm;
    const result = [];
    let cur = listHandle;
    while (w.dbg_type(cur) === 2) {  // 2 = pair
      const carH = w.pair_car(cur);
      result.push(ECE._eceToJs(carH));
      cur = w.pair_cdr(cur);
    }
    return result;
  },

  ffi: {
    eval(ptr, len) {
      const code = ECE._readMem(ptr, len);
      const result = (0, eval)(code);  // indirect eval = global scope
      return ECE._jsAlloc(result);
    },

    get(objIdx, propPtr, propLen) {
      const obj = ECE._jsGet(objIdx);
      const prop = ECE._readMem(propPtr, propLen);
      return ECE._jsAlloc(obj[prop]);
    },

    set(objIdx, propPtr, propLen, valHandle) {
      const obj = ECE._jsGet(objIdx);
      const prop = ECE._readMem(propPtr, propLen);
      obj[prop] = ECE._eceToJs(valHandle);
    },

    call(objIdx, methodPtr, methodLen, argsListHandle) {
      const obj = ECE._jsGet(objIdx);
      const method = ECE._readMem(methodPtr, methodLen);
      const args = ECE._eceListToJsArray(argsListHandle);
      const result = obj[method](...args);
      return ECE._jsAlloc(result);
    },

    callback(procHandle) {
      const w = ECE.wasm;
      // Create a JS function that calls the ECE procedure
      const fn = function(...jsArgs) {
        // Convert JS args to js-refs and build ECE list
        let argList = ECE._hNil;
        for (let i = jsArgs.length - 1; i >= 0; i--) {
          const jsRef = w.make_js_ref(ECE._jsAlloc(jsArgs[i]));
          argList = w.h_cons(jsRef, argList);
        }
        return w.call_ece_proc(procHandle, argList);
      };
      return ECE._jsAlloc(fn);
    },

    // Type conversion helpers
    to_number(idx) {
      return Number(ECE._jsGet(idx));
    },

    to_string(idx) {
      const s = String(ECE._jsGet(idx));
      const mem = new Uint16Array(ECE.wasm.memory.buffer);
      for (let i = 0; i < s.length; i++) mem[i] = s.charCodeAt(i);
      return s.length;
    },

    from_number(val) {
      return ECE._jsAlloc(val);
    },

    from_string(ptr, len) {
      return ECE._jsAlloc(ECE._readMem(ptr, len));
    },

    release(idx) {
      ECE._jsFree(idx);
    },

    is_null(idx) {
      const v = ECE._jsGet(idx);
      return (v === null || v === undefined) ? 1 : 0;
    }
  },

  // ── Handle-based WASM interop ──
  // WASM stores GC refs in a handle table, JS gets i32 indices.

  // Write a JS string to WASM linear memory as UTF-16, return {offset, len}
  writeString(jsStr) {
    const mem = new Uint16Array(ECE.wasm.memory.buffer);
    for (let i = 0; i < jsStr.length; i++) {
      mem[i] = jsStr.charCodeAt(i);
    }
    return { offset: 0, len: jsStr.length };
  },

  // Intern a symbol (returns handle i32)
  internSym(name) {
    if (ECE._symCache[name] !== undefined) return ECE._symCache[name];
    const { offset, len } = ECE.writeString(name);
    const h = ECE.wasm.intern_sym(offset, len);
    ECE._symCache[name] = h;
    return h;
  },
  _symCache: {},

  // Create a WASM string (returns handle i32)
  makeString(jsStr) {
    const { offset, len } = ECE.writeString(jsStr);
    return ECE.wasm.make_string(offset, len);
  },

  // Load .ecec text via WAT-native reader
  loadEcecText(text) {
    const w = ECE.wasm;
    // Ensure linear memory is large enough for UTF-16 text
    const needed = text.length * 2;
    const currentBytes = w.memory.buffer.byteLength;
    if (needed > currentBytes) {
      const pages = Math.ceil((needed - currentBytes) / 65536);
      w.memory.grow(pages);
    }
    const mem = new Uint16Array(w.memory.buffer);
    for (let i = 0; i < text.length; i++) {
      mem[i] = text.charCodeAt(i);
    }
    return w.load_ecec(0, text.length);
  },

  // ── Bootstrap and run ──

  async init(wasmUrl, outputElementId) {
    if (typeof document !== "undefined") {
      ECE.outputElement = document.getElementById(outputElementId);
    }

    const response = await fetch(wasmUrl);
    const wasmBytes = await response.arrayBuffer();

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

    return instance;
  },

  // Build global environment with all primitives
  buildGlobalEnv() {
    const w = ECE.wasm;
    const envHandle = w.build_global_env(0);

    // Register ALL primitives from primitives.def
    // Core (0-99) + CL-compat stubs
    // Generated from primitives.def — do not edit by hand.
    // Regenerate with: bash scripts/gen-primitives-json.sh
    const prims = require("./primitives.json");

    for (const [id, name] of prims) {
      const nameSym = ECE.internSym(name);
      const primHandle = w.h_primitive(id);
      w.env_define(envHandle, nameSym, primHandle);
    }

    // Allocate singleton handles that we'll cache for instruction building
    ECE._hNil   = w.h_nil();
    ECE._hTrue  = w.h_true();
    ECE._hFalse = w.h_false();
    ECE._hEof   = w.h_eof();
    ECE._hVoid  = w.h_void();

    // Also define #t, #f, nil as variables
    w.env_define(envHandle, ECE.internSym("#t"), ECE._hTrue);
    w.env_define(envHandle, ECE.internSym("#f"), ECE._hFalse);

    // Mark permanent handles (env, symbols, primitives, singletons)
    w.mark_handles();

    // Initialize assembler symbol table for runtime compilation
    ECE.initAssemblerSymbols();

    // Store global env for execute-from-pc
    w.set_global_env(envHandle);

    // Create default compilation space for REPL/eval
    const replSym = ECE.internSym("repl");
    w.create_space(replSym, 524288);
    w.set_current_space(w.sym_id(replSym));

    return envHandle;
  },

  // Initialize assembler symbol ID table for runtime instruction conversion
  initAssemblerSymbols() {
    const w = ECE.wasm;
    const names = [
      // 0-6: instruction types
      'assign', 'test', 'branch', 'goto', 'save', 'restore', 'perform',
      // 7-12: register names
      'val', 'env', 'proc', 'argl', 'continue', 'stack',
      // 13-16: source/dest types
      'const', 'reg', 'label', 'op',
      // 17-37: operation names (op-id = slot - 17)
      'lookup-variable-value',       // 17 → op 0
      'compiled-procedure-entry',    // 18 → op 1
      'compiled-procedure-env',      // 19 → op 2
      'make-compiled-procedure',     // 20 → op 3
      'extend-environment',          // 21 → op 4
      'primitive-procedure?',        // 22 → op 5
      'apply-primitive-procedure',   // 23 → op 6
      'continuation?',               // 24 → op 7
      'continuation-stack',          // 25 → op 8
      'continuation-conts',          // 26 → op 9
      'parameter?',                  // 27 → op 10
      'apply-parameter',             // 28 → op 11
      'false?',                      // 29 → op 12
      'list',                        // 30 → op 13
      'cons',                        // 31 → op 14
      'car',                         // 32 → op 15
      'cdr',                         // 33 → op 16
      'lexical-ref',                 // 34 → op 17
      'lexical-set!',                // 35 → op 18
      'define-variable!',            // 36 → op 19
      'set-variable-value!',         // 37 → op 20
      'capture-continuation',        // 38 → op 21
    ];
    w.init_asm_syms(names.length);
    for (let i = 0; i < names.length; i++) {
      w.store_asm_sym(i, ECE.internSym(names[i]));
    }
  },

  async bootstrap(baseUrl) {
    const files = [
      "prelude.ececb",
      "compiler.ececb",
      "reader.ececb",
      "assembler.ececb",
      "compilation-unit.ececb"
    ];

    // Build global environment first
    ECE.globalEnvHandle = ECE.buildGlobalEnv();
    console.log("Global environment built.");

    for (const file of files) {
      const url = `${baseUrl}/${file}`;
      console.log(`Loading ${file}...`);
      const parsed = await ECE.loadEcecb(url);
      ECE.loadParsed(parsed);
    }

    console.log("Bootstrap complete.");
  },

  // Execute a loaded space
  runSpace(spaceName, pc) {
    const sym = ECE.internSym(spaceName);
    // sym is a handle; we need the symbol ID for get-space
    // For now, use the symbol's intern index directly
    // TODO: resolve this properly
    const w = ECE.wasm;
    return w.run(sym, pc || 0, ECE.globalEnvHandle);
  }
};

// Export for Node.js testing
if (typeof module !== "undefined") module.exports = ECE;
