## Tasks

- [x] Investigated: skipping call/cc wrapper breaks R7RS dynamic-wind tests — reverted
- [x] Refactor: rename old `save-continuation!` / `load-continuation` to `%write-value-to-file` / `%read-value-from-file` (internal)
- [x] New `save-continuation!` function: uses `%raw-call/cc` to capture + save, returns `#t` on save, `#f` on restore
- [x] New `load-continuation` function: loads + invokes the saved continuation
- [x] Update CL test-serialization.scm to use internal `%write-value-to-file` / `%read-value-from-file`
- [x] Regenerate bootstrap
- [x] Run CL tests: all passed (dynamic-wind tests pass)
- [x] Run WASM tests: 445 passed, 0 failed
