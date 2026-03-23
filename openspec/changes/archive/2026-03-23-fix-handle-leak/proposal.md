## Why

The clock demo (and other game loop demos) crash after ~23 minutes with "Out of bounds array.set" in `pair_car`. The handle table (8M entries) is exhausted because `$alloc-handle` increments monotonically and `reset_handles()` is never called during the game loop. Each frame allocates ~100 handles from JS exports and ECE execution, at 60fps that's ~6K handles/sec.

## What Changes

- Call `reset_handles()` in the sandbox's `animationLoop` to recycle temporary handles each frame
- Add a handle reset integration test to verify game loops can run indefinitely

## Capabilities

### New Capabilities

### Modified Capabilities

## Impact

- `sandbox/sandbox.js`: One line added to `animationLoop`
- `wasm/test.js`: One additional integration test
