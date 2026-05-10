# ECE VM Specification

This document specifies the ECE register-machine VM as implemented by the Common
Lisp runtime in [`src/runtime.lisp`](../../src/runtime.lisp) and the WebAssembly
runtime in [`wasm/runtime.wat`](../../wasm/runtime.wat).

ECE code is compiled to a small symbolic instruction language inspired by SICP
5.5. `.ecec` archives store those symbolic instructions as ECE data. The CL
runtime executes resolved instruction lists directly. The WASM runtime decodes
the same instruction language into compact `$instr` records with numeric
opcodes.

## Execution Model

Execution happens inside one current code object and one current program
counter. A code object owns:

- an instruction vector;
- a local label table mapping label symbols to PCs;
- optional procedure metadata such as name, arity, and source location;
- optional archive identity, used by save/restore and native-zone lookup;
- optional native-zone entry points.

The executor fetches the instruction at `pc`, performs it, then increments `pc`
unless the instruction explicitly jumps, halts, or exits through a native-zone
protocol. If `pc` reaches the length of the current code object, execution
returns the value in `val`.

The current code object is part of the VM state even though it is not an
ECE-visible register. Cross-procedure jumps replace the current code object and
continue at the target code object's local PC.

## Registers

The VM has six ECE-visible registers plus one internal flag.

| Register | WASM ID | Meaning |
| --- | ---: | --- |
| `val` | 0 | Most recent expression or operation result. Function results are returned through this register. |
| `env` | 1 | Current lexical environment chain. Compiled procedures install their captured environment here before extending it with arguments. |
| `proc` | 2 | Procedure being applied. It can hold a primitive, compiled procedure, continuation, parameter, or other value while dispatch checks run. |
| `argl` | 3 | Argument list for the procedure in `proc`. Arguments are ordinary ECE list values. |
| `continue` | 4 | Return address for compiled code. In the code-object model, label assignments to `continue` store a qualified address `(code-object . pc)`. |
| `stack` | 5 | Explicit VM stack used by `save`, `restore`, continuations, and generated compiler sequences. |
| `flag` | n/a | Internal boolean used by `test` and `branch`. It is not addressable by source instructions. |

The CL runtime stores the stack as a CL list. The WASM runtime stores it as an
ECE list. In both runtimes, `save` conses onto the front and `restore` pops from
the front.

## Operands

Instruction operands have one of three source-level forms:

| Operand | Meaning |
| --- | --- |
| `(const value)` | The literal ECE value `value`. In archive files, nested code-object constants are stored as `(co-ref index)` and patched back during load. |
| `(reg name)` | The current value of VM register `name`. |
| `(label name)` | The local PC for `name` in the current code object's label table. When assigned to `continue`, the runtime stores `(current-code-object . pc)` instead of a bare PC. |

Operation operands are evaluated left to right by reading these operand forms
before invoking the operation.

## Instruction Set

The source instruction language has eight executable forms:

```scheme
(assign <register> <source> <operand> ...)
(test (op <operation>) <operand> ...)
(branch (label <label>))
(goto <destination>)
(save <register>)
(restore <register>)
(perform (op <operation>) <operand> ...)
(halt)
```

The compiler and archive writer use symbolic instruction names. WASM decodes
them to the numeric opcodes below.

| Opcode | Instruction | Primary effect | Normal PC behavior |
| ---: | --- | --- | --- |
| 0 | `assign` | Stores a value in a register. | Increment by 1, unless an operation bridges to ECE `error`. |
| 1 | `test` | Calls an operation and stores truthiness in `flag`. | Increment by 1. |
| 2 | `branch` | If `flag` is true, jumps to a label PC. | Jump when true, otherwise increment by 1. |
| 3 | `goto` | Unconditional jump to a label or address stored in a register. | Jump; no automatic increment. |
| 4 | `save` | Pushes a register value onto `stack`. | Increment by 1. |
| 5 | `restore` | Pops `stack` into a register. | Increment by 1. |
| 6 | `perform` | Calls an operation for side effects and discards its result. | Increment by 1. |
| 7 | `halt` | Ends execution of the current code object. | Exit executor and return `val`. |

### `assign`

```scheme
(assign <target> (const <value>))
(assign <target> (reg <source-register>))
(assign <target> (label <label>))
(assign <target> (op <operation>) <operand> ...)
```

`assign` computes a source value and writes it to the target register.

- `(const value)` writes `value`.
- `(reg source-register)` copies the source register's current value.
- `(label label)` resolves `label` in the current code object. If the target is
  `continue`, the stored value is `(current-code-object . pc)`; otherwise it is
  the bare local PC.
- `(op operation)` evaluates its operands and calls the named machine
  operation, then stores the result.

The CL runtime may pre-resolve `(op name)` to an internal `(op-fn function)` form
inside `resolved-instructions`; this is an implementation optimization, not a
source instruction form.

