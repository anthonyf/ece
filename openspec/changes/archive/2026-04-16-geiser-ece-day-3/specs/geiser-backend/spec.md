## MODIFIED Requirements

### Requirement: geiser-autodoc returns parameter info for global procedures

The `geiser-autodoc` handler in `src/geiser-ece.scm` SHALL accept a list of identifiers, look up each in the global environment, query `%procedure-params` for parameter metadata, and return Geiser's expected autodoc alist format. The elisp side SHALL wire `eldoc-mode` to call this handler as the cursor moves through function call forms.

#### Scenario: Autodoc for a known function

- **WHEN** `(geiser-autodoc '(map))` is called
- **THEN** it SHALL return an alist containing `map` with its parameter names in the `(args (required ...))` format

#### Scenario: Autodoc for unknown identifier

- **WHEN** `(geiser-autodoc '(zzz-nonexistent))` is called
- **THEN** it SHALL return an empty list `()`

#### Scenario: Eldoc displays signature in minibuffer

- **WHEN** user positions cursor inside `(map |` in a `.scm` buffer with an active Geiser REPL
- **THEN** the minibuffer SHALL display the function signature showing parameter names
