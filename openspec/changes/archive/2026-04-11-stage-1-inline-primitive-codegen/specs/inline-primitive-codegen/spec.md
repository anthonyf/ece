## ADDED Requirements

### Requirement: Per-space inline codegen entry point

ECE SHALL provide `src/codegen-cl-inline.scm`, an ECE program that takes a compilation space's symbol ID and writes a CL source file containing one `(defun zone-NAME ...)` whose body is the inlined translation of that space's instruction vector. The codegen SHALL reuse `*host-primitives*` and the template expander from `src/codegen-cl.scm` for primitive call sites.

#### Scenario: Generate compiled zone for a space
- **WHEN** the codegen is invoked with a space symbol that has a populated instruction vector
- **THEN** it SHALL produce a CL file containing exactly one `(defun zone-<spacename> ...)` form
- **AND** the function's lambda list SHALL be `(initial-pc initial-val initial-env initial-proc initial-argl initial-continue initial-stack)`
- **AND** the function body SHALL be a `tagbody` whose tags correspond to the instruction PCs
- **AND** the function SHALL return `(values pc val env proc argl continue stack)` on zone exit

#### Scenario: Unknown space
- **WHEN** the codegen is invoked with a space symbol that does not exist in the space registry
- **THEN** it SHALL signal an error naming the missing space
- **AND** it SHALL NOT write any output file

#### Scenario: Empty space
- **WHEN** the codegen is invoked with a space whose instruction vector has zero entries
- **THEN** it SHALL emit a `defun` with an empty `tagbody` body that returns the initial register state unchanged

### Requirement: Inline primitive substitution

When the codegen encounters an instruction that calls a statically-known primitive, it SHALL substitute the primitive's `:cl` template body inline at the call site instead of emitting a `funcall` against the dispatch table.

#### Scenario: Statically-known primitive call
- **WHEN** the instruction stream contains `(assign proc (const (primitive ID)))` followed by argument construction and a `(perform (op-fn #'apply-primitive-procedure) ...)` call
- **AND** ID resolves to a primitive whose `:cl` template is registered in `*host-primitives*`
- **THEN** the codegen SHALL emit the expanded template body at the call site
- **AND** the parameters in the template body SHALL be bound to the corresponding registers / arg-list slots

#### Scenario: Dynamically-resolved primitive call
- **WHEN** the instruction stream calls `apply-primitive-procedure` against a primitive whose identity cannot be statically determined (e.g., the proc register holds a value computed at runtime)
- **THEN** the codegen SHALL fall back to emitting `(funcall #'ece-NAME args...)` against the auto-generated defun in `bootstrap/primitives-auto.lisp`

#### Scenario: Operation call sites
- **WHEN** the instruction stream contains an operation call `(perform (op-fn FN) ...)` whose operation name resolves via `*operation-name-to-id*`
- **THEN** the codegen SHALL emit a direct CL call to the operation's underlying CL function

#### Scenario: ECE-platform primitive
- **WHEN** the call site targets an ECE-platform primitive (one defined in `src/prelude.scm` rather than templated in `src/primitives.scm`)
- **THEN** the codegen SHALL emit a `lookup-variable-value` against `*global-env*` followed by an `apply-ece-procedure` call
- **AND** SHALL NOT attempt to inline the body

### Requirement: Compiled-zone runtime hook

`execute-instructions` SHALL check for a registered compiled-zone function for the target space at entry. When one is registered, it SHALL invoke the compiled-zone function with the current register state and resume from its returned state. When none is registered, it SHALL run the existing dispatch loop unchanged.

#### Scenario: Space with compiled zone
- **WHEN** `execute-instructions` is called with a `space-id` that has a registered compiled-zone function
- **THEN** the function SHALL be invoked with the current register state
- **AND** its return values SHALL be used to update the executor's register state
- **AND** the existing dispatch loop SHALL NOT execute for any instruction in that space

#### Scenario: Space without compiled zone
- **WHEN** `execute-instructions` is called with a `space-id` that has no registered compiled-zone function
- **THEN** the executor SHALL run the existing dispatch loop unchanged
- **AND** no compiled-zone code SHALL be invoked

#### Scenario: Cross-space jump from compiled to interpreted
- **WHEN** a compiled-zone function returns because `continue` (or a `goto`) targets a space that has no registered compiled-zone function
- **THEN** `execute-instructions` SHALL pick up the returned register state and run the dispatch loop on the target space

#### Scenario: Cross-space jump from interpreted to compiled
- **WHEN** the dispatch loop encounters a `goto` to a space that has a registered compiled-zone function
- **THEN** the executor SHALL invoke the compiled-zone function with the current register state instead of continuing the dispatch loop on the target space

