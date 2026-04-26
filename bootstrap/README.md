# bootstrap/ — .ecec archive format reference

This directory holds the files that boot ECE from scratch:

- `bootstrap.ecec` — the compiled prelude/compiler/assembler/reader/... bundle. One `(:ecec-archive ...)` section per source `.scm` file, concatenated.
- `primitives-auto.lisp` — auto-generated CL defuns that bridge primitive ids to host implementations (loaded before `bootstrap.ecec`).
- `*-zone.lisp` — per-code-object compiled-zone files generated from `bootstrap.ecec`. Each file contains one CL `defun` and registers it in the archive zone registry at load time.

This README documents the on-disk `.ecec` archive format (version 2) introduced by the `per-procedure-code-objects` change. The previous multi-space header format is retired; loaders raise on any non-archive input and point users at `make bootstrap` to regenerate.

## Archive s-expression shape

Each `.ecec` section is a single top-level s-expression:

```scheme
(:ecec-archive
  :version  2
  :file     "prelude.scm"
  :unit-id  <optional-explicit-unit-id>
  :entries  (<entry-0> <entry-1> ... <entry-N-1>))
```

- `version` is the integer `2`. A mismatch (including missing version) yields the error `"Unsupported .ecec archive version: <v>. Run `make bootstrap` to regenerate."`.
- `file` is the basename of the `.scm` source the archive was compiled from. Current file archives synthesize their archive unit-id by stripping this extension and interning the stem as an ECE symbol.
- `unit-id` is optional. When present, it supplies the semantic unit identity used as the first element of `(unit-id . co-key)` zone-registry keys. String unit ids are treated as legacy file stems and normalized to ECE symbols; structured ids are preserved as data.
- `entries` is a list of code-object entries. Entry 0 is the archive's **init code-object**, produced by wrapping all top-level forms of the source in `(begin ...)` and calling `mc-compile-to-code-object` on the result. Entries 1..N-1 are nested lambdas reachable from the init, hoisted to the archive level in DFS reach-order.

The current archive uses ECE keyword-style symbols as field tags (`:version`, `:file`, `:entries`, `:name`, `:arity`, `:source-loc`, `:labels`, `:instructions`). Loaders still accept the legacy plain-symbol spelling (`ecec-archive`, `version`, `file`, ...) as a transition compatibility path, but new archives should use the colon-prefixed form emitted by the writer.

## Entry shape

```scheme
(:code-object
  :name         <symbol-or-#f>
  :arity        <(param-names . rest-flag)-or-#f>
  :source-loc   <(file line col)-or-#f>
  :labels       (<(label-sym . pc)> ...)
  :instructions (<instruction> ...))
```

- `name` is the procedure name if the code-object came from a `(define (name ...) ...)`; `#f` for anonymous lambdas and for the init entry.
- `arity` is `(param-names . rest-flag)` where `param-names` is a list of the declared parameter symbols and `rest-flag` is `#t` if the lambda uses a dotted rest parameter. `#f` when the code-object doesn't represent a procedure body (the init entry).
- `source-loc` is `(file line col)` or `#f` — populated by the reader when source-location tracking is enabled.
- `labels` is an alist mapping label symbols (usually `L<n>`) to zero-based PCs within this code-object's instruction vector.
- `instructions` is the raw instruction list in source form (symbolic `op` references, not pre-resolved function pointers). The loader rebuilds `resolved-instructions` on the fly — see "What isn't serialized" below.

## Nested code-object references

Lambdas inside a lambda compile bottom-up: the inner code-object becomes a constant operand of the outer's `make-compiled-procedure` instruction. On disk that constant is rewritten to a `co-ref`:

```
(assign val (op make-compiled-procedure) (const (co-ref 3)) (reg env))
```

The integer `3` is a zero-based index into the archive's `entries` list. At load time (`archive-sexp->code-objects`) the loader walks every instruction tree via `archive/patch-co-refs` and replaces each `(const (co-ref N))` with `(const <code-object-at-N>)`, pointing at the live struct it has already materialized from entry `N`. Two-pass load order: pass 1 creates all code-objects (metadata + labels), pass 2 pushes instructions with refs patched.

## What isn't serialized

