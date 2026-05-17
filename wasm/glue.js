// ECE WebAssembly Runtime — JS Glue Layer
// ========================================
// Provides browser/Node glue for ECE's WASM runtime.

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
    },

    trace_save_restore(pc, spaceId, isSave, regId, valType, stackDepth) {
      // No-op in production. Override for debugging.
    }
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

  _refreshSingletonHandles() {
    const w = ECE.wasm;
    ECE._hNil = w.h_nil();
    ECE._hTrue = w.h_true();
    ECE._hFalse = w.h_false();
    ECE._hEof = w.h_eof();
    ECE._hVoid = w.h_void();
  },

  // Convert an ECE value handle to a JS value (for FFI arg marshalling)
  _eceToJs(handle) {
    const w = ECE.wasm;
    if (typeof w.h_false_p === "function" && w.h_false_p(handle)) return false;
    if (typeof w.h_true_p === "function" && w.h_true_p(handle)) return true;
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
      default: return null;
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
    },

    native_zone_call(idx, pc, val, env, proc, argl, cont, stack, co) {
      const fn = ECE._jsGet(idx);
      if (typeof fn !== "function") {
        throw new Error("native-zone export-ref is not callable");
      }
      if (fn.length >= 8) {
        return fn(pc, val, env, proc, argl, cont, stack, co);
      }
      return fn({ pc, val, env, proc, argl, cont, stack, co, wasm: ECE.wasm, ECE });
    }
  },

  wasmHost: {
    resources: new Map(),

    setText(url, text) {
      ECE.wasmHost.resources.set(url, { kind: "text", value: String(text) });
    },

    setBytes(url, bytes) {
      let value = bytes;
      if (bytes instanceof ArrayBuffer) {
        value = new Uint8Array(bytes);
      } else if (ArrayBuffer.isView(bytes)) {
        value = new Uint8Array(bytes.buffer, bytes.byteOffset, bytes.byteLength);
      }
      ECE.wasmHost.resources.set(url, { kind: "bytes", value });
    },

    clearResources() {
      ECE.wasmHost.resources.clear();
    },

    _resource(url, expectedKind) {
      const resource = ECE.wasmHost.resources.get(url);
      if (!resource) {
        throw new Error(`wasm-host: resource not cached: ${url}`);
      }
      if (resource.kind !== expectedKind) {
        throw new Error(`wasm-host: cached resource has wrong kind: ${url}`);
      }
      return resource.value;
    },

    fetch_text(ptr, len) {
      const url = ECE._readMem(ptr, len);
      const text = ECE.wasmHost._resource(url, "text");
      ECE.writeString(text);
      return text.length;
    },

    fetch_bytes(ptr, len) {
      const url = ECE._readMem(ptr, len);
      return ECE._jsAlloc(ECE.wasmHost._resource(url, "bytes"));
    },

    instantiate(bytesIdx, importsIdx) {
      const bytes = ECE._jsGet(bytesIdx);
      const imports = ECE._jsGet(importsIdx);
      const module = bytes instanceof WebAssembly.Module
        ? bytes
        : new WebAssembly.Module(bytes);
      const instance = new WebAssembly.Instance(module, imports || {});
      return ECE._jsAlloc(instance);
    },

    wasm_export(instanceIdx, ptr, len) {
      const instance = ECE._jsGet(instanceIdx);
      const name = ECE._readMem(ptr, len);
      const exportRef = instance && instance.exports && instance.exports[name];
      if (typeof exportRef !== "function") {
        throw new Error(`wasm-host: missing WASM export: ${name}`);
      }
      return ECE._jsAlloc(exportRef);
    },

    native_zone_imports() {
      return ECE._jsAlloc({
        ece: {
          h_fixnum: ECE.wasm.h_fixnum,
          h_nil: ECE.wasm.h_nil,
          h_true: ECE.wasm.h_true,
          h_false: ECE.wasm.h_false,
          h_false_p: ECE.wasm.h_false_p,
          h_char: ECE.wasm.h_char,
          h_cons: ECE.wasm.h_cons,
          h_symbol_1: ECE.wasm.h_symbol_1,
          h_symbol_from_chars: ECE.wasm.h_symbol_from_chars,
          h_lookup: ECE.wasm.h_lookup,
          h_primitive_p: ECE.wasm.h_primitive_p,
          h_continuation_p: ECE.wasm.h_continuation_p,
          h_parameter_p: ECE.wasm.h_parameter_p,
          h_compiled_entry: ECE.wasm.h_compiled_entry,
          h_compiled_env: ECE.wasm.h_compiled_env,
          h_make_compiled_proc: ECE.wasm.h_make_compiled_proc,
          h_extend_env: ECE.wasm.h_extend_env,
          h_lexical_ref: ECE.wasm.h_lexical_ref,
          h_lexical_set: ECE.wasm.h_lexical_set,
          h_apply_primitive: ECE.wasm.h_apply_primitive,
          h_error_sentinel_p: ECE.wasm.h_error_sentinel_p,
          pair_car: ECE.wasm.pair_car,
          pair_cdr: ECE.wasm.pair_cdr,
          h_vector: ECE.wasm.h_vector,
          h_vector_set: ECE.wasm.h_vector_set
        }
      });
    }
  },

  // ── Handle-based WASM interop ──
  // WASM stores GC refs in a handle table, JS gets i32 indices.

  _ensureStringWriteCapacity(codeUnitLength) {
    const requiredBytes = codeUnitLength * 2;
    const currentBytes = ECE.wasm.memory.buffer.byteLength;
    if (requiredBytes > currentBytes) {
      ECE.wasm.memory.grow(Math.ceil((requiredBytes - currentBytes) / 65536));
    }
  },

  _ensureByteWriteCapacity(byteLength) {
    const currentBytes = ECE.wasm.memory.buffer.byteLength;
    if (byteLength > currentBytes) {
      ECE.wasm.memory.grow(Math.ceil((byteLength - currentBytes) / 65536));
    }
  },

  // Write a JS string to WASM linear memory as UTF-16, return {offset, len}
  writeString(jsStr) {
    ECE._ensureStringWriteCapacity(jsStr.length);
    const mem = new Uint16Array(ECE.wasm.memory.buffer);
    for (let i = 0; i < jsStr.length; i++) {
      mem[i] = jsStr.charCodeAt(i);
    }
    return { offset: 0, len: jsStr.length };
  },

  // Write bytes to WASM linear memory, return {offset, len}
  writeBytes(bytesLike) {
    const bytes = bytesLike instanceof Uint8Array
      ? bytesLike
      : new Uint8Array(bytesLike);
    ECE._ensureByteWriteCapacity(bytes.byteLength);
    new Uint8Array(ECE.wasm.memory.buffer, 0, bytes.byteLength).set(bytes);
    return { offset: 0, len: bytes.byteLength };
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

  _schemeStringLiteral(jsStr) {
    return `"${String(jsStr).replace(/\\/g, "\\\\").replace(/"/g, "\\\"")}"`;
  },

  _archiveBytes(bytesLike) {
    if (bytesLike instanceof Uint8Array) return bytesLike;
    if (bytesLike instanceof ArrayBuffer) return new Uint8Array(bytesLike);
    if (ArrayBuffer.isView(bytesLike)) {
      return new Uint8Array(bytesLike.buffer, bytesLike.byteOffset, bytesLike.byteLength);
    }
    throw new Error("archive bytes must be an ArrayBuffer or typed array");
  },

  _archiveBytesAreBinary(bytesLike) {
    const bytes = ECE._archiveBytes(bytesLike);
    return bytes.length >= 8 &&
      bytes[0] === 0x45 && bytes[1] === 0x43 &&
      bytes[2] === 0x45 && bytes[3] === 0x43 &&
      bytes[4] === 0x00 &&
      bytes[5] === 0x42 && bytes[6] === 0x49 && bytes[7] === 0x4e;
  },

  _decodeArchiveText(bytesLike) {
    const bytes = ECE._archiveBytes(bytesLike);
    if (typeof TextDecoder !== "undefined") {
      return new TextDecoder("utf-8").decode(bytes);
    }
    if (typeof Buffer !== "undefined") {
      return Buffer.from(bytes.buffer, bytes.byteOffset, bytes.byteLength).toString("utf8");
    }
    let text = "";
    for (let i = 0; i < bytes.length; i++) text += String.fromCharCode(bytes[i]);
    return text;
  },

  _base64ToBytes(base64) {
    if (typeof Buffer !== "undefined") {
      return new Uint8Array(Buffer.from(base64, "base64"));
    }
    const raw = atob(base64);
    const bytes = new Uint8Array(raw.length);
    for (let i = 0; i < raw.length; i++) bytes[i] = raw.charCodeAt(i);
    return bytes;
  },

  evalStringLast(source) {
    const evalStr = ECE.wasm.env_lookup(ECE.globalEnvHandle, ECE.internSym("eval-string-last"));
    return ECE.wasm.call_ece_proc(
      evalStr,
      ECE.wasm.h_cons(ECE.makeString(source), ECE._hNil));
  },

  // Load a .ecec archive (single top-level sexp).
  // Returns a handle wrapping the init code-object.
  loadArchiveText(text) {
    const w = ECE.wasm;
    text = text.trimEnd();
    const { offset, len } = ECE.writeString(text);
    return w.load_archive(offset, len);
  },

  // Load a multi-archive bundle (one or more (ecec-archive ...) sexps
  // concatenated). Each archive's init code-object is loaded and
  // executed sequentially so definitions from earlier archives are
  // available to later ones. Returns the final init code-object handle.
  //
  // Handle-table growth: each iteration allocates two handles (the
  // load_archive_continue co-handle + the run_code_object result). These
  // remain live until the caller invokes mark_handles()/reset_handles().
  // The bootstrap path (and test runners) call mark_handles() immediately
  // after this returns, so growth is bounded by the bundle's archive count
  // per bootstrap — not per-call-to-loadArchiveBundle over the program
  // lifetime. Callers that invoke loadArchiveBundle repeatedly without
  // marking afterwards should reset handles between calls.
  loadArchiveBundle(text) {
    const codeObjects = ECE.materializeArchiveBundleText(text);
    ECE.runCodeObjects(codeObjects);
    return codeObjects[codeObjects.length - 1];
  },

  loadArchiveBytes(bytes) {
    const { offset, len } = ECE.writeBytes(bytes);
    return ECE.wasm.load_binary_archive(offset, len);
  },

  loadArchiveAuto(archive) {
    if (typeof archive === "string") {
      return ECE.loadArchiveText(archive);
    }
    const bytes = ECE._archiveBytes(archive);
    return ECE._archiveBytesAreBinary(bytes)
      ? ECE.loadArchiveBytes(bytes)
      : ECE.loadArchiveText(ECE._decodeArchiveText(bytes));
  },

  loadArchiveBase64(base64) {
    return ECE.loadArchiveAuto(ECE._base64ToBytes(base64));
  },

  materializeArchiveBundleBytes(bytes) {
    const w = ECE.wasm;
    const codeObjects = [ECE.loadArchiveBytes(bytes)];
    while (w.binary_archive_has_more()) {
      codeObjects.push(w.load_binary_archive_continue());
    }
    return codeObjects;
  },

  materializeArchiveBundleText(text) {
    const w = ECE.wasm;
    const codeObjects = [ECE.loadArchiveText(text)];
    while (w.archive_has_more()) {
      codeObjects.push(w.load_archive_continue());
    }
    return codeObjects;
  },

  runCodeObjects(codeObjects) {
    const w = ECE.wasm;
    let result = ECE._hVoid;
    for (const co of codeObjects) {
      result = w.run_code_object(co, ECE.globalEnvHandle);
    }
    return result;
  },

  loadArchiveBundleBytes(bytes) {
    const codeObjects = ECE.materializeArchiveBundleBytes(bytes);
    ECE.runCodeObjects(codeObjects);
    return codeObjects[codeObjects.length - 1];
  },

  loadArchiveBundleAuto(archive) {
    if (typeof archive === "string") {
      return ECE.loadArchiveBundle(archive);
    }
    const bytes = ECE._archiveBytes(archive);
    return ECE._archiveBytesAreBinary(bytes)
      ? ECE.loadArchiveBundleBytes(bytes)
      : ECE.loadArchiveBundle(ECE._decodeArchiveText(bytes));
  },

  loadArchiveBundleBase64(base64) {
    return ECE.loadArchiveBundleAuto(ECE._base64ToBytes(base64));
  },

  async fetchArchiveBytes(url, options = {}) {
    const resp = await fetch(url, options);
    if (!resp.ok) {
      throw new Error(`failed to fetch archive ${url}: ${resp.status}`);
    }
    return new Uint8Array(await resp.arrayBuffer());
  },

  async fetchAndLoadArchiveBundle(url, options = {}) {
    return ECE.loadArchiveBundleAuto(await ECE.fetchArchiveBytes(url, options));
  },

  async reloadProgramFromUrls(archiveUrl, zoneModuleUrl = null, manifestUrl = null) {
    if ((zoneModuleUrl && !manifestUrl) || (!zoneModuleUrl && manifestUrl)) {
      throw new Error("reloadProgramFromUrls requires both native-zone URLs or neither");
    }

    const archiveResp = await fetch(archiveUrl, { cache: "no-store" });
    if (!archiveResp.ok) {
      throw new Error(`reloadProgramFromUrls failed to fetch archive: ${archiveResp.status}`);
    }
    const archiveBytes = new Uint8Array(await archiveResp.arrayBuffer());
    const archiveIsBinary = ECE._archiveBytesAreBinary(archiveBytes);
    const archiveText = archiveIsBinary ? null : ECE._decodeArchiveText(archiveBytes);
    if (archiveIsBinary) {
      ECE.wasmHost.setBytes(archiveUrl, archiveBytes);
    } else {
      ECE.wasmHost.setText(archiveUrl, archiveText);
    }

    if (zoneModuleUrl && manifestUrl) {
      const [zoneResp, manifestResp] = await Promise.all([
        fetch(zoneModuleUrl, { cache: "no-store" }),
        fetch(manifestUrl, { cache: "no-store" })
      ]);
      if (!zoneResp.ok) {
        throw new Error(`reloadProgramFromUrls failed to fetch zone module: ${zoneResp.status}`);
      }
      if (!manifestResp.ok) {
        throw new Error(`reloadProgramFromUrls failed to fetch zone manifest: ${manifestResp.status}`);
      }
      ECE.wasmHost.setBytes(zoneModuleUrl, await zoneResp.arrayBuffer());
      ECE.wasmHost.setText(manifestUrl, await manifestResp.text());
    }

    ECE.wasm.reset_handles();
    ECE._refreshSingletonHandles();
    ECE._symCache = {};

    if (archiveIsBinary || (!zoneModuleUrl && !manifestUrl)) {
      const codeObjects = archiveIsBinary
        ? ECE.materializeArchiveBundleBytes(archiveBytes)
        : ECE.materializeArchiveBundleText(archiveText);

      if (zoneModuleUrl && manifestUrl) {
        ECE.evalStringLast(
          `(load-native-zone-module ${ECE._schemeStringLiteral(zoneModuleUrl)} ${ECE._schemeStringLiteral(manifestUrl)})`);
      }
      return ECE.runCodeObjects(codeObjects);
    }

    const args = [
      ECE._schemeStringLiteral(archiveUrl),
      ECE._schemeStringLiteral(zoneModuleUrl),
      ECE._schemeStringLiteral(manifestUrl)
    ].join(" ");
    return ECE.evalStringLast(`(reload-program ${args})`);
  },

  // Execute a loaded archive's init code-object.
  runCodeObject(coHandle) {
    return ECE.wasm.run_code_object(coHandle, ECE.globalEnvHandle);
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
      ffi: ECE.ffi,
      wasm_host: ECE.wasmHost
    };

    const { instance } = await WebAssembly.instantiate(wasmBytes, imports);
    ECE.wasm = instance.exports;

    return instance;
  },

  // Build global environment — boot-env.ecec handles primitive registration,
  // continuation/error caching, and REPL space creation.
  // Assembler symbol table must be initialized here (before any .ecec loading)
  // because the WAT ecec text loader uses it to resolve instruction symbols.
  buildGlobalEnv() {
    const w = ECE.wasm;
    const envHandle = w.build_global_env(0);

    // Cache singleton handles for JS-side use
    ECE._refreshSingletonHandles();

    // Pre-register boot-registration primitives so boot-env.ecec can call them
    w.env_define(envHandle, ECE.internSym("%register-primitive!"), w.h_primitive(222));
    w.env_define(envHandle, ECE.internSym("%init-asm-syms"), w.h_primitive(223));
    w.env_define(envHandle, ECE.internSym("%store-asm-sym"), w.h_primitive(224));
    w.env_define(envHandle, ECE.internSym("%set-continuation-syms!"), w.h_primitive(225));
    w.env_define(envHandle, ECE.internSym("%set-error-sym!"), w.h_primitive(226));
    w.env_define(envHandle, ECE.internSym("%create-repl-space!"), w.h_primitive(227));

    // Initialize assembler symbol table — required by the WAT ecec text loader
    // before any .ecec files can be parsed. boot-env.ecec will re-initialize
    // this (idempotently) so the .def files remain the single source of truth.
    ECE.initAssemblerSymbols();

    // Define #t and #f — can't be done in boot-env.ecec because the ecec
    // text format can't distinguish (const #t) as value vs symbol name
    w.env_define(envHandle, ECE.internSym("#t"), ECE._hTrue);
    w.env_define(envHandle, ECE.internSym("#f"), ECE._hFalse);

    // Mark permanent handles (env, symbols, singletons)
    w.mark_handles();

    // Store global env for execute-from-pc
    w.set_global_env(envHandle);

    // Define *global-env* as an ECE variable so env-reset instructions
    // in flat .ecec files can look it up during execution
    w.env_define(envHandle, ECE.internSym("*global-env*"), envHandle);

    return envHandle;
  },

  // Initialize assembler symbol ID table — required by WAT ecec text loader.
  initAssemblerSymbols() {
    const w = ECE.wasm;
    const names = [
      'assign', 'test', 'branch', 'goto', 'save', 'restore', 'perform',
      'val', 'env', 'proc', 'argl', 'continue', 'stack',
      'const', 'reg', 'label', 'op',
      'lookup-variable-value', 'lookup-global-variable',
      'set-variable-value!', 'define-variable!', 'extend-environment',
      'lexical-ref', 'lexical-set!',
      'make-compiled-procedure', 'compiled-procedure-entry', 'compiled-procedure-env',
      'primitive-procedure?', 'continuation?', 'parameter?',
      'apply-primitive-procedure', 'apply-parameter',
      'parameter-ref', 'parameter-set!', 'parameter-raw-set!',
      'capture-continuation', 'do-continuation-winds',
      'continuation-stack', 'continuation-conts',
      'false?', 'list', 'cons', 'car', 'cdr',
      'halt',
    ];
    w.init_asm_syms(names.length);
    for (let i = 0; i < names.length; i++) {
      w.store_asm_sym(i, ECE.internSym(names[i]));
    }
  },

  async bootstrap(baseUrl) {
    // Build global environment first
    ECE.globalEnvHandle = ECE.buildGlobalEnv();
    console.log("Global environment built.");

    // Load bootstrap bundle (multi-archive sexp)
    const url = `${baseUrl}/bootstrap.ecec`;
    console.log("Loading bootstrap bundle...");
    await ECE.fetchAndLoadArchiveBundle(url);
    ECE.wasm.mark_handles();

    console.log("Bootstrap complete.");
  }
};

// Browser classic scripts do not expose top-level const bindings as window
// properties. App skeletons and hand-written pages use window/globalThis.ECE.
if (typeof globalThis !== "undefined") globalThis.ECE = ECE;

// Export for Node.js testing
if (typeof module !== "undefined") module.exports = ECE;
