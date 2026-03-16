## 1. Tag and Clean Up

- [x] 1.1 Tag current HEAD as `last-cl-bootstrap`
- [x] 1.2 Delete `src/compiler.lisp`
- [x] 1.3 Delete `src/readtable.lisp`
- [x] 1.4 Delete `src/boot.lisp`
- [x] 1.5 Remove `src/main.fasl` and `src/runtime.fasl` from git tracking

## 2. Update ASDF System

- [x] 2.1 Remove `"ece/cold"` system definition from `ece.asd`

## 3. Rewrite Makefile

- [x] 3.1 Rewrite `image:` target to use self-hosting rebuild (load `"ece"` system, ECE `load` each `.scm` file, `ece-save-image`)
- [x] 3.2 Remove `disasm:` target's dependency on `ece/cold` (if any)

## 4. Verify

- [x] 4.1 Run `make test` — all tests pass
- [x] 4.2 Run `make image` — self-hosting rebuild produces a valid image
- [x] 4.3 Run `make test` again after rebuild — tests pass against new image
- [x] 4.4 Run `make repl` — REPL starts and basic expressions work
