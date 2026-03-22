### Requirement: JS handle table
The JS bridge SHALL maintain a handle table mapping i32 indices to JS values. Index 0 SHALL be reserved (represents null/undefined).

#### Scenario: Allocate handle
- **WHEN** a JS value is stored in the handle table
- **THEN** a unique i32 index is returned and the value is retrievable by that index

#### Scenario: Free handle
- **WHEN** a handle is released
- **THEN** the slot is available for reuse and the JS value can be garbage collected

### Requirement: WASM imports for FFI
The JS bridge SHALL provide 5 WASM imports under the `ffi` category: `eval`, `get`, `set`, `call`, and `callback`.

#### Scenario: ffi.eval import
- **WHEN** WASM calls `ffi.eval` with a string pointer and length
- **THEN** the JS bridge evaluates the string as JavaScript and returns a handle index

#### Scenario: ffi.call import
- **WHEN** WASM calls `ffi.call` with object handle, method string pointer/length, and args list handle
- **THEN** the JS bridge calls the method on the object with converted arguments and returns a handle to the result

### Requirement: Argument marshalling
The JS bridge SHALL convert ECE argument list values to JS values when processing `ffi.call`. Supported conversions: js-ref (pass through), fixnum/float (to JS number), ECE string (to JS string), ECE boolean (to JS boolean), nil (to JS null).

#### Scenario: Mixed argument types
- **WHEN** `ffi.call` is called with args list `(js-ref-1 42 "hello" #t '())`
- **THEN** the JS bridge passes `[jsObj, 42, "hello", true, null]` to the JS method

### Requirement: Callback wrapping
The `ffi.callback` import SHALL accept an ECE procedure handle, create a JS function that calls `call_ece_proc` with the procedure and any arguments (converted to js-refs), and return a handle to the JS function.

#### Scenario: Callback with JS arguments
- **WHEN** a JS event fires and the callback wrapper is invoked with a JS Event object
- **THEN** the Event object is stored in the JS handle table and passed to the ECE procedure as a js-ref

### Requirement: FFI primitives registered in buildGlobalEnv
The JS `buildGlobalEnv` function SHALL register all FFI primitives (IDs 210-221) in the global environment.

#### Scenario: FFI primitives available after bootstrap
- **WHEN** the sandbox boots and bootstrap completes
- **THEN** `%js-eval`, `%js-get`, `%js-set!`, `%js-call`, `%js-callback`, and all other FFI primitives are bound in the global environment
