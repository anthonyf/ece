## ADDED Requirements

### Requirement: codegen translates instruction vector to CL source
The codegen tool SHALL read the global instruction vector and emit a CL `defun` containing a `tagbody` form with one label per PC. Each instruction SHALL be translated to direct CL register operations without a dispatch loop.

#### Scenario: Assign constant
- **WHEN** the instruction vector contains `(assign val (const 42))` at PC 5
- **THEN** the generated CL code SHALL contain a label `L5` followed by `(setf val 42)`

#### Scenario: Assign from register
- **WHEN** the instruction vector contains `(assign proc (reg val))` at PC 10
- **THEN** the generated CL code SHALL contain `(setf proc val)` at label `L10`

#### Scenario: Assign from operation
- **WHEN** the instruction vector contains `(assign val (op-fn #'func) (reg env) (const x))` at PC 20
- **THEN** the generated CL code SHALL contain a `funcall` to the operation function with the operands inlined as direct variable references or constants

#### Scenario: Assign from label
- **WHEN** the instruction vector contains `(assign continue (label L42))` at PC 7
- **THEN** the generated CL code SHALL contain `(setf continue 42)` at label `L7` (the label resolved to its numeric PC)

### Requirement: codegen translates control flow instructions
The codegen SHALL translate `test`, `branch`, `goto`, `save`, `restore`, and `perform` instructions to equivalent CL code.

#### Scenario: Test and branch
- **WHEN** the instruction vector contains `(test (op-fn #'false?) (reg val))` at PC 30 followed by `(branch (label L35))` at PC 31
- **THEN** the generated CL code SHALL set a `flag` variable from the test, and the branch SHALL emit `(when flag (go L35))`

#### Scenario: Goto label
- **WHEN** the instruction vector contains `(goto (label L50))` at PC 40
- **THEN** the generated CL code SHALL emit `(go L50)` at label `L40`

#### Scenario: Goto register — in-zone
- **WHEN** the instruction vector contains `(goto (reg continue))` at PC 45
- **AND** the `continue` register holds a PC within the compiled zone
- **THEN** the generated CL code SHALL dispatch to the target label within the same `tagbody`

#### Scenario: Goto register — cross-zone exit
- **WHEN** the instruction vector contains `(goto (reg continue))` at PC 45
- **AND** the `continue` register holds a PC outside the compiled zone
- **THEN** the generated CL code SHALL return all register values to the outer dual-zone executor

#### Scenario: Save and restore
- **WHEN** the instruction vector contains `(save env)` at PC 60 and `(restore env)` at PC 65
- **THEN** the generated CL code SHALL emit `(push env stack)` and `(setf env (pop stack))` respectively

#### Scenario: Perform
- **WHEN** the instruction vector contains `(perform (op-fn #'func) (reg val) (reg argl))` at PC 70
- **THEN** the generated CL code SHALL emit a `funcall` for side effects without assigning the result

### Requirement: codegen references operations via table
The codegen SHALL NOT embed CL function objects as source literals. It SHALL reference operations via an index into an operation table that is populated at load time.

#### Scenario: Operation table reference
- **WHEN** the instruction at PC 20 uses `(op-fn #'lookup-variable-value)`
- **THEN** the generated CL code SHALL reference the function via `(aref *op-table* N)` where N is the operation's index in the table

#### Scenario: Operation table populated at load time
- **WHEN** the generated CL file is loaded
- **THEN** the operation table SHALL be populated from the instruction vector's pre-resolved `op-fn` entries

### Requirement: codegen supports entry dispatch
The generated function SHALL accept a starting PC and jump to the corresponding label. This dispatch occurs once per zone entry, not per instruction.

#### Scenario: Entry at arbitrary PC
- **WHEN** the compiled zone function is called with `pc=500`
- **THEN** execution SHALL begin at label `L500` within the `tagbody`

### Requirement: codegen is written in ECE
The codegen tool SHALL be implemented as an ECE source file (`codegen-cl.scm`) loaded into the ECE image.

#### Scenario: Codegen invocation
- **WHEN** the user calls `(codegen-cl)` or equivalent from the ECE REPL
- **THEN** the tool SHALL read the current global instruction vector and emit a CL source file containing the compiled zone function

### Requirement: codegen emits loadable CL source
The generated CL file SHALL be valid CL source that can be compiled and loaded by SBCL.

#### Scenario: Load generated file
- **WHEN** the generated CL file is loaded via `(load "compiled-zone.lisp")`
- **THEN** SBCL SHALL compile and load it without errors
- **AND** the compiled zone function SHALL be available for the dual-zone executor