If an operation returns an error sentinel, both runtimes try to look up the ECE
`error` procedure, put the sentinel message and irritants into `argl`, put the
procedure into `proc`, switch to the error procedure's code object, and continue
there. In the current CL executor, this sentinel bridge exists on the `assign`
operation path. In the WASM executor, the bridge also exists for `test` and
`perform`.

### `test`

```scheme
(test (op <operation>) <operand> ...)
```

`test` evaluates operands, calls the operation, and sets `flag` from the
operation result. Generated code uses predicate-style machine operations here,
such as `false?`, `primitive-procedure?`, `continuation?`, and `parameter?`.
In CL these predicates return host booleans. In WASM, the flag is true unless
the operation result is Scheme `#f`.

The current CL executor does not bridge error sentinels from `test`; generated
code uses predicate operations that should not produce sentinels. The WASM
executor does bridge a sentinel result from `test` to ECE `error`.

### `branch`

```scheme
(branch (label <label>))
```

`branch` reads `flag`. If `flag` is true, it sets `pc` to the target label's
local PC in the current code object. If `flag` is false, execution falls through
to the next instruction.

`branch` is always local to the current code object. Cross-code-object control
flow goes through `goto`.

### `goto`

```scheme
(goto (label <label>))
(goto (reg <register>))
```

`goto` transfers control without an automatic PC increment.

`(goto (label label))` jumps to a local label in the current code object.

`(goto (reg register))` reads an address-like value from a register:

- a code object means PC 0 of that code object;
- `(code-object . pc)` means the qualified PC in that code object;
- a bare integer/fixnum means that PC in the current code object;
- the CL runtime also accepts a symbol as a local label name.

Compiled procedure entries and continuation return addresses use this form.
Tail calls are ordinary `goto` instructions to the callee entry, which is why
tail calls do not grow the host language stack.

### `save`

```scheme
(save <register>)
```

`save` pushes the current value of a register onto the explicit VM stack.
Compiler-generated preserving sequences use `save` before code that may clobber
a needed register.

### `restore`

```scheme
(restore <register>)
```

`restore` pops the top value from the explicit VM stack and writes it to the
target register. The VM assumes compiler-generated save/restore balancing; a
malformed instruction stream can underflow the stack.

### `perform`

```scheme
(perform (op <operation>) <operand> ...)
```

`perform` evaluates operands and calls a machine operation, discarding the
ordinary result. It is used for effects such as mutation, definition, and
continuation winding.

The current CL executor discards the operation result without checking for an
error sentinel. The WASM executor bridges a sentinel result from `perform` to
ECE `error`.

### `halt`

```scheme
(halt)
```

`halt` exits the executor and returns the current `val`. The compiler appends
`halt` to top-level code objects produced by `mc-compile-to-code-object`.

## WASM Instruction Encoding

WASM stores each decoded instruction as:

```wat
(type $instr (struct
  (field $opcode i32)
  (field $a i32)
  (field $b i32)
  (field $c i32)
  (field $val (ref null eq))))
```

The fields are interpreted by opcode:

| Opcode | `$a` | `$b` | `$c` | `$val` |
| ---: | --- | --- | --- | --- |
| 0 `assign` | target register ID | source type | source register, label PC, or operation ID | constant value or operand list |
| 1 `test` | unused | unused | operation ID | operand list |
| 2 `branch` | unused | unused | target label PC | unused |
| 3 `goto` | unused | destination type | target label PC or register ID | unused |
| 4 `save` | register ID | unused | unused | unused |
| 5 `restore` | register ID | unused | unused | unused |
| 6 `perform` | unused | unused | operation ID | operand list |
| 7 `halt` | unused | unused | unused | unused |

Source type IDs for `assign` are:

| ID | Source |
| ---: | --- |
| 0 | `const` |
| 1 | `reg` |
| 2 | `label` |
| 3 | `op` |

Destination type IDs for `goto` are:

| ID | Destination |
| ---: | --- |
| 0 | `label` |
| 1 | `reg` |

WASM operation IDs are the stable IDs from [`operations.def`](../../operations.def).
The JavaScript glue initializes a symbol-ID table so the WAT archive loader can
map symbolic instruction and operation names to these numeric IDs.

## Machine Operations

Machine operations are internal VM helpers invoked by `assign`, `test`, and
`perform` through `(op name)`. They are not user-facing primitives. Their stable
IDs are declared in [`operations.def`](../../operations.def), and runtimes must
implement every listed operation.

