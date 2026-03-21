## 1. Remove generated sandbox files from repo

- [x] 1.1 Add `sandbox/ece-runtime.js`, `sandbox/ece-bootstrap.js`, `sandbox/ece-compiled.js` to `.gitignore`
- [x] 1.2 Remove the files from git tracking (already not tracked)

## 2. Landing page

- [x] 2.1 Create `site/index.html` — title, links to sandbox and tests, link to GitHub repo, dark theme

## 3. Browser test runner

- [x] 3.1 Create `scripts/build-test-page.sh` — compiles test .ececb, builds self-contained HTML with embedded assets
- [x] 3.2 Create test page HTML template — boots ECE, runs tests, parses output, renders pass/fail as styled HTML
- [x] 3.3 Add `make site` target to Makefile — builds sandbox, test page, assembles `_site/`

## 4. GitHub Actions workflow

- [x] 4.1 Create `.github/workflows/pages.yml` — install deps, build site, deploy via `actions/deploy-pages`

## 5. README

- [x] 5.1 Add live demo links near top of README (sandbox, tests)

## 6. Validation

- [x] 6.1 `make site` builds successfully locally
- [x] 6.2 Landing page links work
- [x] 6.3 Sandbox has all required files
- [x] 6.4 Test page built (2.1MB self-contained HTML)
