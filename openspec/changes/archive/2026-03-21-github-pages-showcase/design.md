## Context

The sandbox (`sandbox/`) is a self-contained HTML app with all assets inlined as base64 JS. Currently the generated files (~2.5MB) are committed to the repo. The WASM test suite runs in Node via `wasm/test.js`. There's no browser-accessible version of either.

GitHub Pages can serve static files from a branch or artifact. GitHub Actions can build the site on each push.

## Goals / Non-Goals

**Goals:**
- Sandbox and test suite accessible at `anthonyf.github.io/ece/`
- CI builds everything — no generated files committed
- Landing page links apps and points back to GitHub
- README links directly to live demos

**Non-Goals:**
- Custom domain
- Server-side anything
- Build optimization (caching, incremental builds)

## Decisions

### 1. Site structure

```
_site/                    ← built in CI, deployed to Pages
├── index.html            ← landing page (committed as site/index.html)
├── sandbox/              ← copied from sandbox/ after make sandbox
│   ├── index.html
│   ├── ece-runtime.js    ← generated
│   ├── ece-bootstrap.js  ← generated
│   ├── ece-compiled.js   ← generated
│   ├── ece-programs.js
│   └── sandbox.js
└── tests/                ← built by scripts/build-test-page.sh
    └── index.html        ← self-contained (embeds ece-runtime.js, bootstrap, test .ececb)
```

**Choice:** Use `actions/upload-pages-artifact` + `actions/deploy-pages` (the modern GitHub Pages deployment via artifacts, not gh-pages branch). This avoids a separate branch and keeps deployment atomic.

### 2. Browser test runner

The test page reuses the same boot pattern as the sandbox: decode base64 WASM, instantiate, load bootstrap .ececb files, run test space.

**Choice:** Build `site/tests/index.html` via `scripts/build-test-page.sh`. The script:
1. Runs `make test-wasm` to compile tests to `/tmp/ece-wasm-tests.ececb`
2. Embeds ece-runtime.js, ece-bootstrap.js, and test .ececb (base64) into a single HTML file
3. The HTML boots ECE, runs the test space, captures `display` output, parses pass/fail counts, renders as styled HTML

The test output format is already parseable: lines contain "PASS" / "FAIL" and a final "N passed, M failed" summary.

### 3. Generated files removed from repo

**Choice:** Add to `.gitignore`:
```
sandbox/ece-runtime.js
sandbox/ece-bootstrap.js
sandbox/ece-compiled.js
```

These are ~2.5MB of base64-encoded binaries that change on every rebuild. CI builds them fresh. Local dev uses `make sandbox` as before.

### 4. CI workflow

The Pages workflow shares setup with `test.yml` (SBCL, qlot, binaryen, Node). Rather than duplicating, both workflows install the same deps independently. The Pages workflow runs after tests pass (via `needs: test` or separate trigger).

**Choice:** Separate workflow file (`pages.yml`), triggered only on push to main (not PRs). Depends on tests passing via `workflow_run` or just runs its own build — simpler to just build independently since the test workflow already gates merges.

## Risks / Trade-offs

- **CI build time**: Full rebuild (SBCL + bootstrap + WASM + sandbox + tests) takes ~2-3 min. Acceptable for deploy-on-push.
- **Large HTML files**: The test page embeds everything as base64 (~3MB). GitHub Pages serves with gzip, so transfer is ~1MB. Acceptable.