- `resolved-instructions` are **not** on disk. Each `(op <name>)` reference in raw instructions gets converted to `(op-fn #'<fn>)` by `resolve-operations` at load time (via `%code-object-push-instruction!`). This decouples the archive format from primitive and op numbering — regenerating `primitives-auto.lisp` or renumbering ops does not break existing `.ecec` files.
- `native-fn` is **not** on disk. It's a runtime-only slot attached by `attach-archive-native-fns` after zone-file registrations complete (see below).

## Writer entry points

Both live in `src/compilation-unit.scm`:

- `compile-file-to-archive filename output-port` — compile every form in `filename`, wrap them in `(begin ...)`, run `mc-compile-to-code-object`, walk the resulting code-object tree via `archive/collect-reachable`, and write one `(:ecec-archive ...)` s-expression to `output-port` via `write-to-string-flat`.
- `compile-file-archive filename` — convenience wrapper that opens `<filename-minus-.scm>.ecec` and calls `compile-file-to-archive`.
- `code-object->archive-sexp top-co filename` — pure function: produce the archive s-expression from an already-compiled code-object.

`compile-system` (also in `compilation-unit.scm`) calls `compile-file-to-archive` per input file and concatenates the sections into `bootstrap.ecec`.

## Loader entry points

Two parallel implementations; both speak the same on-disk format:

- **CL side** (`src/runtime.lisp`):
  - `load-ecec-section stream &key skip` reads one section via the CL reader with a special readtable (keyword-preserving, case-sensitive) and dispatches to `load-ecec-archive-section` once it has confirmed the section starts with the `:ecec-archive` symbol. A non-archive head signals `"load-ecec-section: expected (:ecec-archive ...), got <head>. Run make bootstrap to regenerate."`.
  - `load-ecec-archive-section raw-archive` materializes every code-object, registers them in `*archive-code-objects*` under `(unit-id . co-key)`, calls `attach-archive-native-fns` to populate `code-object-native-fn` for entries with a registered zone fn, and finally executes the init code-object.
  - `load-ecec-file pathname &key skip` loops `load-ecec-section` until EOF.
- **ECE side** (`src/compilation-unit.scm`, running on the VM post-boot):
  - `load-section-from-port port` — single-section reader for REPL use.
  - `archive-sexp->code-objects archive` — parse + materialize + patch co-refs. Raises on version mismatch.
  - `load-archive-from-port port` / `load-archive filename` — full round-trip: read, materialize, execute init, return init result.

## Per-code-object zone files

Each code-object can optionally ship with a native-compiled "zone" — a CL `defun` that implements the code-object's dispatch loop as straight-line `tagbody`/`go` rather than the interpreter's fetch-decode-execute loop. Zones are generated by `generate-all-zones-from-archive!` in `src/codegen-cl-inline.scm`, one file per code-object, named `<file-stem>-<co-name-or-index>-zone.lisp`.

The pipeline:

1. `generate-all-zones-from-archive! archive-path output-dir` reads `bootstrap.ecec` section by section. For each section it calls `generate-zones-for-archive-section!`, which calls `archive-sexp->code-objects` to rebuild the code-object vector and then emits one zone file per entry.
2. Each zone file ends with a self-registration call of the form `(cl:setf (cl:gethash (cl:cons '<unit-id> <co-key>) *archive-zone-fns*) #'<zone-defun-name>)`. `<co-key>` is the code-object's zero-based archive index.
3. At boot the CL runtime loads zone files **before** `bootstrap.ecec`, so `*archive-zone-fns*` is fully populated by the time the archive loader runs. `attach-archive-native-fns cos unit-id` then looks up `(unit-id . co-key)` for every code-object and, when a zone fn is registered, sets `code-object-native-fn` to that fn.
4. The executor's compiled-zone fast-path reads `code-object-native-fn` directly on code-object entry. Missing native-fn (value `NIL`) falls through to the interpreter transparently.

## Regeneration

```
make bootstrap         # re-runs compile-system end-to-end (two-pass)
```

After any of the following, `make bootstrap` must be rerun:

- Changes to the archive format (this document), the writer, or the loader.
- Changes to primitive numbering or the op set — `resolved-instructions` is rebuilt at load time, so usually no regen needed, but regen is the safest response.
- Changes to instruction emission in the compiler or assembler.
- Changes to the zone codegen in `src/codegen-cl-inline.scm` — rerun `make bootstrap` so the per-code-object zone files match the archive.

If a fresh SBCL process fails to boot with "Unknown label" or "Unbound variable", suspect stale `.fasl-cache/` and rerun `make clean-fasl && make bootstrap`.
