# ECE Documentation

This directory holds the maintained ECE documentation outside the top-level
[`README.md`](../README.md). The README is the user-facing overview; documents
here are the longer-lived references, design notes, and contributor guides.

## Start Here

- [`architecture/language-and-vm.md`](architecture/language-and-vm.md) gives a
  broad tour of the current language, compiler, archive, and runtime design.
- [`vm/specification.md`](vm/specification.md) is the VM reference: registers,
  instruction encoding, opcode behavior, operands, and machine operations.
- [`language/documentation.md`](language/documentation.md) describes the
  planned runtime documentation metadata system and phased rollout.
- [`architecture/save-restore-compatibility.md`](architecture/save-restore-compatibility.md)
  documents the save/restore compatibility boundary for serialized values and
  continuations.
- [`architecture/module-and-archive-plan.md`](architecture/module-and-archive-plan.md)
  describes the module/archive direction.
- [`architecture/browser-app-libraries-plan.md`](architecture/browser-app-libraries-plan.md)
  describes the browser library direction.
- [`architecture/wasm-native-zone-plan.md`](architecture/wasm-native-zone-plan.md)
  describes the WASM native-zone host design.

## Documentation Shape

- Stable references belong under topic directories such as `vm/`,
  `architecture/`, `language/`, `runtime/`, or `contributing/`.
- Design notes that still describe the current system can live under
  `architecture/`.
- Historical planning notes should be folded into the appropriate stable
  document before removal from the maintained path.
