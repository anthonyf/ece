# ece-gh Wrapper Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build `scripts/ece-gh` — a curl-backed shell wrapper that replicates the `gh` commands used in this project's dev loop, working cleanly in Claude's sandbox.

**Architecture:** One bash script dispatches `api`/`pr`/`run` subcommands to curl against GitHub's REST API, pulling the auth token from the macOS keychain via `security`. Two memory files steer the assistant to use the wrapper and annotate the existing SSL-bypass memory as superseded for gh.

**Tech Stack:** bash, curl (Homebrew OpenSSL build), jq, sed, base64, macOS `security` CLI.

**Spec:** `docs/superpowers/specs/2026-04-23-ece-gh-wrapper-design.md`
**Base branch:** `ece-gh-wrapper` (design spec already committed).

---

## File Structure

- Create: `/Users/anthonyfairchild/git/ece/scripts/ece-gh` (bash, executable)
- Create: `/Users/anthonyfairchild/.claude/projects/-Users-anthonyfairchild-git-ece/memory/feedback_use_ece_gh.md`
- Modify: `/Users/anthonyfairchild/.claude/projects/-Users-anthonyfairchild-git-ece/memory/MEMORY.md` (one added line)
- Modify: `/Users/anthonyfairchild/.claude/projects/-Users-anthonyfairchild-git-ece/memory/feedback_verify_ssl.md` (append "superseded for gh" note)

---

## Task 1: Create `scripts/ece-gh`

**File:** Create `/Users/anthonyfairchild/git/ece/scripts/ece-gh`

### Step 1.1: Verify `scripts/` directory exists

```
ls /Users/anthonyfairchild/git/ece/scripts/ | head -3
```

Expected: at least one existing file (e.g., `pre-commit`, `build-ece-binary.lisp`). If the directory is missing, create it with `mkdir -p /Users/anthonyfairchild/git/ece/scripts`.

### Step 1.2: Write the script

Write the following to `/Users/anthonyfairchild/git/ece/scripts/ece-gh`:

