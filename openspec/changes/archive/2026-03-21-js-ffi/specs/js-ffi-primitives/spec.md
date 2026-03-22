## ADDED Requirements

### Requirement: js-ref value type
The WASM runtime SHALL support a `$js-ref` value type that wraps an i32 index into the JS handle table. The type SHALL be distinguishable from all other ECE value types.

#### Scenario: js-ref? predicate
- **WHEN** `(%js-ref? val)` is called on a js-ref value
- **THEN** it returns `#t`

#### Scenario: js-ref? on non-js-ref
- **WHEN** `(%js-ref? 42)` is called on a number
- **THEN** it returns `#f`

### Requirement: %js-eval evaluates JavaScript
`%js-eval` (prim 210) SHALL accept an ECE string, evaluate it as JavaScript, and return a js-ref to the result.

#### Scenario: Evaluate to get document
- **WHEN** `(%js-eval "document")` is called
- **THEN** a js-ref pointing to the browser's document object is returned

#### Scenario: Evaluate expression
- **WHEN** `(%js-eval "1 + 2")` is called and the result is converted with `%js-ref->number`
- **THEN** the number `3` is returned

### Requirement: %js-get reads a property
`%js-get` (prim 211) SHALL accept a js-ref and an ECE string (property name), and return a js-ref to the property value.

#### Scenario: Get property
- **WHEN** `(%js-get document-ref "title")` is called
- **THEN** a js-ref pointing to the document's title string is returned

### Requirement: %js-set! writes a property
`%js-set!` (prim 212) SHALL accept a js-ref (object), an ECE string (property name), and a value (js-ref, number, string, or boolean), and set the property.

#### Scenario: Set property
- **WHEN** `(%js-set! element-ref "textContent" string-js-ref)` is called
- **THEN** the element's textContent is updated to the string value

### Requirement: %js-call calls a method
`%js-call` (prim 213) SHALL accept a js-ref (object), an ECE string (method name), and an ECE list of arguments. It SHALL call the method with the object as `this` and return a js-ref to the result.

#### Scenario: Call method with arguments
- **WHEN** `(%js-call document-ref "getElementById" (list (js-string "my-div")))` is called
- **THEN** a js-ref to the DOM element is returned

#### Scenario: Call method with no arguments
- **WHEN** `(%js-call ctx-ref "beginPath" '())` is called
- **THEN** the canvas context's beginPath is called

### Requirement: %js-callback wraps ECE procedure
`%js-callback` (prim 214) SHALL accept a compiled ECE procedure and return a js-ref to a JS function that, when called, invokes the ECE procedure via `call_ece_proc`.

#### Scenario: Register event handler
- **WHEN** `(%js-callback (lambda (e) (display "clicked")))` is called
- **THEN** a js-ref to a JS function is returned that can be passed to addEventListener

#### Scenario: Callback invocation
- **WHEN** the JS function from `%js-callback` is called by a DOM event
- **THEN** the ECE procedure is invoked with the event as a js-ref argument

### Requirement: %js-ref->number extracts a number
`%js-ref->number` (prim 215) SHALL accept a js-ref and return the JS value as an ECE number.

#### Scenario: Convert JS number
- **WHEN** `(%js-ref->number width-ref)` is called where width-ref points to a JS number 800
- **THEN** the ECE number `800` is returned

### Requirement: %js-ref->string extracts a string
`%js-ref->string` (prim 216) SHALL accept a js-ref and return the JS value as an ECE string.

#### Scenario: Convert JS string
- **WHEN** `(%js-ref->string title-ref)` is called where title-ref points to "Hello"
- **THEN** the ECE string `"Hello"` is returned

### Requirement: %js-number wraps a number as js-ref
`%js-number` (prim 217) SHALL accept an ECE number and return a js-ref to the corresponding JS number.

#### Scenario: Wrap fixnum
- **WHEN** `(%js-number 42)` is called
- **THEN** a js-ref pointing to JS number 42 is returned

#### Scenario: Wrap float
- **WHEN** `(%js-number 3.14)` is called
- **THEN** a js-ref pointing to JS number 3.14 is returned

### Requirement: %js-string wraps a string as js-ref
`%js-string` (prim 218) SHALL accept an ECE string and return a js-ref to the corresponding JS string.

#### Scenario: Wrap string
- **WHEN** `(%js-string "hello")` is called
- **THEN** a js-ref pointing to JS string "hello" is returned

### Requirement: %js-null? checks for null/undefined
`%js-null?` (prim 219) SHALL accept a js-ref and return `#t` if the JS value is null or undefined.

#### Scenario: Null check
- **WHEN** `(%js-null? ref)` is called where ref points to null
- **THEN** `#t` is returned

#### Scenario: Non-null check
- **WHEN** `(%js-null? ref)` is called where ref points to a DOM element
- **THEN** `#f` is returned

### Requirement: %js-release! frees a handle
`%js-release!` (prim 220) SHALL accept a js-ref and remove the JS value from the JS handle table, allowing it to be garbage collected.

#### Scenario: Release handle
- **WHEN** `(%js-release! ref)` is called
- **THEN** the JS handle table slot is freed and the js-ref becomes invalid

### Requirement: Primitives registered in primitives.def
All FFI primitives SHALL be registered in `primitives.def` with IDs 210-221, platform `browser`.

#### Scenario: Primitive IDs assigned
- **WHEN** `primitives.def` is read
- **THEN** IDs 210-221 are assigned to the FFI primitives (%js-eval through %js-ref?)
