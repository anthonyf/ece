## ADDED Requirements

### Requirement: Test files organized by category
The test suite SHALL consist of `.scm` files under `tests/ece/`, one per category, covering pure ECE language semantics.

#### Scenario: Test file structure
- **WHEN** a developer lists files in `tests/ece/`
- **THEN** there are separate test files for arithmetic, lists, strings, vectors, hash tables, control flow, closures, macros, TCO, call/cc, types, higher-order functions, records, errors, and parameters

### Requirement: Arithmetic tests
The test suite SHALL include tests for `+`, `-`, `*`, `/`, `modulo`, `abs`, `min`, `max`, and numeric comparisons.

#### Scenario: Basic arithmetic operations
- **WHEN** `test-arithmetic.scm` is loaded and tests are run
- **THEN** all arithmetic operations produce correct results

### Requirement: List operation tests
The test suite SHALL include tests for `cons`, `car`, `cdr`, `list`, `append`, `reverse`, `length`, `list-ref`, `list-tail`, `assoc`, and list predicates.

#### Scenario: Core list operations
- **WHEN** `test-lists.scm` is loaded and tests are run
- **THEN** all list construction, access, and manipulation operations produce correct results

### Requirement: String operation tests
The test suite SHALL include tests for string construction, `string-length`, `string-ref`, `substring`, `string-append`, string comparisons, and string interpolation.

#### Scenario: String operations
- **WHEN** `test-strings.scm` is loaded and tests are run
- **THEN** all string operations produce correct results

### Requirement: Vector operation tests
The test suite SHALL include tests for `make-vector`, `vector`, `vector-ref`, `vector-set!`, `vector-length`, and `vector->list`.

#### Scenario: Vector operations
- **WHEN** `test-vectors.scm` is loaded and tests are run
- **THEN** all vector operations produce correct results

### Requirement: Hash table operation tests
The test suite SHALL include tests for `make-hash-table`, `hash-table-ref`, `hash-table-set!`, `hash-table-delete!`, `hash-table-keys`, `hash-table-values`, and hash table literals.

#### Scenario: Hash table operations
- **WHEN** `test-hash-tables.scm` is loaded and tests are run
- **THEN** all hash table operations produce correct results

### Requirement: Control flow tests
The test suite SHALL include tests for `if`, `cond`, `case`, `and`, `or`, `when`, `unless`, and `do`.

#### Scenario: Control flow forms
- **WHEN** `test-control-flow.scm` is loaded and tests are run
- **THEN** all control flow forms evaluate correctly

### Requirement: Closure and binding tests
The test suite SHALL include tests for `lambda`, `let`, `let*`, `letrec`, named `let`, and closure capture.

#### Scenario: Closures and lexical binding
- **WHEN** `test-closures.scm` is loaded and tests are run
- **THEN** all binding forms and closures work correctly

### Requirement: Macro tests
The test suite SHALL include tests for `define-macro`, quasiquote expansion, and macro shadowing by lexical bindings.

#### Scenario: Macro expansion
- **WHEN** `test-macros.scm` is loaded and tests are run
- **THEN** all macro definitions and expansions work correctly

### Requirement: Tail call optimization tests
The test suite SHALL include tests verifying TCO across `if`, `begin`, `cond`, `and`, `or`, `when`, `unless`, `let`, `let*`, and named `let` at high iteration counts (at least 100,000).

#### Scenario: TCO does not overflow
- **WHEN** `test-tco.scm` is loaded and tests are run with 100,000+ iteration loops
- **THEN** all tail-call forms complete without stack overflow

### Requirement: Continuation tests
The test suite SHALL include tests for `call/cc` including non-local exit, coroutine patterns, and continuation invocation.

#### Scenario: call/cc operations
- **WHEN** `test-callcc.scm` is loaded and tests are run
- **THEN** all continuation operations work correctly

### Requirement: Type predicate tests
The test suite SHALL include tests for type predicates (`number?`, `string?`, `pair?`, `null?`, `boolean?`, `symbol?`, `vector?`, `procedure?`), equality operators (`eq?`, `eqv?`, `equal?`), and boolean operations.

#### Scenario: Type checks and equality
- **WHEN** `test-types.scm` is loaded and tests are run
- **THEN** all type predicates and equality operators return correct results

### Requirement: Higher-order function tests
The test suite SHALL include tests for `map`, `filter`, `reduce`, `for-each`, `compose`, `any`, and `every`.

#### Scenario: Higher-order functions
- **WHEN** `test-higher-order.scm` is loaded and tests are run
- **THEN** all higher-order functions produce correct results

### Requirement: Record tests
The test suite SHALL include tests for `define-record` including constructor, predicate, and accessor generation.

#### Scenario: Record operations
- **WHEN** `test-records.scm` is loaded and tests are run
- **THEN** record constructors, predicates, and accessors work correctly

### Requirement: Error handling tests
The test suite SHALL include tests for `error` signaling and `assert` behavior.

#### Scenario: Error operations
- **WHEN** `test-errors.scm` is loaded and tests are run
- **THEN** error signaling and assertion behavior work correctly

### Requirement: Parameter tests
The test suite SHALL include tests for `make-parameter` and `parameterize`.

#### Scenario: Dynamic parameters
- **WHEN** `test-parameters.scm` is loaded and tests are run
- **THEN** parameter creation and dynamic binding work correctly

### Requirement: Single entry point
The test suite SHALL provide `run-all.scm` that loads the test framework and all test files, then calls `run-tests`.

#### Scenario: Run entire suite
- **WHEN** `run-all.scm` is loaded in an ECE runtime
- **THEN** the framework is loaded, all test files are loaded, all tests are executed, and a summary is printed

### Requirement: Makefile integration
A `make test-ece` target SHALL load the ECE system and evaluate `(load "tests/ece/run-all.scm")` in ECE.

#### Scenario: Run via make
- **WHEN** `make test-ece` is executed
- **THEN** the ECE runtime is bootstrapped, all ECE-native tests are run, and the process exits with code 0 on success or 1 on failure
