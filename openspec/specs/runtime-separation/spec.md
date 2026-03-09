## ADDED Requirements

### Requirement: Runtime is independently loadable

The runtime (`src/runtime.lisp`) SHALL be loadable without the compiler. It MUST contain all code necessary to execute pre-assembled instruction vectors, including the executor, environment operations, primitive registration, and global state.

#### Scenario: Runtime loads without compiler
- **WHEN** `src/runtime.lisp` is loaded in isolation (without `src/compiler.lisp`)
- **THEN** the package is defined, primitives are registered, and `execute-instructions` is available

### Requirement: Compiler depends on runtime

The compiler (`src/compiler.lisp`) SHALL depend on the runtime. It MUST NOT duplicate any runtime code. Loading the compiler after the runtime MUST provide the full ECE system (compile + execute).

#### Scenario: Full system loads with both files
- **WHEN** `src/runtime.lisp` is loaded followed by `src/compiler.lisp`
- **THEN** `evaluate`, `compile-and-go`, `repl`, and all exports work identically to the current monolithic `ece.lisp`

### Requirement: Runtime has no compiler dependencies

The runtime SHALL NOT reference `evaluate`, `compile-and-go`, `ece-compile`, or any compile-time function. Primitives that require the compiler (`ece-try-eval`, `ece-load`) SHALL be registered in the compiler file.

#### Scenario: Runtime contains no compiler references
- **WHEN** the runtime source is inspected
- **THEN** it contains no calls to `evaluate`, `compile-and-go`, `ece-compile`, `compile-file-ece`, or any `compile-*` function

### Requirement: All tests pass unchanged

Splitting the file SHALL NOT change any observable behavior. All existing tests MUST pass without modification.

#### Scenario: Full test suite passes
- **WHEN** the test suite is run after the split
- **THEN** every test passes with the same results as before