| ID | Operation | Arity | Behavior |
| ---: | --- | ---: | --- |
| 0 | `lookup-variable-value` | 2 | Look up a variable by name in an environment chain. |
| 1 | `lookup-global-variable` | 1 | Look up a variable in the global environment only. |
| 2 | `set-variable-value!` | 3 | Mutate an existing named binding in an environment. |
| 3 | `define-variable!` | 3 | Define or redefine a binding in the first/global hash frame. |
| 4 | `extend-environment` | variadic | Create a new lexical frame from parameter names and argument values, optionally with extra slots for internal definitions. |
| 5 | `lexical-ref` | 3 | Read a lexical variable by depth and offset. |
| 6 | `lexical-set!` | 4 | Mutate a lexical variable by depth and offset. |
| 7 | `make-compiled-procedure` | 2 | Create a compiled procedure from an entry code object/address and captured environment. |
| 8 | `compiled-procedure-entry` | 1 | Return a compiled procedure's entry code object/address. |
| 9 | `compiled-procedure-env` | 1 | Return a compiled procedure's captured environment. |
| 10 | `primitive-procedure?` | 1 | Test whether a value is a primitive procedure. |
| 11 | `continuation?` | 1 | Test whether a value is a continuation. |
| 12 | `parameter?` | 1 | Test whether a value is a parameter object. |
| 13 | `apply-primitive-procedure` | 2 | Apply a primitive procedure to an argument list. |
| 14 | `apply-parameter` | 2 | Apply a parameter object: read with no arguments or set with arguments. |
| 15 | `parameter-ref` | 1 | Return a parameter's current value. |
| 16 | `parameter-set!` | 2 | Set a parameter through the guarded path. |
| 17 | `parameter-raw-set!` | 2 | Set a parameter without guard conversion. |
| 18 | `capture-continuation` | 2 | Capture the VM stack, continue register, and current winding stack. |
| 19 | `do-continuation-winds` | 1 | Run `dynamic-wind` before/after thunks needed for a continuation transition. |
| 20 | `continuation-stack` | 1 | Return the saved stack from a continuation. |
| 21 | `continuation-conts` | 1 | Return the saved continue register from a continuation. |
| 22 | `false?` | 1 | Return true exactly when the value is Scheme `#f`. |
| 23 | `list` | variadic | Construct an ECE list from evaluated operands. |
| 24 | `cons` | 2 | Construct a pair. |
| 25 | `car` | 1 | Return the first field of a pair. |
| 26 | `cdr` | 1 | Return the second field of a pair. |

User-visible primitives are a separate numbering space declared in
[`primitives.def`](../../primitives.def).

## Procedure Calls

The compiler lowers calls into register-machine instructions:

1. Evaluate the operator into `proc`.
2. Evaluate operands into `argl`.
3. Test `proc` against the callable categories:
   `primitive-procedure?`, `continuation?`, `parameter?`, otherwise compiled
   procedure.
4. Dispatch:
   - primitive: `(assign val (op apply-primitive-procedure) (reg proc) (reg argl))`;
   - parameter: `(assign val (op apply-parameter) (reg proc) (reg argl))`;
   - continuation: restore continuation state and `goto` its saved `continue`;
   - compiled procedure: load its entry/environment and `goto` the entry.

For a compiled procedure call, `compiled-procedure-env` installs the captured
environment, `extend-environment` adds a new frame for parameters, and execution
jumps to the procedure entry. Tail-position calls reuse the caller's
`continue`, so they do not add an extra return trampoline.

## Continuations

`capture-continuation` records:

- a copy of the explicit VM stack;
- the current `continue` address;
- the current `dynamic-wind` stack.

Invoking a continuation:

1. puts the resume value in `val`;
2. runs `do-continuation-winds` to transition from the current winding stack to
   the continuation's saved winding stack;
3. replaces `stack` with the saved stack;
4. replaces `continue` with the saved continue address;
5. performs `(goto (reg continue))`.

Because the stack and continuation address are ECE-managed values, they can be
serialized by the save/restore layer when all referenced values are serializable.

## Native Zones

Native zones are optional accelerators for code objects. They must preserve the
same register-machine semantics.

The CL runtime checks a code object's `native-fn` when entering a code object.
The function receives `(pc val env proc argl continue stack)` and returns updated
values for the same state.

The WASM runtime checks the native-zone registry at PC 0 for archive-registered
code objects. A native zone returns a vector:

```scheme
#(mode pc val env proc argl continue stack)
```

Modes are:

| Mode | Meaning |
| ---: | --- |
| 0 | Return immediately with `val`. |
| 1 | Continue with the returned registers and PC. |
| 2 | Bail out to the interpreter with the returned registers and PC. |

Unsupported code objects simply run through the interpreter.

## Source References

- Compiler instruction generation: [`src/compiler.scm`](../../src/compiler.scm)
- Assembler: [`src/assembler.scm`](../../src/assembler.scm)
- CL executor: [`src/runtime.lisp`](../../src/runtime.lisp)
- WASM executor and opcode encoding: [`wasm/runtime.wat`](../../wasm/runtime.wat)
- Operation manifest: [`operations.def`](../../operations.def)
- Archive writer/reader: [`src/compilation-unit.scm`](../../src/compilation-unit.scm)
