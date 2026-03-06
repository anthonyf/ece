---
name: test
description: Run the test suite for this Common Lisp project using qlot and rove.
---

Run the project tests using qlot and rove.

**Steps**

1. Run the tests:
   ```bash
   cd /Users/anthonyfairchild/git/ece && qlot exec sbcl --eval '(asdf:test-system :ece)' --quit
   ```

2. Review the output and report results to the user:
   - Number of tests passed/failed
   - Details of any failures