```bash
#!/usr/bin/env bash
# ece-gh — curl-backed replacement for `gh` that works under Claude's sandbox.
#
# Why this exists:
#   `gh` on macOS uses the system Security framework for TLS verification.
#   When `gh` runs inside Claude's sandbox, Security framework returns
#   OSStatus -26276, causing every `gh api` / `gh pr *` call to fail with
#   "tls: failed to verify certificate". The `skip_tls_verification: true`
#   config flag is read but has no effect on that code path.
#
# What this does:
#   Drops to curl (Homebrew's OpenSSL-backed curl) + a token extracted from
#   the macOS keychain via `security find-generic-password`. Implements the
#   subset of gh commands used in this project's dev loop: api, pr view,
#   pr create, pr merge, run view.
#
# When to delete this script:
#   Once `gh` either (a) respects skip_tls_verification through all code
#   paths, or (b) ships a TLS fallback that works in sandbox, delete this
#   file and revert callers to native `gh`. Removal-test commands and full
#   rationale:
#     docs/superpowers/specs/2026-04-23-ece-gh-wrapper-design.md

set -euo pipefail

# ── Helpers ───────────────────────────────────────────────────────────

gh_token() {
  security find-generic-password -s "gh:github.com" -a anthonyf -w 2>/dev/null \
    | sed 's/^go-keyring-base64://' | base64 -d
}

infer_repo() {
  git remote get-url origin 2>/dev/null \
    | sed -E 's|.*github\.com[:/]([^/]+/[^/.]+)(\.git)?/?$|\1|'
}

require_jq() {
  command -v jq >/dev/null 2>&1 \
    || { echo "ece-gh: jq not found; brew install jq" >&2; exit 1; }
}

api() {
  local method="${1:-GET}"; shift
  local path="$1"; shift
  local token
  token="$(gh_token)"
  if [[ -z "$token" ]]; then
    echo "ece-gh: no gh token in keychain; run 'gh auth login' in a non-sandbox shell first" >&2
    exit 1
  fi
  curl -sk -X "$method" \
    -H "Authorization: token $token" \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/$path" "$@"
}

# ── api subcommand: passthrough, with -X/-f/--jq ──────────────────────

cmd_api() {
  local path=""
  local method="GET"
  local -a body_args=()
  local jq_filter=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -X) method="$2"; shift 2 ;;
      -f)
        # -f key=value → accumulate as JSON body fields
        body_args+=("$2")
        method="POST"
        shift 2
        ;;
      --jq) jq_filter="$2"; shift 2 ;;
      -*) echo "ece-gh api: unsupported flag: $1" >&2; exit 2 ;;
      *)
        if [[ -z "$path" ]]; then path="$1"
        else echo "ece-gh api: unexpected positional: $1" >&2; exit 2
        fi
        shift ;;
    esac
  done
  if [[ -z "$path" ]]; then
    echo "ece-gh api: missing path" >&2
    exit 2
  fi
  local body=""
  if [[ ${#body_args[@]} -gt 0 ]]; then
    body="$(printf '%s\n' "${body_args[@]}" | jq -R 'split("=") | {(.[0]): (.[1:] | join("="))}' | jq -s 'add')"
  fi
  local resp
  if [[ -n "$body" ]]; then
    resp="$(api "$method" "$path" -H "Content-Type: application/json" -d "$body")"
  else
    resp="$(api "$method" "$path")"
  fi
  if [[ -n "$jq_filter" ]]; then
    require_jq
    printf '%s' "$resp" | jq -r "$jq_filter"
  else
    printf '%s\n' "$resp"
  fi
}

# ── pr subcommand ─────────────────────────────────────────────────────

cmd_pr() {
  local sub="$1"; shift
  local repo
  repo="$(infer_repo)"
  if [[ -z "$repo" ]]; then
    echo "ece-gh pr: could not infer GitHub repo from 'origin' remote" >&2
    exit 1
  fi
  case "$sub" in
    view)   cmd_pr_view "$repo" "$@" ;;
    create) cmd_pr_create "$repo" "$@" ;;
    merge)  cmd_pr_merge "$repo" "$@" ;;
    *) echo "ece-gh pr: unsupported subcommand: $sub" >&2; exit 2 ;;
  esac
}

# gh pr view N [--json fields[,...]]
cmd_pr_view() {
  local repo="$1"; shift
  local pr_num=""
  local json_fields=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --json) json_fields="$2"; shift 2 ;;
      -*) echo "ece-gh pr view: unsupported flag: $1" >&2; exit 2 ;;
      *)
        if [[ -z "$pr_num" ]]; then pr_num="$1"
        else echo "ece-gh pr view: unexpected positional: $1" >&2; exit 2
        fi
        shift ;;
    esac
  done
  if [[ -z "$pr_num" ]]; then
    echo "ece-gh pr view: missing PR number" >&2
    exit 2
  fi
  local resp
  resp="$(api GET "repos/$repo/pulls/$pr_num")"
  if [[ -n "$json_fields" ]]; then
    require_jq
    # Build jq object-picker: "statusCheckRollup,mergeStateStatus" → "{statusCheckRollup,mergeStateStatus}"
    printf '%s' "$resp" | jq "{$json_fields}"
  else
    printf '%s\n' "$resp"
  fi
}

# gh pr create --base X --head Y --title T --body B
cmd_pr_create() {
  local repo="$1"; shift
  local base="" head="" title="" body=""
  local draft_flag="false"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --base)  base="$2";  shift 2 ;;
      --head)  head="$2";  shift 2 ;;
      --title) title="$2"; shift 2 ;;
      --body)  body="$2";  shift 2 ;;
      --draft) draft_flag="true"; shift ;;
      *) echo "ece-gh pr create: unsupported flag: $1" >&2; exit 2 ;;
    esac
  done
  if [[ -z "$base" || -z "$head" || -z "$title" || -z "$body" ]]; then
    echo "ece-gh pr create: --base --head --title --body all required" >&2
    exit 2
  fi
  require_jq
  local payload
  payload="$(jq -n --arg base "$base" --arg head "$head" --arg title "$title" --arg body "$body" --argjson draft "$draft_flag" \
    '{base: $base, head: $head, title: $title, body: $body, draft: $draft}')"
  local resp
  resp="$(api POST "repos/$repo/pulls" -H "Content-Type: application/json" -d "$payload")"
  # gh prints the PR URL on create success; mirror that.
  local url
  url="$(printf '%s' "$resp" | jq -r '.html_url // empty')"
  if [[ -z "$url" ]]; then
    echo "ece-gh pr create: failed; response:" >&2
    printf '%s\n' "$resp" >&2
    exit 1
  fi
  printf '%s\n' "$url"
}

# gh pr merge N --merge --delete-branch
cmd_pr_merge() {
  local repo="$1"; shift
  local pr_num=""
  local merge_method="merge"
  local delete_branch="false"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --merge)         merge_method="merge"; shift ;;
      --squash)        merge_method="squash"; shift ;;
      --rebase)        merge_method="rebase"; shift ;;
      --delete-branch) delete_branch="true"; shift ;;
      -*) echo "ece-gh pr merge: unsupported flag: $1" >&2; exit 2 ;;
      *)
        if [[ -z "$pr_num" ]]; then pr_num="$1"
        else echo "ece-gh pr merge: unexpected positional: $1" >&2; exit 2
        fi
        shift ;;
    esac
  done
  if [[ -z "$pr_num" ]]; then
    echo "ece-gh pr merge: missing PR number" >&2
    exit 2
  fi
  require_jq
  # Fetch head branch before merging (we need it after, and the PR record
  # may be read-only post-merge).
  local head_ref=""
  if [[ "$delete_branch" == "true" ]]; then
    head_ref="$(api GET "repos/$repo/pulls/$pr_num" | jq -r '.head.ref')"
  fi
  # Merge
  local merge_payload
  merge_payload="$(jq -n --arg m "$merge_method" '{merge_method: $m}')"
  local merge_resp
  merge_resp="$(api PUT "repos/$repo/pulls/$pr_num/merge" -H "Content-Type: application/json" -d "$merge_payload")"
  local merged
  merged="$(printf '%s' "$merge_resp" | jq -r '.merged // false')"
  if [[ "$merged" != "true" ]]; then
    echo "ece-gh pr merge: merge failed:" >&2
    printf '%s\n' "$merge_resp" >&2
    exit 1
  fi
  # Delete branch if requested
  if [[ "$delete_branch" == "true" && -n "$head_ref" ]]; then
    api DELETE "repos/$repo/git/refs/heads/$head_ref" >/dev/null || true
  fi
  echo "✓ Merged PR #$pr_num"
}

# ── run subcommand ────────────────────────────────────────────────────

cmd_run() {
  local sub="$1"; shift
  local repo
  repo="$(infer_repo)"
  case "$sub" in
    view) cmd_run_view "$repo" "$@" ;;
    *) echo "ece-gh run: unsupported subcommand: $sub" >&2; exit 2 ;;
  esac
}

# gh run view ID [--json fields]
cmd_run_view() {
  local repo="$1"; shift
  local run_id=""
  local json_fields=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --json) json_fields="$2"; shift 2 ;;
      -*) echo "ece-gh run view: unsupported flag: $1" >&2; exit 2 ;;
      *)
        if [[ -z "$run_id" ]]; then run_id="$1"
        else echo "ece-gh run view: unexpected positional: $1" >&2; exit 2
        fi
        shift ;;
    esac
  done
  if [[ -z "$run_id" ]]; then
    echo "ece-gh run view: missing run ID" >&2
    exit 2
  fi
  local resp
  resp="$(api GET "repos/$repo/actions/runs/$run_id")"
  if [[ -n "$json_fields" ]]; then
    require_jq
    printf '%s' "$resp" | jq "{$json_fields}"
  else
    printf '%s\n' "$resp"
  fi
}

# ── Top-level dispatch ────────────────────────────────────────────────

if [[ $# -lt 1 ]]; then
  echo "usage: ece-gh {api|pr|run} ..." >&2
  exit 2
fi
case "$1" in
  api) shift; cmd_api "$@" ;;
  pr)  shift; cmd_pr  "$@" ;;
  run) shift; cmd_run "$@" ;;
  *)   echo "ece-gh: unsupported command: $1" >&2; exit 2 ;;
esac
```