### Requirement: Cross-zone REPL function redefinition

A procedure redefined at the REPL via `(define foo ...)` SHALL be visible to subsequent calls from BOTH the interpreted zone AND any compiled zone, without recompilation.

#### Scenario: Redefine an ECE procedure called from compiled code
- **WHEN** a compiled-zone function calls an ECE procedure `foo` looked up via `*global-env*`
- **AND** the user redefines `foo` at the REPL after the compiled-zone file was loaded
- **THEN** the next call from the compiled-zone function SHALL invoke the new `foo`
- **AND** the compiled-zone file SHALL NOT need to be regenerated

### Requirement: Continuation parity across zones

A continuation captured inside the compiled zone SHALL be resumable by the interpreter, and a continuation captured by the interpreter SHALL be resumable by the compiled zone, with identical observable behavior.

#### Scenario: call/cc captured in compiled zone, resumed in interpreter
- **WHEN** a compiled-zone function captures a continuation
- **AND** the continuation is invoked from interpreted code
- **THEN** execution SHALL resume in the interpreter at the captured PC
- **AND** the register state SHALL match what the compiled zone snapshotted

#### Scenario: call/cc captured in interpreter, resumed in compiled zone
- **WHEN** the interpreter captures a continuation in a space that is later compiled
- **AND** the continuation is invoked
- **THEN** execution SHALL resume via the compiled-zone function with the captured register state

#### Scenario: dynamic-wind across the boundary
- **WHEN** a compiled-zone function enters a `dynamic-wind` whose body invokes interpreted code
- **AND** the body returns normally
- **THEN** the after-thunk SHALL be invoked in whichever zone owns its space
- **AND** `*winding-stack*` SHALL be consistent at every transition

### Requirement: Build integration

The Makefile SHALL provide a target that regenerates the compiled-zone files for any space registered for compilation. The generated files SHALL be checked in alongside `bootstrap/primitives-auto.lisp`.

#### Scenario: Regenerate compiled zone
- **WHEN** any of `src/codegen-cl-inline.scm`, `src/codegen-cl.scm`, `src/primitives.scm`, or the source `.scm` file for the chosen space changes
- **THEN** `make bootstrap` SHALL regenerate the corresponding `bootstrap/<space>-zone.lisp` file

#### Scenario: Idempotent regeneration
- **WHEN** the codegen is run twice with unchanged inputs
- **THEN** the second run SHALL produce a byte-identical compiled-zone file

#### Scenario: Rollback
- **WHEN** a regenerated compiled-zone file is broken
- **THEN** `git checkout bootstrap/<space>-zone.lisp` SHALL restore the previous working version
- **AND** the runtime SHALL load that file at boot without further changes

### Requirement: Runtime loads compiled-zone files

`src/runtime.lisp` SHALL load every `bootstrap/*-zone.lisp` file present at boot time, after `bootstrap/primitives-auto.lisp` and before `(boot-from-compiled)` runs. Each loaded file SHALL register its compiled-zone function in `*compiled-zone-functions*`.

#### Scenario: Compiled zone present
- **WHEN** a `bootstrap/<space>-zone.lisp` file exists
- **THEN** the runtime SHALL load it during boot
- **AND** the file's load-time effects SHALL register `(zone-<space>)` under the space's symbol in `*compiled-zone-functions*`

#### Scenario: Compiled zone absent
- **WHEN** no `bootstrap/*-zone.lisp` files exist
- **THEN** the runtime SHALL boot exactly as before, with all spaces interpreted

#### Scenario: Compiled zone is corrupt or incompatible
- **WHEN** loading a `bootstrap/*-zone.lisp` file fails
- **THEN** the runtime SHALL signal a clear error pointing at `make bootstrap` for regeneration
- **AND** SHALL NOT silently fall back to interpreted mode

### Requirement: Test parity between zones

Every test in the project's existing test suites that exercises a space chosen for compilation SHALL pass identically against both the interpreted and compiled implementations of that space.

#### Scenario: Test parity harness
- **WHEN** the parity test harness is run against a chosen space
- **THEN** it SHALL execute every test program against the interpreted version of the space first
- **AND** then against the compiled-zone version of the same space
- **AND** SHALL report failure if any test produces different output, register state, or thrown errors between the two runs

#### Scenario: Existing test suites stay green
- **WHEN** a compiled-zone file is checked in for the chosen space
- **AND** the existing test suites (rove, ECE self-hosted, conformance, WASM) are run
- **THEN** every test SHALL pass with zero failures
- **AND** no test SHALL require modification to accommodate the compiled zone
