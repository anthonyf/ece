## ADDED Requirements

### Requirement: CI reuses warm-cache zone FASLs in the `make ece` step instead of recompiling
The CI workflow in `.github/workflows/test.yml` runs two separate SBCL processes that both load `:ece`: the `Warm FASL cache` step (SBCL #1 at `--dynamic-space-size 8192`) and the `Build ece binary` step (SBCL #2 at `--dynamic-space-size 4096`, via `make ece`). SBCL #2 SHALL reuse the zone FASLs that SBCL #1 compiled instead of recompiling them from scratch, so that peak SBCL heap in the `Build ece binary` step stays comfortably below its 4GB dynamic-space-size.

This SHALL be achieved by ordering the workflow steps so that:
1. The `Mark bootstrap outputs as up-to-date` step (which touches `bootstrap/*-zone.lisp`) runs **before** `Warm FASL cache`.
2. `Warm FASL cache` runs after the touch, so its freshly-compiled FASLs land with mtimes strictly newer than the touched source mtimes.
3. `Build ece binary` runs last, and its `load-compiled-zones` mtime check sees FASL mtime > source mtime, triggering the "load cached FASL, no recompile" path.

The `load-compiled-zones` mtime check in `src/runtime.lisp` SHALL NOT be removed. It is load-bearing as a stale-cache safety net: if `actions/cache@v4`'s `restore-keys: fasl-` prefix match restores FASLs from a commit whose zone sources differ, the mtime check in SBCL #1 (warm-cache) detects the stale FASL and triggers a recompile before any stale code can be loaded.

#### Scenario: CI cache hit on exact key, no stale restore
- **WHEN** `actions/cache@v4` restores FASLs on an exact key match (same source hash as the current commit)
- **AND** the `Mark bootstrap outputs as up-to-date` step touches `bootstrap/*-zone.lisp`
- **AND** the `Warm FASL cache` step runs `(asdf:load-system :ece)` at 8GB
- **THEN** `load-compiled-zones` SHALL see touched source mtimes newer than restored FASL mtimes and SHALL recompile each zone file once, writing fresh FASLs at even-newer mtimes
- **AND** the subsequent `Build ece binary` step SHALL run `(asdf:load-system :ece)` and `(ece:evaluate (compile-system ...))` at 4GB, see fresh FASL mtimes > touched source mtimes, skip all zone recompilation, and complete `compile-system` with peak heap well under 4GB
- **AND** the `Build ece binary` step's stdout SHALL contain zero `; compiling file "bootstrap/*-zone.lisp"` lines

#### Scenario: CI prefix-match restore with stale FASLs
- **WHEN** `actions/cache@v4`'s `restore-keys: fasl-` pulls in FASLs from a commit with different zone source content
- **AND** the `Mark bootstrap outputs as up-to-date` step touches `bootstrap/*-zone.lisp`
- **AND** `Warm FASL cache` runs at 8GB
- **THEN** `load-compiled-zones` SHALL see touched source mtimes newer than the stale restored FASL mtimes and SHALL recompile each zone file, writing fresh FASLs that match the current commit's zone sources
- **AND** the subsequent `Build ece binary` step SHALL still skip all zone recompilation (FASL mtimes from warm-cache are newer than touched source mtimes) and SHALL successfully load the freshly-compiled FASLs

#### Scenario: Local build with no CI cache involvement
- **WHEN** a developer runs `make ece` locally on a clean `.fasl-cache/`
- **THEN** `load-compiled-zones` SHALL see missing FASLs and compile each zone file once
- **AND** subsequent `make ece` invocations SHALL reuse the cached FASLs because the zone sources have not been touched

### Requirement: `make ece` build heap stays at the existing 4GB ceiling
The `bin/ece` and `share/ece/ece-main.ecec` Makefile targets SHALL continue to run their SBCL invocations at `--dynamic-space-size 4096`. The CI `Warm FASL cache` step's separate use of `--dynamic-space-size 8192` is operational headroom specific to pre-warming restore-key-mismatched caches, not a load-bearing requirement of the normal build. After this change, the normal build path SHALL succeed at 4GB.

#### Scenario: Post-fix CI observation
- **WHEN** this change has landed and CI runs
- **AND** the `Build ece binary` step executes `make ece`
- **THEN** SBCL runs at `--dynamic-space-size 4096` (unchanged from before this change)
- **AND** no `Heap exhausted` error SHALL appear in the `Build ece binary` step's output
- **AND** the `compile-system` invocation SHALL produce a valid `share/ece/ece-main.ecec` output file
