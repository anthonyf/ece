## Context

ECE's port system on CL wraps CL streams. On WASM, ports are currently stubs (read-char returns eof, open-input-string returns the string itself). File I/O primitives (100-103) have no WASM implementation. Implementing buffer-based ports with localStorage backing unifies the test suites and enables browser-based save/load.

## Goals / Non-Goals

**Goals:**
- File I/O works on WASM via localStorage
- All port primitives (60-75) work on WASM
- All 41 CL-only tests become common tests
- Save/load for IF games works in the browser

**Non-Goals:**
- Filesystem access (no File System Access API)
- Binary file I/O on WASM (text only via UTF-16 buffers)
- Streaming I/O (entire file loaded into buffer at open)

## Decisions

### 1. Port struct design

```wat
(type $port (struct
  (field $buffer (mut (ref null $string)))  ;; UTF-16 content buffer
  (field $pos    (mut i32))                 ;; read position / write length
  (field $cap    (mut i32))                 ;; buffer capacity (for output growth)
  (field $name   (ref null $string))        ;; filename (null for string ports)
  (field $dir    i32)                       ;; 0=input, 1=output
  (field $open   (mut i32))))              ;; 1=open, 0=closed
```

Input ports: buffer filled at open time, pos advances on read-char.
Output ports: buffer grows on write-char, flushed to localStorage on close.
String ports: same struct, name=null (no localStorage interaction).

### 2. localStorage integration via JS imports

Two JS imports handle all storage:
- `storage_read`: writes filename to linear memory, JS reads localStorage, writes content back to linear memory, returns length
- `storage_write`: JS reads filename + content from linear memory, calls localStorage.setItem

This uses the existing linear memory transfer pattern (same as display_string).

### 3. open-input-string unification

The existing `open-input-string` (prim 73) currently returns the string itself. It should create a proper `$port` struct — same type as file ports, just with name=null. This unifies all port operations.

### 4. Current-input/output-port

Global defaults for console I/O:
- `current-input-port`: a special port that delegates read-char to a JS import (browser prompt or stdin)
- `current-output-port`: a special port where write-char calls the existing display_string JS import

These are created at startup and stored as globals.

### 5. with-input-from-file / with-output-to-file

These (IDs 102-103) are higher-level operations that temporarily redirect current-input/output-port. They can be implemented as ECE prelude wrappers using `dynamic-wind` or simple save/restore, rather than platform primitives. This keeps the WAT implementation focused on the core port operations.

## Risks / Trade-offs

- **localStorage size limit**: Typically 5-10MB per origin. Adequate for save files and test data. Not suitable for large file storage.
- **No binary I/O**: localStorage stores strings. Binary data would need base64 encoding. For the current use case (text files, serialized s-expressions), this is fine.
- **Synchronous API**: localStorage is synchronous, matching ECE's synchronous I/O model. No async complications.
- **Node.js testing**: Node.js doesn't have localStorage. The JS glue should provide a Map-based fallback for testing outside the browser.
