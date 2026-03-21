## Why

The ECE sandbox and test suite run entirely in-browser via WASM but aren't publicly accessible. Deploying to GitHub Pages lets visitors try ECE without installing anything. Linking from the README makes the project immediately tangible.

## What Changes

- New GitHub Actions workflow (`.github/workflows/pages.yml`) builds sandbox assets and test page in CI, deploys to GitHub Pages on push to main
- New browser test runner page (`site/tests/index.html`) — boots ECE, runs compiled test suite, renders pass/fail results as HTML
- New landing page (`site/index.html`) — "ECE Sample Applications" with links to sandbox and tests, link back to GitHub
- README updated with live demo links near the top
- Sandbox build artifacts (`ece-runtime.js`, `ece-bootstrap.js`, `ece-compiled.js`) removed from repo, built in CI instead
- `.gitignore` updated to exclude generated sandbox files

## Capabilities

### New Capabilities
- `github-pages-deployment`: GitHub Actions workflow to build and deploy ECE showcase site
- `browser-test-runner`: In-browser ECE test suite with HTML results display

### Modified Capabilities
_None — no spec-level behavior changes._

## Impact

- `.github/workflows/pages.yml` (new)
- `site/index.html` (new landing page)
- `site/tests/index.html` (new browser test runner)
- `scripts/build-test-page.sh` (new build script)
- `README.md` (add demo links)
- `.gitignore` (add generated files)
- `Makefile` (add `site` target)
- `sandbox/ece-runtime.js`, `ece-bootstrap.js`, `ece-compiled.js` removed from git
