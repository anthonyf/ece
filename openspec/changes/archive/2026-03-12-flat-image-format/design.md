## Context

ECE images are currently serialized using CL's `write` with `*print-circle* t` and loaded using CL's `read` with a custom readtable (`*ece-readtable*`). The custom readtable adds quasiquote, unquote, string interpolation, and hash table literal syntax (~130 lines). Loading requires a full recursive descent s-expression parser with `#n=`/`#n#` structural sharing support.

Analysis of the current image (`bootstrap/ece.image`, 1.2MB) shows: 189 shared reference definitions, 37,625 back-references, zero circular references (all structural sharing). The image contains symbols, integers, strings, vectors, 3 keywords, ~35 gensym keywords, 31 character literals, and nested cons structures.

The image is fully self-hosting: it contains the ECE reader, compiler, assembler, prelude, and compaction code. After loading an image, the system can read `.scm` files, compile them, and save new images without any CL reader infrastructure.

## Goals / Non-Goals

**Goals:**
- Replace s-expression image format with a flat, line-oriented text format that requires only a trivial deserializer (switch statement over ~12 opcodes)
- Remove CL reader infrastructure (`*ece-readtable*`, reader macros, `ece-read`) from the runtime (~230 lines)
- Serialize characters by integer code point to avoid implementation-specific character names
- Maintain image round-trip correctness for all ECE data types including structural sharing
- Keep the format human-readable (text, one instruction per line)

**Non-Goals:**
- Binary format (future optimization — text first for debuggability)
- Changing the image's logical content (7-element structure: instructions, labels, env, macros, names, params, param-counter)
- Modifying the compaction algorithm (stays in ECE-side code)
- Removing the CL reader from `compiler.lisp` (cold boot still uses it for the one-time transition)

## Decisions

### 1. Stack-based flat format with ~12 opcodes

The format uses one instruction per line. Each instruction either pushes a value onto a build stack or pops values to construct compound data. Structural sharing uses `def N` (assign ID to top-of-stack) and `ref N` (push previously defined value).

**Opcodes:**
| Opcode | Args | Action |
|--------|------|--------|
| `int N` | integer | Push integer N |
| `sym NAME` | symbol name | Push interned symbol |
| `kwd NAME` | keyword name | Push keyword |
| `str "..."` | escaped string | Push string |
| `chr N` | char code | Push `(code-char N)` |
| `nil` | — | Push NIL |
| `t` | — | Push T |
| `cons` | — | Pop B, pop A, push (A . B) |
| `list N` | count | Pop N items, push proper list |
| `vec N` | count | Pop N items, push vector |
| `def N` | ID | Assign ID N to top-of-stack (no pop) |
| `ref N` | ID | Push previously defined value N |

**Rationale:** Alternatives considered: (a) JSON — loses symbol/keyword/char distinction, no structural sharing; (b) s-expression with simpler reader — still requires parenthesis matching and recursive descent; (c) binary format — not human-readable, harder to debug. The stack-based approach requires zero lookahead, no nesting, and maps naturally to a `case` statement.

### 2. Serializer walks data depth-first with identity tracking

The serializer (`ece-serialize-flat`) walks the image data structure depth-first. It uses an identity hash table (`eq`) to detect shared references:
- First visit: emit the value's build instructions, assign a `def N` if the value appears elsewhere
- Subsequent visits: emit `ref N`

Pre-pass counts references to determine which values need `def` IDs (only values referenced >1 time get IDs, to keep the output smaller).

**Rationale:** Single-pass with deferred def would require backpatching line numbers. Two-pass (count then emit) is simpler and produces cleaner output.

### 3. String escaping uses minimal escape set

Strings are emitted as `str "..."` with only these escapes: `\\` → backslash, `\"` → double quote, `\n` → newline, `\t` → tab, `\r` → carriage return. All other characters are emitted literally (including UTF-8).

**Rationale:** Matches ECE's own reader escape set. No need for hex escapes since the format is UTF-8 text.

### 4. Image structure preserved as top-level list

The 7-element image structure (instructions, labels, env, macros, names, params, param-counter) is serialized as a `list 7` at the end. The deserializer pops the final value from the stack as the image data, then destructures it identically to the current `ece-load-image`.

### 5. CL reader infrastructure removed from runtime.lisp

After the flat deserializer is working:
- Delete `*ece-readtable*` and all `set-macro-character` calls (lines ~378-483)
- Delete `ece-read` function
- Remove `*readtable*` bindings from `ece-load-image`, `compile-file-ece`
- `compile-file-ece` in `compiler.lisp` (cold boot only) retains the CL reader

**Rationale:** The ECE reader (in the image) handles all `.scm` file reading after boot. CL reader is only needed during cold bootstrap, which lives in `compiler.lisp`.

### 6. Characters serialized by integer code point

`#\space` → `chr 32`, `#\newline` → `chr 10`, etc. No named characters.

**Rationale:** SBCL uses implementation-specific Unicode character names (e.g., `#\Combining_Tilde`). Integer code points are universally portable.

## Risks / Trade-offs

- **One-time transition complexity** → The first flat image must be built using the old CL reader path. After that, the system is self-hosting. Mitigation: `make image` does the transition build; verify round-trip before deleting old code.
- **Larger image file** → Flat format may be slightly larger than s-expression format due to one-instruction-per-line overhead. Mitigation: acceptable for text format; binary format is a future optimization.
- **Hash table serialization** → HAMT internal structure (cons trees with keywords `:hash-table`, `:hamt-leaf`, etc.) serializes naturally as nested cons/list. No special opcode needed.
- **Gensym keywords** → Keywords like `:|1|` from gensym-based parameter IDs serialize as `kwd |1|` — deserializer must handle `|...|` escaping. Mitigation: use same CL `symbol-name` extraction for keywords.