### Step 1.3: Make it executable

```
chmod +x /Users/anthonyfairchild/git/ece/scripts/ece-gh
```

### Step 1.4: Verify it parses and dispatches

```
/Users/anthonyfairchild/git/ece/scripts/ece-gh 2>&1 | head -3
```

Expected: `usage: ece-gh {api|pr|run} ...` (from the no-arg branch). If bash parse errors: inspect the script carefully for quoting issues.

### Step 1.5: Smoke-test `api`

```
cd /Users/anthonyfairchild/git/ece && scripts/ece-gh api user | head -5
```

Expected: JSON response starting with `{ "login": "anthonyf", ...`.

If it fails with "no gh token in keychain": user needs to `gh auth login` in a non-sandbox shell first. If the token is present but curl returns 401 / rate-limit: report the exact curl response before moving on.

### Step 1.6: Smoke-test `pr view`

```
cd /Users/anthonyfairchild/git/ece && scripts/ece-gh pr view 169 --json state 2>&1 | head -3
```

Expected: `{ "state": "MERGED" }` (PR #169 merged earlier in this session).

### Step 1.7: Smoke-test `run view`

First, fetch a recent run ID:

```
cd /Users/anthonyfairchild/git/ece && scripts/ece-gh api repos/anthonyf/ece/actions/runs?per_page=1 | jq -r '.workflow_runs[0].id'
```

Then view it:

```
cd /Users/anthonyfairchild/git/ece && scripts/ece-gh run view <id-from-above> --json status,conclusion
```

Expected: `{ "status": "completed", "conclusion": "success" }` or similar.

### Step 1.8: Commit

```
cd /Users/anthonyfairchild/git/ece
git add scripts/ece-gh
git commit -m "scripts: add ece-gh curl-backed wrapper for sandboxed gh

Native gh fails with TLS cert error (OSStatus -26276) under Claude's
sandbox because macOS Security framework is inaccessible. Wrapper
shells out to curl -sk with a keychain-extracted token for the subset
of gh used in this project's dev loop: api, pr view, pr create,
pr merge, run view.

Temporary — see design spec for removal plan:
  docs/superpowers/specs/2026-04-23-ece-gh-wrapper-design.md

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 2: Add `feedback_use_ece_gh.md` memory

**File:** Create `/Users/anthonyfairchild/.claude/projects/-Users-anthonyfairchild-git-ece/memory/feedback_use_ece_gh.md`

### Step 2.1: Write the file

```markdown
---
name: Use scripts/ece-gh instead of gh for API calls in this project
description: Native gh fails with TLS cert error under Claude's sandbox; scripts/ece-gh is the curl-backed wrapper that works in-sandbox
type: feedback
---

**Use `scripts/ece-gh` (in the ECE project) in place of `gh` for API calls.** The native `gh` fails with `tls: failed to verify certificate: x509: OSStatus -26276` when run from Claude's sandbox because macOS Security framework is inaccessible. The wrapper shells out to `curl -sk` with a keychain-extracted token and works cleanly without `dangerouslyDisableSandbox: true`.

**Supported subcommands:**

- `scripts/ece-gh api <path>` — GET/POST/PUT/DELETE with `-X METHOD`, `-f key=value` JSON body args, `--jq <filter>`.
- `scripts/ece-gh pr view N [--json fields]` — PR details, optionally filtered.
- `scripts/ece-gh pr create --base X --head Y --title T --body B` — open a PR.
- `scripts/ece-gh pr merge N [--merge|--squash|--rebase] [--delete-branch]` — merge + optional branch cleanup.
- `scripts/ece-gh run view ID [--json fields]` — actions workflow run details.

**If the wrapper doesn't cover what you need:** prefer `scripts/ece-gh api <raw-REST-path>` — it's a thin passthrough and covers anything the REST API exposes. Only fall back to `gh + dangerouslyDisableSandbox: true` when neither the wrapper nor the REST API path works.

**Why this is temporary:** `gh`'s `skip_tls_verification: true` config flag is supposed to bypass this but has no effect on the API client code path. When that's fixed upstream (or gh ships a TLS fallback that works in sandbox), delete the wrapper and revert. Removal test:

```bash
gh api user                                  # basic auth + TLS
gh pr view 1 --json statusCheckRollup        # JSON field extract
gh run view <id> --json status,conclusion    # actions API
```

If all three succeed in-sandbox → delete `scripts/ece-gh`, remove this memory, revert callers. Full rationale: `docs/superpowers/specs/2026-04-23-ece-gh-wrapper-design.md`.
```

### Step 2.2: Verify

```
ls -la /Users/anthonyfairchild/.claude/projects/-Users-anthonyfairchild-git-ece/memory/feedback_use_ece_gh.md
```

Expected: file present, non-empty.

---

## Task 3: Link from MEMORY.md

**File:** Modify `/Users/anthonyfairchild/.claude/projects/-Users-anthonyfairchild-git-ece/memory/MEMORY.md`

### Step 3.1: Locate the last "User Interaction Preferences" entry

```
grep -n 'feedback_sandbox_trust\|feedback_check_copilot_before_merge' /Users/anthonyfairchild/.claude/projects/-Users-anthonyfairchild-git-ece/memory/MEMORY.md | head
```

Expected: a line matching the sandbox-trust feedback entry added earlier this session. That's where the new link goes (immediately after).

### Step 3.2: Append the new link

Use the Edit tool:

```
old_string: - [Trust Makefile's sandbox setup](feedback_sandbox_trust.md) — run `make <target>` in-sandbox by default; only disable sandbox on actual failures; use `make clean-fasl` not raw `rm`

new_string: - [Trust Makefile's sandbox setup](feedback_sandbox_trust.md) — run `make <target>` in-sandbox by default; only disable sandbox on actual failures; use `make clean-fasl` not raw `rm`
- [Use scripts/ece-gh instead of gh](feedback_use_ece_gh.md) — native gh fails under sandbox (TLS cert); the wrapper works cleanly in-sandbox
```

### Step 3.3: Verify

```
grep -c 'feedback_use_ece_gh' /Users/anthonyfairchild/.claude/projects/-Users-anthonyfairchild-git-ece/memory/MEMORY.md
```

Expected: 1.

---

## Task 4: Annotate `feedback_verify_ssl.md` as superseded for gh

**File:** Modify `/Users/anthonyfairchild/.claude/projects/-Users-anthonyfairchild-git-ece/memory/feedback_verify_ssl.md`

### Step 4.1: Add a supersession note

Use the Edit tool to append a new section after the existing `**How to apply:**` list:

```
old_string: **How to apply:**
- If any command fails with a TLS/x509 cert error, retry with the appropriate bypass flag without asking.
- This applies to `gh`, `git`, `curl`, and similar tools in this environment.

new_string: **How to apply:**
- If any command fails with a TLS/x509 cert error, retry with the appropriate bypass flag without asking.
- This applies to `git`, `curl`, and similar tools in this environment.

**Superseded for `gh`:** use `scripts/ece-gh` (see [feedback_use_ece_gh.md](feedback_use_ece_gh.md)). `gh`'s `skip_tls_verification` flag doesn't actually work under Claude's sandbox; the wrapper is the clean path. This note remains relevant for `git` and `curl`.
```

### Step 4.2: Verify

```
grep -c 'Superseded for' /Users/anthonyfairchild/.claude/projects/-Users-anthonyfairchild-git-ece/memory/feedback_verify_ssl.md
```

Expected: 1.

---

## Task 5: Final verification + push + PR

### Step 5.1: Confirm the branch contains expected commits

```
cd /Users/anthonyfairchild/git/ece
git log --oneline main..HEAD
```

Expected (bottom to top):
```
<hash> scripts: add ece-gh curl-backed wrapper for sandboxed gh
<hash> Add design spec: ece-gh wrapper for sandboxed gh
```

The memory files are not in git (they live under `~/.claude/projects/...`). That's expected.

### Step 5.2: Sanity-check the script is staged correctly

```
cd /Users/anthonyfairchild/git/ece
git diff main -- scripts/ece-gh | head -30
git show HEAD -- scripts/ece-gh | head
```

Expected: the script is present, executable bit set (visible in the `new mode 100755` line of `git show`).

### Step 5.3: Push

```
cd /Users/anthonyfairchild/git/ece
git push -u origin ece-gh-wrapper
```

### Step 5.4: Open PR

Because this PR is adding the wrapper that helps `gh` work under sandbox, the PR itself is opened via native `gh` with sandbox disabled (one-time — this is the very command the wrapper is trying to avoid, but we can't use the wrapper to ship itself):

```
cd /Users/anthonyfairchild/git/ece
gh pr create --base main --head ece-gh-wrapper --title "scripts/ece-gh: curl-backed wrapper for gh under sandbox" --body "$(cat <<'EOF'
## Summary

Adds \`scripts/ece-gh\`, a curl-backed shell wrapper around the subset of
\`gh\` commands used in this project's dev loop. Closes the friction
where every \`gh api\` / \`gh pr\` call required \`dangerouslyDisableSandbox:
true\` in Claude sessions because macOS Security framework returns
OSStatus -26276 when called from sandbox.

**Why:** \`gh\`'s \`skip_tls_verification: true\` config flag is parsed
correctly but has no effect on the API client's TLS code path. See the
spec for full investigation details.

**Supported subcommands:** \`api\`, \`pr view\`, \`pr create\`, \`pr merge\`,
\`run view\`. For anything else, fall back to \`scripts/ece-gh api <raw-path>\`.

**Temporary:** removal plan in the spec. When native \`gh\` starts working
in-sandbox, delete the script and revert callers.

## Test plan

- [x] \`scripts/ece-gh api user\` returns the user JSON.
- [x] \`scripts/ece-gh pr view 169 --json state\` returns \`{"state":"MERGED"}\`.
- [x] \`scripts/ece-gh run view <id> --json status,conclusion\` returns the job state.

## Specs

- docs/superpowers/specs/2026-04-23-ece-gh-wrapper-design.md
- docs/superpowers/plans/2026-04-23-ece-gh-wrapper.md

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

If `gh pr create` itself fails (TLS), use the wrapper we just built:

```
cd /Users/anthonyfairchild/git/ece
scripts/ece-gh pr create --base main --head ece-gh-wrapper --title "scripts/ece-gh: curl-backed wrapper for gh under sandbox" --body "<body as above>"
```

---

## Self-Review Notes

**Spec coverage:**
- Design §1 (script) → Task 1.
- Design §2 (command semantics) → Task 1 step 1.2 (the full script includes all subcommand handlers).
- Design §3 (error handling) → Task 1 step 1.2 (embedded in the script).
- Design §4 (documentation) → Task 1 step 1.2 (script header) + design spec itself.
- Design §5 (memory) → Tasks 2, 3, 4.
- Design §6 (dependencies) → Task 1 step 1.4+ (smoke tests implicitly verify).

**Placeholder scan:** none. Every step has exact commands and complete code.

**Type consistency:** subcommand names (`api`, `pr view`, `pr create`, `pr merge`, `run view`), helper function names (`gh_token`, `infer_repo`, `api`, `require_jq`), and flag names (`--json`, `--jq`, `-f`, `-X`, `--merge`, `--squash`, `--rebase`, `--delete-branch`, `--base`, `--head`, `--title`, `--body`, `--draft`) all appear identically between the script definition (Task 1.2), the memory note (Task 2.1), and the design spec.
