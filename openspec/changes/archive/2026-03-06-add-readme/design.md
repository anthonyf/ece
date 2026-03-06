## Context

ECE is an explicit control evaluator for a small Lisp, written in Common Lisp. It implements self-evaluating expressions, variables, `quote`, `lambda`, `if`, `begin`, `call/cc`, and primitive procedures. It uses qlot for dependency management, ASDF for the build system, and rove for testing.

## Goals / Non-Goals

**Goals:**
- Document what ECE is and what language features it supports
- Provide setup and usage instructions (qlot, sbcl)
- Show how to run tests

**Non-Goals:**
- Comprehensive language reference or tutorial
- API documentation for internals

## Decisions

**Single README.md**: One file at project root. Keep it concise — the code is small enough to read directly for deeper understanding.

**Sections**: Title, description, features list, prerequisites, setup, usage examples, testing.

## Risks / Trade-offs

None significant. Documentation-only change.
