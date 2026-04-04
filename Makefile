.PHONY: test test-rove test-ece test-wasm test-conformance test-golden check-test-counts test-web-server repl run run-lisp bootstrap wasm sandbox site fmt check-fmt setup clean clean-fasl update-test-counts update-golden

# FASL output goes to project-local .fasl-cache/ (sandbox-friendly, portable)
export ASDF_OUTPUT_TRANSLATIONS = (:output-translations ("$(CURDIR)/" "$(CURDIR)/.fasl-cache/") :inherit-configuration)

# Derive WASM test sources from run-common.scm (single manifest for both platforms)
WASM_TEST_SRCS := $(shell grep -o '"[^"]*"' tests/ece/run-common.scm | tr -d '"') wasm/wasm-test-runner.scm

# Temp dir for test output capture (used by check-test-counts)
TEST_OUTPUT_DIR := $(shell mktemp -d)

BOOTSTRAP_DIR := bootstrap
BOOTSTRAP_SRCS := src/prelude.scm src/compiler.scm src/reader.scm src/assembler.scm src/compilation-unit.scm src/syntax-rules.scm src/browser-lib.scm

GOLDEN_SRCS := $(wildcard tests/golden/*.scm)

test: test-rove test-ece test-wasm test-conformance test-golden check-test-counts test-web-server

test-rove:
	@qlot exec sbcl --disable-debugger --eval '(asdf:load-system :ece)' --eval '(asdf:load-system :ece/tests)' \
	  --eval '(let ((suite (car (rove/core/suite/package:all-suites)))) (rove/core/suite/package:run-suite suite) (unless (zerop (slot-value (rove/core/suite::suite-stats suite) (quote rove/core/result::failed))) (uiop:quit 1)))' \
	  --quit 2>&1 | tee $(TEST_OUTPUT_DIR)/test-rove.txt
	@grep -q "tests passed" $(TEST_OUTPUT_DIR)/test-rove.txt

test-ece:
	@mkdir -p .tmp
	@qlot exec sbcl --dynamic-space-size 4096 --disable-debugger --eval '(asdf:load-system :ece)' \
	  --eval '(handler-case (progn (ece:evaluate (list (quote load) "tests/ece/run-all.scm"))) (error ()))' \
	  --eval '(let ((p (ece::lookup-variable-value (intern "*test-passes*" :ece) ece::*global-env*)) (f (ece::lookup-variable-value (intern "*test-failures*" :ece) ece::*global-env*))) (format t "~%~D passed, ~D failed~%" p f) (when (> f 0) (sb-ext:exit :code 1)))' \
	  --quit 2>&1 | tee $(TEST_OUTPUT_DIR)/test-ece.txt
	@grep -q "0 failed" $(TEST_OUTPUT_DIR)/test-ece.txt

test-conformance:
	@qlot exec sbcl --dynamic-space-size 4096 --disable-debugger --eval '(asdf:load-system :ece)' \
	  --eval '(handler-case (ece:evaluate (list (quote load) "tests/conformance/run-conformance.scm")) (error (c) (format t "Error: ~A~%" c) (sb-ext:exit :code 1)))' \
	  --eval '(let ((f (ece::lookup-variable-value (intern "*conformance-failures*" :ece) ece::*global-env*))) (format t "~%~D conformance failures~%" f) (when (> f 0) (sb-ext:exit :code 1)))' \
	  --quit 2>&1 | tee $(TEST_OUTPUT_DIR)/test-conformance.txt
	@grep -q "Conformance results:" $(TEST_OUTPUT_DIR)/test-conformance.txt
	@! grep -q "[1-9][0-9]* failed" $(TEST_OUTPUT_DIR)/test-conformance.txt

test-wasm: wasm
	@mkdir -p .tmp
	@echo "Compiling WASM test suite..."
	@cat $(WASM_TEST_SRCS) > .tmp/ece-wasm-tests.scm
	@echo '(run-tests)' >> .tmp/ece-wasm-tests.scm
	@qlot exec sbcl --disable-debugger --eval '(asdf:load-system :ece)' \
	  --eval '(ece:evaluate (list (intern "compile-file" :ece) ".tmp/ece-wasm-tests.scm"))' \
	  --quit
	@echo "Running WASM tests..."
	@node --max-old-space-size=4096 wasm/test.js .tmp/ece-wasm-tests.ecec 2>&1 | tee $(TEST_OUTPUT_DIR)/test-wasm.txt
	@grep -q "0 failed" $(TEST_OUTPUT_DIR)/test-wasm.txt

check-test-counts:
	@echo ""
	@echo "=== Test Count Baseline Check ==="
	@ECE_COUNT=$$(grep -o '[0-9]* passed' $(TEST_OUTPUT_DIR)/test-ece.txt 2>/dev/null | tail -1 | grep -o '^[0-9]*'); \
	  if [ -n "$$ECE_COUNT" ]; then bash scripts/check-test-counts.sh cl-ece "$$ECE_COUNT"; fi
	@CONF_COUNT=$$(grep 'Conformance results:' $(TEST_OUTPUT_DIR)/test-conformance.txt 2>/dev/null | grep -o '[0-9]* passed' | grep -o '[0-9]*'); \
	  if [ -n "$$CONF_COUNT" ]; then bash scripts/check-test-counts.sh conformance "$$CONF_COUNT"; fi
	@WASM_COUNT=$$(grep -o '[0-9]* passed' $(TEST_OUTPUT_DIR)/test-wasm.txt 2>/dev/null | tail -1 | grep -o '^[0-9]*'); \
	  if [ -n "$$WASM_COUNT" ]; then bash scripts/check-test-counts.sh wasm-ece "$$WASM_COUNT"; fi

test-golden:
	@echo "Running golden compiler output tests..."
	@mkdir -p .tmp
	@FAIL=0; \
	for src in $(GOLDEN_SRCS); do \
	  base=$$(basename "$$src" .scm); \
	  expected="tests/golden/$$base.expected"; \
	  actual=".tmp/$$base.actual"; \
	  qlot exec sbcl --dynamic-space-size 4096 --disable-debugger \
	    --eval '(asdf:load-system :ece)' \
	    --eval '(in-package :ece)' \
	    --eval "(set-variable-value! (intern \"mc-label-counter\" :ece) 0 *global-env*)" \
	    --eval "(evaluate (list (intern \"compile-file\" :ece) \"$$src\"))" \
	    --quit 2>/dev/null; \
	  ecec="tests/golden/$$base.ecec"; \
	  tail -n +2 "$$ecec" > "$$actual"; \
	  rm -f "$$ecec"; \
	  if diff -u "$$expected" "$$actual" > /dev/null 2>&1; then \
	    echo "  PASS: $$base"; \
	  else \
	    echo "  FAIL: $$base"; \
	    diff -u "$$expected" "$$actual" | head -20; \
	    FAIL=1; \
	  fi; \
	done; \
	[ $$FAIL -eq 0 ] && echo "All golden tests passed." || (echo "Golden tests FAILED." && exit 1)

update-golden:
	@echo "Updating golden expected files..."
	@for src in $(GOLDEN_SRCS); do \
	  base=$$(basename "$$src" .scm); \
	  expected="tests/golden/$$base.expected"; \
	  qlot exec sbcl --dynamic-space-size 4096 --disable-debugger \
	    --eval '(asdf:load-system :ece)' \
	    --eval '(in-package :ece)' \
	    --eval "(set-variable-value! (intern \"mc-label-counter\" :ece) 0 *global-env*)" \
	    --eval "(evaluate (list (intern \"compile-file\" :ece) \"$$src\"))" \
	    --quit 2>/dev/null; \
	  ecec="tests/golden/$$base.ecec"; \
	  tail -n +2 "$$ecec" > "$$expected"; \
	  rm -f "$$ecec"; \
	  echo "  Updated: $$base.expected ($$(wc -l < "$$expected") lines)"; \
	done

test-web-server: wasm
	@echo "Building hello-world in server mode..."
	@mkdir -p .tmp/server-mode-test
	@printf '(display "Hello, World!")\n(newline)\n' > .tmp/server-mode-hello.scm
	@bin/ece-build --target web -o .tmp/server-mode-test .tmp/server-mode-hello.scm
	@echo "Starting HTTP server..."
	@python3 -c '\
import http.server, socketserver, threading, sys, subprocess, functools; \
handler = functools.partial(http.server.SimpleHTTPRequestHandler, directory=".tmp/server-mode-test"); \
srv = socketserver.TCPServer(("127.0.0.1", 0), handler); \
port = srv.server_address[1]; \
print(f"Serving on port {port}"); \
t = threading.Thread(target=srv.serve_forever, daemon=True); \
t.start(); \
r = subprocess.run(["node", "wasm/test-server-mode.js", f"http://127.0.0.1:{port}"], capture_output=True, text=True); \
print(r.stdout, end=""); \
print(r.stderr, end="", file=sys.stderr); \
srv.shutdown(); \
sys.exit(r.returncode)'

repl:
	qlot exec sbcl --load ece.asd --eval '(asdf:load-system :ece)' --eval '(ece:repl)'

# Run SBCL with ECE loaded — use for ad-hoc evaluation via --eval
# Example: make run-lisp ARGS="--eval '(ece:evaluate 42)' --quit"
run-lisp:
	qlot exec sbcl --dynamic-space-size 4096 --disable-debugger --eval '(asdf:load-system :ece)' $(ARGS)

bootstrap:
	@mkdir -p $(BOOTSTRAP_DIR)
	qlot exec sbcl --eval '(asdf:load-system :ece)' \
	  --eval '(in-package :ece)' \
	  --eval '(evaluate (list (quote eval) (list (quote read) (list (quote open-input-string) "(load \"src/compilation-unit.scm\")"))))' \
	  --eval '(evaluate (list (quote eval) (list (quote read) (list (quote open-input-string) "(compile-system (quote (\"src/prelude.scm\" \"src/compiler.scm\" \"src/reader.scm\" \"src/assembler.scm\" \"src/compilation-unit.scm\" \"src/syntax-rules.scm\" \"src/browser-lib.scm\")) \"bootstrap/bootstrap.ecec\")"))))' \
	  --quit
	@echo "Bootstrap bundle regenerated: $(BOOTSTRAP_DIR)/bootstrap.ecec"

sandbox: wasm
	@mkdir -p .tmp/sandbox-build sandbox
	@echo '(void)' > .tmp/sandbox-stub.scm
	@bin/ece-build --target web --standalone -o .tmp/sandbox-build .tmp/sandbox-stub.scm
	@cp .tmp/sandbox-build/ece-runtime.js sandbox/ece-runtime.js
	@cp .tmp/sandbox-build/ece-bootstrap.js sandbox/ece-bootstrap.js
	@# Pre-compile canned programs (Hello World .scm → .ecec → base64 in JS)
	@echo "Compiling canned programs..."
	@printf '(display "Hello, World!")\n(newline)\n' > .tmp/ece-hello.scm
	@qlot exec sbcl --disable-debugger --eval '(asdf:load-system :ece)' \
	  --eval '(ece:evaluate (list (intern "compile-file" :ece) ".tmp/ece-hello.scm"))' \
	  --quit 2>/dev/null
	@echo '// Pre-compiled ECE programs — auto-generated' > sandbox/ece-compiled.js
	@echo 'const ECE_COMPILED = {};' >> sandbox/ece-compiled.js
	@printf '%s' 'ECE_COMPILED["Hello World"] = "' >> sandbox/ece-compiled.js
	@base64 -i .tmp/ece-hello.ecec | tr -d '\n' >> sandbox/ece-compiled.js
	@echo '";' >> sandbox/ece-compiled.js
	@echo "Sandbox assets built in sandbox/"

site: sandbox
	@echo "Assembling site..."
	@rm -rf _site
	@mkdir -p _site/sandbox
	@cp site/index.html _site/
	@cp sandbox/index.html sandbox/sandbox.js sandbox/ece-programs.js _site/sandbox/
	@cp sandbox/ece-runtime.js sandbox/ece-bootstrap.js sandbox/ece-compiled.js _site/sandbox/
	@bash scripts/build-test-page.sh _site/tests
	@echo "Site built at _site/"

wasm: wasm/runtime.wasm

wasm/runtime.wasm: wasm/runtime.wat
	wasm-as --enable-gc --enable-reference-types wasm/runtime.wat -o wasm/runtime.wasm

run:
	qlot exec sbcl --load ece.asd --eval '(asdf:load-system :ece)' --eval '(ece:repl)'

ROOT_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
LISP_FILES := $(wildcard src/*.lisp) $(wildcard tests/*.lisp) ece.asd
SCM_FILES := $(wildcard src/*.scm)

fmt:
	@for f in $(LISP_FILES); do \
		echo "Formatting $$f"; \
		emacs --batch "$$f" --load "$(ROOT_DIR)/scripts/cl-indent.el" 2>/dev/null; \
	done
	@for f in $(SCM_FILES); do \
		echo "Formatting $$f"; \
		emacs --batch "$$f" --load "$(ROOT_DIR)/scripts/scheme-indent.el" 2>/dev/null; \
	done

check-fmt: fmt
	@if git diff --quiet -- $(LISP_FILES) $(SCM_FILES); then \
		echo "Formatting check passed."; \
	else \
		echo "Formatting check failed. Run 'make fmt' to fix."; \
		git checkout -- $(LISP_FILES) $(SCM_FILES); \
		exit 1; \
	fi

setup:
	ln -sf ../../scripts/pre-commit .git/hooks/pre-commit
	@echo "Pre-commit hook installed."

update-test-counts:
	@mkdir -p .tmp
	@echo "Running test suites to capture counts..."
	@CL_COUNT=$$(qlot exec sbcl --dynamic-space-size 4096 --disable-debugger \
	  --eval '(asdf:load-system :ece)' \
	  --eval '(handler-case (progn (ece:evaluate (list (quote load) "tests/ece/run-all.scm"))) (error ()))' \
	  --eval '(format t "~%ECE_PASS_COUNT=~D~%" (ece::lookup-variable-value (intern "*test-passes*" :ece) ece::*global-env*))' \
	  --quit 2>&1 | grep ECE_PASS_COUNT= | sed 's/ECE_PASS_COUNT=//') && \
	CONF_COUNT=$$(make test-conformance 2>&1 | grep 'Conformance results:' | grep -o '[0-9]* passed' | grep -o '[0-9]*') && \
	WASM_COUNT=$$(make test-wasm 2>&1 | grep 'passed,' | grep -o '^[0-9]*') && \
	python3 -c "import json; json.dump({'cl-ece': int('$$CL_COUNT'), 'cl-rove': 42, 'wasm-ece': int('$$WASM_COUNT'), 'conformance': int('$$CONF_COUNT')}, open('tests/test-counts.json','w'), indent=2); print(open('tests/test-counts.json').read())"

clean:
	rm -rf .fasl-cache/

clean-fasl:
	rm -rf .fasl-cache/
