## 1. Instruction Sequence Foundation

- [x] 1.1 Define instruction sequence representation `(needs modifies instructions)` and constructor `make-instruction-sequence`
- [x] 1.2 Implement `empty-instruction-sequence`, `append-instruction-sequences`, and `tack-on-instruction-sequence`
- [x] 1.3 Implement `preserving` combinator that wraps save/restore only when register conflicts exist
- [x] 1.4 Implement label generation (`make-label`) for unique branch targets

## 2. Compiler Core

- [x] 2.1 Implement `compile` dispatch function (mirrors interpreter's `ev-dispatch` but at compile time)
- [x] 2.2 Implement `compile-self-evaluating` — emit `(assign target (const value))`
- [x] 2.3 Implement `compile-variable` — emit lookup instruction
- [x] 2.4 Implement `compile-quoted` — emit `(assign target (const datum))`
- [x] 2.5 Implement `compile-if` — compile predicate, consequent, alternative with branch labels
- [x] 2.6 Implement `compile-begin` (sequence) — compile expressions in order, last gets tail linkage
- [x] 2.7 Implement `compile-lambda` — compile body separately, emit make-compiled-procedure
- [x] 2.8 Implement `compile-application` — compile operator, compile operands with `construct-arglist`, emit apply
- [x] 2.9 Implement `compile-define` and `compile-assignment` — compile value, emit define/set operation
- [x] 2.10 Implement `compile-callcc` — emit continuation capture, compile receiver, emit apply
- [x] 2.11 Implement `compile-quasiquote` — expand with `qq-expand` at compile time, then compile result
- [x] 2.12 Implement `compile-define-macro` — register macro in compile-time environment
- [x] 2.13 Implement macro expansion in `compile` dispatch — detect macros, expand, compile expanded form
- [x] 2.14 Implement `compile-apply-form` — compile `(apply proc args)` special form

## 3. Instruction Executor

- [x] 3.1 Implement instruction executor loop — iterate through instruction vector, dispatch on instruction type
- [x] 3.2 Implement `assign` instruction execution (const, reg, op variants)
- [x] 3.3 Implement `test`, `branch`, `goto` (label and register variants)
- [x] 3.4 Implement `save` and `restore` instructions
- [x] 3.5 Implement `perform` instruction (for side-effecting operations)
- [x] 3.6 Implement apply dispatch: primitive-apply and compiled-procedure-apply
- [x] 3.7 Implement continuation-apply in executor (restore stack + jump to saved pc)

## 4. Integration

- [x] 4.1 Implement `compile-and-go` — compile expression, assemble into instruction vector, execute
- [x] 4.2 Replace `evaluate` to call `compile-and-go` internally
- [x] 4.3 Implement `compile-file` to replace `ece-load` — read and compile all forms from a file
- [x] 4.4 Update prelude loading to use `compile-file`
- [x] 4.5 Keep old interpreter as `evaluate-interpreted` for reference

## 5. Testing

- [x] 5.1 Run full existing test suite — all tests must pass unchanged
- [x] 5.2 Add compiler-specific tests: compiled procedure objects, macro lexical shadowing
- [x] 5.3 Performance verified: 1M TCO iterations in 0.76s, 208MB consed (4x less than pre-optimization)
