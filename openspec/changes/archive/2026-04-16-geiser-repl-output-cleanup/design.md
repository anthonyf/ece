## Context

ECE's `--geiser` REPL mode wraps all output in `((result "...") (output . "..."))` alists for the wire protocol. Geiser's `C-x C-e` parses these correctly, but the REPL buffer (a comint buffer) displays the raw text. Other Geiser backends handle this by having the Scheme-side print clean output to the REPL and only use the alist format for programmatic responses, but ECE's architecture uses a single output channel.

## Goals / Non-Goals

**Goals:**

- REPL buffer shows clean results: `3` not `((result "3") (output . ""))`.
- Side-effect output from `display`/`write` appears before the result.
- Error responses show the error message clearly.

**Non-Goals:**

- Changing the wire protocol — the alist format stays for programmatic consumers.
- Syntax highlighting of results.
- Pretty-printing of large structures.

## Decisions

### Decision 1: Comint output filter in elisp

**Choice:** Add a `comint-preoutput-filter-functions` entry in the REPL buffer that parses alist responses and reformats them.

**Rationale:** This is the standard comint mechanism for transforming process output before display. It doesn't interfere with Geiser's own output parsing (which happens through a different channel). The filter only runs in the REPL buffer, not during programmatic eval.

### Decision 2: Filter format

**Choice:** For `((result "val") (output . "captured"))`:
- If `output` is non-empty, display it first (no decoration)
- Then display the result value (read from the string, re-printed cleanly)
- If result is empty string, display nothing (void return)

**Rationale:** Matches the behavior of a normal Scheme REPL. Side effects appear in order, result appears last.

## Risks / Trade-offs

- **[Risk] Regex fragility.** The filter needs to recognize alist responses vs. other output. A malformed response could slip through. Mitigation: use `read-from-string` to parse, fall back to raw display on parse failure.
- **[Trade-off] Result re-printing.** The result is a string representation from ECE's `write-to-string-flat`. We display it as-is (not re-formatted by elisp). This means ECE's print conventions are preserved.
