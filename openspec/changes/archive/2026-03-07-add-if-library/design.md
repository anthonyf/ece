## Context

ECE now has all the core primitives needed for IF: `read-line`, `fmt`, `print-text`, `random`, `write-to-string`, string operations, list operations, macros, TCO, and `call/cc`. The next step is to build an IF library in pure ECE code that IF authors can `(load "if-lib.scm")` to get room definitions and choice menus.

## Goals / Non-Goals

**Goals:**
- Provide `room` and `choose` macros that feel natural for IF authoring
- Validate the design with a small playable sample game
- Update the roadmap to reflect current progress and priorities

**Non-Goals:**
- Visited room tracking (future — add when needed)
- Inventory helpers (future — add when needed)
- Save/load game to disk (future — needs continuation serialization)
- Text styling / ANSI colors (future polish)
- HTML/JSCL output target (future)

## Decisions

### 1. `room` macro design

```scheme
(room tavern
  "You enter a dimly lit tavern. A bartender polishes a glass."
  (choose ...))
```

Expands to:
```scheme
(define (tavern)
  (print-text "You enter a dimly lit tavern. A bartender polishes a glass.\n")
  (choose ...))
```

The `room` macro defines a zero-argument function, displays the description text, then evaluates the body. Navigation happens via tail calls between room functions (GOTO) or regular calls (GOSUB).

**Alternative considered**: Storing room metadata in a data structure (like SugarCube's passage objects). Rejected for now — functions are simpler and align with ECE's Scheme roots. Can add metadata later if needed.

### 2. `choose` macro design

```scheme
(choose
  ("Talk to bartender" (bartender-talk))
  ("Leave" (town-square))
  (when (> strength 15)
    ("Arm wrestle" (arm-wrestle))))
```

The `choose` macro is the most complex piece. It needs to:
1. Evaluate guard expressions at runtime to filter available choices
2. Display a numbered menu of available choices
3. Read the player's numeric input via `read-line` + `string->number`
4. Validate the input (re-prompt on invalid)
5. Execute the selected choice's action expression

**Implementation approach**: `choose` expands into code that builds a list of `(label . action-thunk)` pairs at runtime, filtering by guards. Then calls a helper function `choose-loop` that displays the menu and handles input.

```scheme
(define-macro (choose . clauses)
  (let ((choices (gensym)))
    `(let ((,choices (list ,@(map expand-choice clauses))))
       (choose-loop (filter car ,choices)))))
```

Each clause becomes either:
- `(cons "label" (lambda () action))` — unconditional
- `(if guard (cons "label" (lambda () action)) (cons #f #f))` — conditional (filtered out by `(filter car ...)`)

The `choose-loop` function is a regular ECE function (not a macro) that handles display and input:

```scheme
(define (choose-loop choices)
  (display-choices choices 1)
  (print-text "> ")
  (let ((input (string->number (read-line))))
    (if (and input (> input 0) (<= input (length choices)))
        ((cdr (list-ref choices (- input 1))))
        (begin (print-text "Invalid choice.\n")
               (choose-loop choices)))))
```

**Alternative considered**: Making `choose` a function instead of a macro. Rejected because guard expressions like `(when (> strength 15) ...)` need to be evaluated lazily — a function would evaluate all arguments eagerly, including guards for choices that shouldn't be shown.

### 3. File organization

- `if-lib.scm` — in project root, contains all IF library code
- `simple-game.scm` — in project root, starts with `(load "if-lib.scm")` and defines a small game

The sample game should have 3-5 rooms with:
- Basic navigation between rooms (GOTO via tail calls)
- At least one conditional choice (guarded by a variable)
- A simple win condition

### 4. Roadmap update

Mark step 1 as complete, update the "What ECE Has Today" table, and reflect the current priorities.

## Risks / Trade-offs

- **`choose` guard syntax**: Using `(when guard ...)` inside `choose` clauses means the macro needs to distinguish guarded from unguarded clauses at expansion time. This is doable by checking if the clause's car is `when`. → Straightforward pattern match in the macro.
- **Thunks for actions**: Wrapping each choice's action in `(lambda () ...)` adds a tiny overhead but is necessary to defer execution until the player chooses. → Negligible cost.
- **Input validation loop**: `choose-loop` re-prompts on invalid input. If the terminal is piped or reaches EOF, `read-line` could return empty string forever. → Acceptable for terminal IF; can add EOF check later.
