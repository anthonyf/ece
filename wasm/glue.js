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
    }
  },

  loader: {
    fetch_ececb() { return null; }  // placeholder
  },

  // ── .ececb binary parser ──

  parseBinary(bytes) {
    const view = new DataView(bytes.buffer || bytes);
    let pos = 0;

    function u8() { return view.getUint8(pos++); }
    function u16() { const v = view.getUint16(pos, true); pos += 2; return v; }
    function u32() { const v = view.getUint32(pos, true); pos += 4; return v; }
    function i32() { const v = view.getInt32(pos, true); pos += 4; return v; }
    function f64() { const v = view.getFloat64(pos, true); pos += 8; return v; }
    function str(len) {
      const s = new TextDecoder().decode(bytes.slice(pos, pos + len));
      pos += len;
      return s;
    }
    function lpStr() { return str(u16()); }      // u16-le prefixed
    function lpStr32() { return str(u32()); }     // u32-le prefixed

    // Read header
    const magic = str(4);
    if (magic !== "ECEB") throw new Error(`Bad magic: ${magic}`);
    const version = u8();
    if (version !== 1) throw new Error(`Unsupported version: ${version}`);
    const spaceName = lpStr();
    const macroCount = u16();
    const macros = [];
    for (let i = 0; i < macroCount; i++) macros.push(lpStr());

    // Read units
    const units = [];
    while (pos < bytes.length) {
      const marker = u8();
      if (marker !== 0xFE) throw new Error(`Bad unit marker: ${marker} at ${pos - 1}`);

      // Labels
      const labelCount = u32();
      const labels = {};
      for (let i = 0; i < labelCount; i++) {
        const name = lpStr();
        const pc = u32();
        labels[name] = pc;
      }

      // Instructions
      const instrCount = u32();
      const instrs = [];
      for (let i = 0; i < instrCount; i++) {
        instrs.push(readInstruction());
      }

      units.push({ labels, instrs });
    }

    function readInstruction() {
      const opcode = u8();
      switch (opcode) {
        case 0: return readAssign();
        case 1: return readTest();
        case 2: return readBranch();
        case 3: return readGoto();
        case 4: return { op: "save", reg: u8() };
        case 5: return { op: "restore", reg: u8() };
        case 6: return readPerform();
        default: throw new Error(`Unknown opcode: ${opcode}`);
      }
    }

    function readAssign() {
      const target = u8();
      const srcType = u8();
      switch (srcType) {
        case 0: return { op: "assign", target, src: "const", val: readValue() };
        case 1: return { op: "assign", target, src: "reg", srcReg: u8() };
        case 2: return { op: "assign", target, src: "label", label: lpStr() };
        case 3: {
          const opId = u8();
          const count = u8();
          const operands = [];
          for (let i = 0; i < count; i++) operands.push(readOperand());
          return { op: "assign", target, src: "op", opId, operands };
        }
        default: throw new Error(`Unknown assign src type: ${srcType}`);
      }
    }

    function readTest() {
      const opId = u8();
      const count = u8();
      const operands = [];
      for (let i = 0; i < count; i++) operands.push(readOperand());
      return { op: "test", opId, operands };
    }

    function readBranch() {
      return { op: "branch", label: lpStr() };
    }

    function readGoto() {
      const destType = u8();
      if (destType === 0) return { op: "goto", dest: "label", label: lpStr() };
      if (destType === 1) return { op: "goto", dest: "reg", reg: u8() };
      throw new Error(`Unknown goto dest type: ${destType}`);
    }

    function readPerform() {
      const opId = u8();
      const count = u8();
      const operands = [];
      for (let i = 0; i < count; i++) operands.push(readOperand());
      return { op: "perform", opId, operands };
    }

    function readOperand() {
      const type = u8();
      switch (type) {
        case 0: return { type: "const", val: readValue() };
        case 1: return { type: "reg", reg: u8() };
        case 2: return { type: "label", label: lpStr() };
        default: throw new Error(`Unknown operand type: ${type}`);
      }
    }

    function readValue() {
      const type = u8();
      switch (type) {
        case 0: return { type: "fixnum", val: i32() };
        case 1: return { type: "string", val: lpStr32() };
        case 2: return { type: "symbol", val: lpStr() };
        case 3: return { type: "true" };
        case 4: return { type: "false" };
        case 5: return { type: "nil" };
        case 6: return { type: "eof" };
        case 7: return { type: "char", val: u32() };
        case 8: return { type: "float", val: f64() };
        case 9: return { type: "void" };
        case 10: return { type: "pair", car: readValue(), cdr: readValue() };
        case 11: {
          const vlen = u32();
          const elems = [];
          for (let i = 0; i < vlen; i++) elems.push(readValue());
          return { type: "vector", elems };
        }
        default: throw new Error(`Unknown value type: ${type}`);
      }
    }

    return { spaceName, version, macros, units };
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

  // Build a WASM value from parsed .ececb value (returns handle i32)
  buildValue(val) {
    const w = ECE.wasm;
    switch (val.type) {
      case "fixnum":  return w.h_fixnum(val.val);
      case "string":  return ECE.makeString(val.val);
      case "symbol":  return ECE.internSym(val.val);
      case "true":    return ECE._hTrue  || (ECE._hTrue  = w.h_true());
      case "false":   return ECE._hFalse || (ECE._hFalse = w.h_false());
      case "nil":     return ECE._hNil   || (ECE._hNil   = w.h_nil());
      case "eof":     return ECE._hEof   || (ECE._hEof   = w.h_eof());
      case "char":    return w.h_char(val.val);
      case "float":   return w.h_float(val.val);
      case "void":    return ECE._hVoid  || (ECE._hVoid  = w.h_void());
      case "pair":    return w.h_cons(ECE.buildValue(val.car), ECE.buildValue(val.cdr));
      case "vector": {
        const vecH = w.h_vector(val.elems.length);
        for (let i = 0; i < val.elems.length; i++) {
          w.h_vector_set(vecH, i, ECE.buildValue(val.elems[i]));
        }
        return vecH;
      }
      default:        return ECE._hNil || (ECE._hNil = w.h_nil());
    }
  },

  // Build an operand as a WASM pair (type . value) — handle i32
  buildOperand(op, labelMap) {
    const w = ECE.wasm;
    const nil = ECE._hNil || (ECE._hNil = w.h_nil());
    switch (op.type) {
      case "const":
        return w.h_cons(w.h_fixnum(0), ECE.buildValue(op.val));
      case "reg":
        return w.h_cons(w.h_fixnum(1), w.h_fixnum(op.reg));
      case "label": {
        const pc = labelMap[op.label];
        if (pc === undefined) {
          console.warn(`Unresolved label: ${op.label}`);
          return w.h_cons(w.h_fixnum(2), w.h_fixnum(0));
        }
        return w.h_cons(w.h_fixnum(2), w.h_fixnum(pc));
      }
      default: return nil;
    }
  },

  // Build an operand list (handle i32)
  buildOperandList(operands, labelMap) {
    const w = ECE.wasm;
    const nil = ECE._hNil || (ECE._hNil = w.h_nil());
    let list = nil;
    for (let i = operands.length - 1; i >= 0; i--) {
      list = w.h_cons(ECE.buildOperand(operands[i], labelMap), list);
    }
    return list;
  },

  // Build a $instr struct from a parsed instruction (handle i32)
  buildInstruction(instr, labelMap) {
    const w = ECE.wasm;
    const nil = ECE._hNil || (ECE._hNil = w.h_nil());

    switch (instr.op) {
      case "assign": {
        let b, c, val;
        switch (instr.src) {
          case "const": b = 0; c = 0; val = ECE.buildValue(instr.val); break;
          case "reg":   b = 1; c = instr.srcReg; val = nil; break;
          case "label": {
            b = 2;
            c = labelMap[instr.label] !== undefined ? labelMap[instr.label] : 0;
            val = nil;
            break;
          }
          case "op":
            b = 3; c = instr.opId;
            val = ECE.buildOperandList(instr.operands, labelMap);
            break;
        }
        return w.make_instr(0, instr.target, b, c, val);
      }
      case "test":
        return w.make_instr(1, 0, 0, instr.opId,
          ECE.buildOperandList(instr.operands, labelMap));
      case "branch": {
        const pc = labelMap[instr.label] !== undefined ? labelMap[instr.label] : 0;
        return w.make_instr(2, 0, 0, pc, nil);
      }
      case "goto":
        if (instr.dest === "label") {
          const pc = labelMap[instr.label] !== undefined ? labelMap[instr.label] : 0;
          return w.make_instr(3, 0, 0, pc, nil);
        } else {
          return w.make_instr(3, 0, 1, instr.reg, nil);
        }
      case "save":
        return w.make_instr(4, instr.reg, 0, 0, nil);
      case "restore":
        return w.make_instr(5, instr.reg, 0, 0, nil);
      case "perform":
        return w.make_instr(6, 0, 0, instr.opId,
          ECE.buildOperandList(instr.operands, labelMap));
      default:
        console.warn(`Unknown instruction: ${instr.op}`);
        return w.make_instr(7, 0, 0, 0, nil);
    }
  },

  // Load a parsed .ececb into WASM compilation spaces
  loadParsed(parsed) {
    const w = ECE.wasm;
    const spaceSym = ECE.internSym(parsed.spaceName);

    // Count total instructions across all units
    let totalInstrs = 0;
    for (const unit of parsed.units) totalInstrs += unit.instrs.length;

    // Create the compilation space (handle must survive reset_handles)
    const spaceHandle = w.create_space(spaceSym, totalInstrs);
    // Re-mark so the space handle is below the watermark
    w.mark_handles();

    // Global label map (labels from all units, offset by cumulative PC)
    const labelMap = {};
    let basePC = 0;
    for (const unit of parsed.units) {
      for (const [name, pc] of Object.entries(unit.labels)) {
        labelMap[name] = basePC + pc;
      }
      basePC += unit.instrs.length;
    }

    // Build and set all instructions
    // Reset temporary handles after each instruction to avoid overflow.
    // The instruction GC struct is stored in the space's array, so it
    // remains reachable even after the handle is freed.
    let pc = 0;
    for (const unit of parsed.units) {
      for (const instr of unit.instrs) {
        const instrHandle = ECE.buildInstruction(instr, labelMap);
        w.space_set_instr(spaceHandle, pc, instrHandle);
        // Handle recycling disabled for now — causes issues with operand values.
        // TODO: optimize handle usage in a future pass
        pc++;
      }
    }

    console.log(`Loaded space "${parsed.spaceName}": ${pc} instructions, ${Object.keys(labelMap).length} labels`);
    return spaceHandle;
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
      loader: ECE.loader
    };

    const { instance } = await WebAssembly.instantiate(wasmBytes, imports);
    ECE.wasm = instance.exports;

    return instance;
  },

  async loadEcecb(url) {
    const response = await fetch(url);
    const bytes = new Uint8Array(await response.arrayBuffer());
    const parsed = ECE.parseBinary(bytes);
    console.log(`Loaded ${url}: space="${parsed.spaceName}", ${parsed.units.length} units`);
    return parsed;
  },

  // Build global environment with all primitives
  buildGlobalEnv() {
    const w = ECE.wasm;
    const envHandle = w.build_global_env(0);

    // Register ALL primitives from primitives.def
    // Core (0-99) + CL-compat stubs
    const prims = [
      [0,"+"], [1,"-"], [2,"*"], [3,"/"], [4,"modulo"],
      [5,"car"], [6,"cdr"], [7,"cons"], [8,"list"],
      [9,"set-car!"], [10,"set-cdr!"],
      [11,"null?"], [12,"pair?"], [13,"number?"], [14,"string?"],
      [15,"symbol?"], [16,"integer?"], [17,"char?"], [18,"vector?"],
      [19,"boolean?"], [20,"eq?"], [21,"equal?"],
      [22,"="], [23,"<"], [24,">"],
      [25,"string-length"], [26,"string-ref"], [27,"string-append"],
      [28,"substring"], [29,"string->number"], [30,"number->string"],
      [31,"string->symbol"], [32,"symbol->string"],
      [33,"string=?"], [34,"string<?"], [35,"string>?"],
      [36,"string-downcase"], [37,"string-upcase"],
      [38,"string-split"], [39,"string-trim"],
      [40,"string-contains?"], [41,"string-join"], [42,"string"],
      [43,"char->integer"], [44,"integer->char"],
      [45,"char=?"], [46,"char<?"],
      [47,"char-whitespace?"], [48,"char-alphabetic?"], [49,"char-numeric?"],
      [50,"make-vector"], [51,"vector"], [52,"vector-ref"],
      [53,"vector-set!"], [54,"vector-length"],
      [55,"vector->list"], [56,"list->vector"],
      [57,"display"], [58,"write"], [59,"newline"],
      [60,"read-char"], [61,"peek-char"], [62,"write-char"],
      [63,"read-line"], [64,"char-ready?"], [65,"eof?"],
      [66,"print"], [67,"write-to-string"],
      [68,"input-port?"], [69,"output-port?"], [70,"port?"],
      [71,"current-input-port"], [72,"current-output-port"],
      [73,"open-input-string"], [74,"close-input-port"], [75,"close-output-port"],
      [76,"bitwise-and"], [77,"bitwise-or"], [78,"bitwise-xor"],
      [79,"bitwise-not"], [80,"arithmetic-shift"],
      [81,"%raw-error"], [82,"gensym"],
      [83,"sleep"], [84,"clear-screen"],
      [85,"execute-from-pc"], [86,"get-macro"], [87,"set-macro!"],
      [88,"make-parameter"],
      [89,"apply-compiled-procedure"], [90,"try-eval"],
      [91,"extend-environment"],
      [92,"%intern-ece"],
      [93,"%instruction-vector-length"], [94,"%instruction-vector-push!"],
      [95,"%label-table-set!"], [96,"%label-table-ref"],
      [97,"%procedure-name-set!"],
      [98,"platform-has?"], [99,"%platform-primitives"],
      [114,"parameter?"], [137,"keyword?"],
      // Platform hash table primitives (core)
      [141,"%make-hash-table"], [142,"hash-table?"],
      [143,"hash-ref"], [144,"hash-set!"], [145,"hash-remove!"],
      [146,"hash-has-key?"], [147,"hash-keys"], [148,"hash-values"], [149,"hash-count"],
    ];

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

    return envHandle;
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
