# ece-gh Wrapper for Sandboxed `gh`

**Date:** 2026-04-23
**Status:** Implemented (PR #170)
**Scope:** small — one shell script + two memory-file edits + one spec (this file) + one implementation plan

## Context

In Claude's sandbox, every invocation of `gh` that touches the network fails with:

```
tls: failed to verify certificate: x509: OSStatus -26276
```

Investigation (this session) confirmed:

- The error comes from macOS's Security framework, invoked by Go's TLS layer inside `gh`. Sandbox context makes Security framework return `-26276` instead of validating the cert.
- `gh` has a `skip_tls_verification: true` flag in `~/.config/gh/hosts.yml`. The flag is correctly parsed (gh reports it as `true` via `gh config get`), but the HTTP client gh uses for API calls ignores it and still validates via Security framework.
- None of `GH_SSL_NO_VERIFY`, `GIT_SSL_NO_VERIFY`, `SSL_CERT_FILE`, `GODEBUG=x509usefallbackroots=1`, or `GH_TOKEN=…` change the behavior. The TLS failure happens before auth.
- `curl -sk` with `-H "Authorization: token …"` works cleanly in-sandbox (Homebrew curl is OpenSSL-backed, not Secure Transport).
- The keychain entry `gh:github.com` is readable from sandbox via `security find-generic-password`.

The current workaround — pass `dangerouslyDisableSandbox: true` on every `gh` call — produces permission prompts that interrupt flow. User explicitly asked to eliminate this friction.

## Goals

1. The common `gh` operations used in this project's dev loop (`api`, `pr view`, `pr create`, `pr merge`, `run view`) work in-sandbox without `dangerouslyDisableSandbox: true`.
2. The workaround is clearly marked as temporary: header in the script plus an explicit removal plan (three test commands that must succeed against native `gh` in-sandbox before we delete the wrapper).
3. Assistant memory steers to the wrapper by default.

## Non-goals

- Full gh-CLI compatibility. Only the subset this project uses.
- Fixing `gh` upstream. Not filed; the wrapper is sufficient for our dev-loop needs, and the bug primarily affects sandbox contexts that are unusual outside this project.
- Binary / compiled solution. Shell script is sufficient for a macOS dev machine.
- Automated tests. The wrapper is dev-environment tooling; manual verification suffices.

## Design

### 1. Script: `scripts/ece-gh`

Shell script (`#!/usr/bin/env bash`). Header explains why the script exists and when to delete it. Top-level helpers:

```bash
gh_token() {
  security find-generic-password -s "gh:github.com" -a anthonyf -w 2>/dev/null \
    | sed 's/^go-keyring-base64://' | base64 -d
}

infer_repo() {
  git remote get-url origin 2>/dev/null \
    | sed -E 's|.*github\.com[:/]([^/]+/[^/.]+)(\.git)?/?$|\1|'
}

api() {
  local method="${1:-GET}"; shift
  local path="$1"; shift
  curl -sk -X "$method" \
    -H "Authorization: token $(gh_token)" \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/$path" "$@"
}
```

Dispatch:

```bash
case "$1" in
  api) shift; cmd_api "$@" ;;
  pr)  shift; cmd_pr  "$@" ;;
  run) shift; cmd_run "$@" ;;
  *)   echo "ece-gh: unsupported: $*" >&2; exit 2 ;;
esac
```

### 2. Command semantics

| Wrapped | Underlying API call |
|---|---|
| `ece-gh api <path>` | `GET https://api.github.com/<path>` |
| `ece-gh api <path> -X METHOD` | that method |
| `ece-gh api <path> -f key=value` | JSON body `{"key": "value"}` |
| `ece-gh api <path> --jq <filter>` | response piped through `jq <filter>` |
| `ece-gh pr view N --json fields` | `GET /repos/OWNER/REPO/pulls/N` → `jq '{<fields>}'` |
| `ece-gh pr create --base X --head Y --title T --body B` | `POST /repos/OWNER/REPO/pulls` with JSON body |
| `ece-gh pr merge N --merge --delete-branch` | `PUT /repos/OWNER/REPO/pulls/N/merge` then `DELETE /repos/OWNER/REPO/git/refs/heads/<head-branch>` |
| `ece-gh run view ID --json fields` | `GET /repos/OWNER/REPO/actions/runs/ID` → `jq '{<fields>}'` |

OWNER/REPO inferred from `git remote get-url origin`. Head-branch for `pr merge --delete-branch` fetched from the PR metadata (`GET /repos/OWNER/REPO/pulls/N` → `.head.ref`) before the merge call.

### 3. Error handling

- Token not found in keychain → exit 1 with `"no gh token in keychain; run 'gh auth login' in a non-sandbox shell first"`.
- `curl` non-2xx response → print the response body to stderr, exit 1.
- Repo inference fails (no `origin`, or not a `github.com` URL) → exit 1 with `"could not infer GitHub repo from 'origin' remote"`.
- `jq` missing → exit 1 with `"jq not found; brew install jq"`.
- Unrecognized subcommand or flag → exit 2 with a clear message naming the offending token.

### 4. Documentation

**Header comment in `scripts/ece-gh`:** 12-15 lines explaining why the wrapper exists, what it does, and when to delete it. Points to this design doc.

**Removal plan (in this spec):** when native `gh` starts working in sandbox, these three commands succeed without `dangerouslyDisableSandbox: true`:

```bash
gh api user                                  # basic auth + TLS
gh pr view 1 --json statusCheckRollup        # JSON field extract
gh run view <id> --json status,conclusion    # actions API
```

If all three succeed → delete `scripts/ece-gh`, remove `feedback_use_ece_gh.md` memory + its link in `MEMORY.md`, revert any callers that pass `scripts/ece-gh` explicitly.

### 5. Memory

- **New:** `feedback_use_ece_gh.md` tells the assistant to use `scripts/ece-gh` instead of `gh` for API calls; references this design doc.
- **Link:** added to `MEMORY.md` under "User Interaction Preferences".
- **Supersede:** annotate existing `feedback_verify_ssl.md` noting it's still relevant for `git`/`curl` but not needed for `gh` now that the wrapper exists.

### 6. Dependencies

`bash`, `curl` (Homebrew, OpenSSL-backed — not macOS's Secure Transport curl), `jq`, `sed`, `base64`, `security` (macOS CLI). All present on the user's system.

## Testing

Manual verification after install:

1. `scripts/ece-gh api user | jq .login` → prints GitHub login.
2. `scripts/ece-gh pr view 169 --json state,merged` → `{"state":"closed","merged":true}`. (REST `state` is `open|closed`; the separate `merged` field distinguishes a merged PR from one closed without merge.)
3. `scripts/ece-gh run view <recent-run-id> --json status,conclusion` → `{"status":"completed","conclusion":"success"}`.
4. From sandbox context (i.e., the next assistant session) — run each without `dangerouslyDisableSandbox: true`; should succeed.

No automated test. The wrapper is a dev-environment tool; it touches the keychain, network, and GitHub; mocking all three is not worth the code.

## Risks

- **Keychain access fails in sandbox.** Mitigated — `security find-generic-password` was verified to work in-sandbox during this session.
- **Keychain entry missing or corrupted.** Script reports a clear error and exits 1.
- **`jq` filter format doesn't match gh's `--json` behavior.** `gh --json a,b,c` returns an object with those keys; we approximate with `jq '{a, b, c}'`. Close enough for the query patterns used here; if a caller needs deep filtering, use `--jq` explicitly.
- **GitHub API schema drift.** The API version header pins `2022-11-28`. When that's deprecated, update the header.
- **Wrapper drifts from native gh behavior.** Over time, if gh adds capabilities we rely on, the wrapper needs updating. Mitigated by the "prefer `ece-gh api <path>`" fallback in the memory note — it keeps us close to the REST API rather than re-implementing gh features.
