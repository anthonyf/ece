## REMOVED Requirements

### Requirement: ece/cold ASDF system loads compiler.lisp for cold boot
**Reason**: ECE is fully self-hosting. The CL bootstrap compiler and readtable are no longer needed — the image contains its own compiler, reader, and assembler. Image rebuilds use ECE itself.
**Migration**: Use `make image` (self-hosting rebuild) instead of `ece/cold`. For disaster recovery, checkout the `last-cl-bootstrap` git tag.
