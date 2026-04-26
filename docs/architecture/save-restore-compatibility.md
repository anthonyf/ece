# Save/Restore Compatibility Policy

ECE save files are serialized ECE values. When a saved value contains a
continuation or compiled procedure, the serializer may refer to loaded archive
code objects by `(archive-unit-id . index)` instead of embedding full instruction
vectors. This keeps ordinary continuation saves small, but it means save files
have a code identity requirement.

## Compatibility Boundary

A continuation save is compatible with the same archive identity, not merely
the same source filename. Archive-registered code objects serialize as:

```scheme
(%ser/co-ref unit-id index fingerprint)
```

`unit-id` and `index` locate the code object in the loaded archive registry.
`fingerprint` identifies the code object's serialized metadata and instruction
shape at save time. Loading a save requires the referenced archive entry to be
present and to match the saved fingerprint. If the archive is missing,
deserialization raises `ece-deser-missing-archive-error`. If the archive entry
exists but no longer matches, deserialization raises
`ece-deser-archive-mismatch-error`.

Older save blobs without fingerprints remain readable, but they cannot detect
same-unit/index code drift. They should be treated as best-effort legacy saves.

## Code Changes

Serialized continuations contain return addresses into code objects. Rebuilding
or editing code can move instructions, change labels, or alter the meaning of a
program counter. ECE therefore treats code changes as save-incompatible unless
an application implements its own migration layer.

For games and persistent workflows, prefer saving explicit state data for
long-term compatibility and reserve continuation saves for same-build resume,
page refresh, local checkpointing, and development workflows.

## Global State

The global environment is not serialized as application state. A serialized
continuation records lexical environments and parameter cells reachable from
the captured continuation, while globals are expected to be supplied by the
loaded program and bootstrap archives. Mutable game or workflow state should
live in lexical scope or in explicit data structures passed to the save layer.

## Host Resources

Host resources such as file ports, sockets, native streams, process handles,
and browser handles are not restored by value. If such a resource appears in a
`dynamic-wind` frame needed by a continuation, serialization raises
`ece-serialization-unserializable-wind-error` rather than dropping the frame and
silently changing control-flow semantics.

String ports may be reasonable to restore by value in a future change because
their complete state can be represented as ECE data. File ports, sockets, and
other native resources should require an explicit application-level resource
manager that serializes stable external references and reopens or rejects them
on restore.
