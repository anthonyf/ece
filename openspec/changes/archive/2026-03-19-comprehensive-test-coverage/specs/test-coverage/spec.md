## NEW Requirements

### Requirement: cross-space execution tested
Tests SHALL verify that functions calling across compilation spaces work correctly.

### Requirement: mutation primitives tested
Tests SHALL verify set-car! and set-cdr! behave correctly.

### Requirement: file I/O tested
Tests SHALL verify with-input-from-file, with-output-to-file, write-char, read-char, peek-char.

### Requirement: multiple continuation invocation tested
Tests SHALL verify a call/cc continuation can be invoked more than once with correct results.

### Requirement: continuation + parameterize interaction tested
Tests SHALL verify capturing a continuation inside parameterize, exiting, then invoking preserves dynamic bindings.

### Requirement: all features have ECE native tests
Features that currently only have CL-side tests SHALL gain ECE native equivalents: bitwise ops, random, write-to-string, named let, loop/collect, keyword?, platform-has?, macro shadowing.
