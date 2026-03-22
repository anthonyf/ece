### Requirement: js-call with rest args
`browser-lib.scm` SHALL define `(js-call obj method . args)` that wraps `%js-call` with rest parameter support.

#### Scenario: Variadic call
- **WHEN** `(js-call ctx "fillRect" (js-number 10) (js-number 20) (js-number 100) (js-number 50))` is called
- **THEN** `ctx.fillRect(10, 20, 100, 50)` is called in JS

### Requirement: js-eval wrapper
`browser-lib.scm` SHALL define `(js-eval str)` that wraps `%js-eval`.

#### Scenario: Get global object
- **WHEN** `(js-eval "document")` is called
- **THEN** a js-ref to the document object is returned

### Requirement: Type conversion wrappers
`browser-lib.scm` SHALL define `js-number`, `js-string`, `js-ref->number`, `js-ref->string`, `js-null?`, `js-release!`, and `js-ref?` as wrappers around the raw primitives.

#### Scenario: Number round-trip
- **WHEN** `(js-ref->number (js-number 42))` is called
- **THEN** the ECE number `42` is returned

### Requirement: DOM access helpers
`browser-lib.scm` SHALL define `get-element-by-id`, `query-selector-all`, `set-text!`, and `set-html!`.

#### Scenario: Get element by ID
- **WHEN** `(get-element-by-id "my-div")` is called
- **THEN** a js-ref to the DOM element is returned (or js-null if not found)

### Requirement: Event handling
`browser-lib.scm` SHALL define `(add-event-listener! el event handler)` that wraps the DOM addEventListener using `js-callback`.

#### Scenario: Register click handler
- **WHEN** `(add-event-listener! btn "click" (lambda (e) (display "clicked")))` is called
- **THEN** a JS event listener is registered on the button element

### Requirement: CSS class manipulation
`browser-lib.scm` SHALL define `class-add!` and `class-remove!` for manipulating element classList.

#### Scenario: Add CSS class
- **WHEN** `(class-add! el "active")` is called
- **THEN** the "active" class is added to the element's classList

#### Scenario: Remove CSS class
- **WHEN** `(class-remove! el "active")` is called
- **THEN** the "active" class is removed from the element's classList

### Requirement: js-callback wrapper
`browser-lib.scm` SHALL define `(js-callback proc)` that wraps `%js-callback`.

#### Scenario: Create callback
- **WHEN** `(js-callback (lambda (e) (display "event")))` is called
- **THEN** a js-ref to a JS function wrapper is returned
