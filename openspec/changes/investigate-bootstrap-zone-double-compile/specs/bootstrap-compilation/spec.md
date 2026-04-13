## ADDED Requirements

### Requirement: Each bootstrap zone file is compiled at most once per SBCL image during `make ece`
A fresh `make ece` invocation MUST compile each `bootstrap/*-zone.lisp` file at most once within the lifetime of a single SBCL process. Compiling the same zone twice in one image is wasted work and, for the largest zones (currently `reader-zone.lisp` at ~376k lines), pushes SBCL's dynamic heap past the 4GB default ceiling because IR1 optimization state from the first compile has not been released before the second begins.

This requirement applies to the `share/ece/ece-main.ecec` Makefile target (Makefile:28-33), which runs one SBCL image executing both `(asdf:load-system :ece)` and `(ece:evaluate (compile-system ...))`. Both invocations happen in the same image; neither may recompile a zone file the other already compiled in that image.

#### Scenario: Fresh build on a clean FASL cache
- **WHEN** the FASL cache is empty (`rm -rf .fasl-cache/`) and `make ece` is invoked
- **AND** the build reaches the `share/ece/ece-main.ecec` target
- **THEN** each `bootstrap/*-zone.lisp` file SHALL be compiled exactly once by SBCL/ASDF during the lifetime of the single SBCL process that executes that target
- **AND** no `; compiling file "bootstrap/*-zone.lisp"` log line from SBCL's `compile-file` SHALL appear more than once for the same file in that image's output

#### Scenario: Warm build with a populated FASL cache
- **WHEN** `.fasl-cache/bootstrap/*-zone.fasl` files already exist and are newer than their `.lisp` sources
- **AND** `make ece` is invoked
- **AND** the build reaches the `share/ece/ece-main.ecec` target
- **THEN** ASDF SHALL load the cached FASLs without recompiling any zone file
- **AND** no `compile-file` invocation on `bootstrap/*-zone.lisp` SHALL occur during the SBCL process for that target

#### Scenario: CI-style build with `touch bootstrap/*-zone.lisp` ahead of `make ece`
- **WHEN** the CI workflow runs `touch bootstrap/*-zone.lisp` (as currently done in `.github/workflows/test.yml` lines 59-64 to mark outputs up-to-date)
- **AND** `make ece` is invoked afterwards
- **AND** the build reaches the `share/ece/ece-main.ecec` target
- **THEN** each zone file SHALL be compiled at most once within that target's SBCL image
- **AND** whether the compile happens zero times (FASL newer than touched source) or one time (touch made the source newer than cached FASL) is acceptable, but recompiling the same file twice in one image SHALL NOT happen

### Requirement: Peak SBCL heap during `make ece` stays below 4GB on a normal build
After the double-compile is eliminated, a fresh `make ece` on a normal build (clean or warm cache) SHALL NOT exceed 4GB of SBCL dynamic heap at any point. The 8GB ceiling from PR #146 SHALL remain in place as headroom for future bootstrap expansion, but SHALL NOT be load-bearing — the build SHALL succeed at 4GB if the ceiling were temporarily restored.

Note: this requirement is aspirational for the current state of `prelude.scm` and `reader-zone.lisp`. If a single zone file legitimately requires more than 4GB of compile heap even without duplication, that is a separate scaling concern (splitting `prelude.scm` into smaller zones) tracked outside this change.

#### Scenario: Measuring peak heap after the fix
- **WHEN** the fix for the double-compile is applied
- **AND** `make ece` is run on a clean FASL cache with SBCL started at `--dynamic-space-size 4096` (temporarily, for measurement only)
- **THEN** the build SHALL complete successfully without `Heap exhausted` errors
- **AND** peak GC triggers SHALL show dynamic-space usage below 4GB at all points during the run
