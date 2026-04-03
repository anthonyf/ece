## 1. Convention-Based Resolution

- [x] 1.1 Create `*primitive-cl-overrides*` alist with ~15 non-conventional mappings (char->integer→char-code, set-car!→rplaca, etc.)
- [x] 1.2 Implement `resolve-cl-primitive` function: override table → `ece-<name>` → CL `<name>` → ECE `<name>` → nil
- [x] 1.3 Replace `init-primitive-dispatch-tables` to use `resolve-cl-primitive` instead of `build-cl-function-map`

## 2. Remove Manual Lists

- [x] 2.1 Remove `*primitive-procedures*` list
- [x] 2.2 Remove `*wrapper-primitives*` list
- [x] 2.3 Remove `build-cl-function-map` function

## 3. Boot-Time Validation

- [x] 3.1 Change unresolved `core`/`cl` primitives from warning to error (skip `ece` and `browser` platforms)
- [x] 3.2 Verify boot succeeds — all core/cl primitives resolve via convention or override

## 4. Bootstrap and Validation

- [x] 4.1 Two-pass `make bootstrap`
- [x] 4.2 Run CL test suite (rove + ECE self-hosted + conformance) — all must pass
- [x] 4.3 Run WASM test suite — all must pass (no WASM changes, but validate no regression)
