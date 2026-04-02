.PHONY: test test-rove test-ece test-wasm test-conformance check-test-counts repl run bootstrap wasm sandbox site fmt check-fmt setup clean clean-fasl update-test-counts

# FASL output goes to project-local .fasl-cache/ (sandbox-friendly, portable)
export ASDF_OUTPUT_TRANSLATIONS = (:output-translations ("$(CURDIR)/" "$(CURDIR)/.fasl-cache/") :inherit-configuration)

# Derive WASM test sources from run-common.scm (single manifest for both platforms)
WASM_TEST_SRCS := $(shell grep -o '"[^"]*"' tests/ece/run-common.scm | tr -d '"') wasm/wasm-test-runner.scm

# Temp dir for test output capture (used by check-test-counts)
TEST_OUTPUT_DIR := $(shell mktemp -d)

BOOTSTRAP_DIR := bootstrap
BOOTSTRAP_SRCS := src/prelude.scm src/compiler.scm src/reader.scm src/assembler.scm src/compilation-unit.scm src/syntax-rules.scm

test: test-rove test-ece test-conformance test-wasm check-test-counts

test-rove:
	qlot exec sbcl --eval '(asdf:load-system :ece)' --eval '(asdf:load-system :ece/tests)' --eval '(unless (rove:run :ece/tests) (uiop:quit 1))' --quit

test-ece:
	@qlot exec sbcl --eval '(asdf:load-system :ece)' \
	  --eval '(handler-case (ece:evaluate (list (quote load) "tests/ece/run-all.scm")) (error ()))' \
	  --eval '(let ((p (ece::lookup-variable-value (intern "*test-passes*" :ece) ece::*global-env*)) (f (ece::lookup-variable-value (intern "*test-failures*" :ece) ece::*global-env*))) (format t "~%~D passed, ~D failed~%" p f) (when (> f 0) (sb-ext:exit :code 1)))' \
	  --quit 2>&1 | tee $(TEST_OUTPUT_DIR)/test-ece.txt
	@grep -q "0 failed" $(TEST_OUTPUT_DIR)/test-ece.txt

test-conformance:
	@qlot exec sbcl --dynamic-space-size 4096 --eval '(asdf:load-system :ece)' \
	  --eval '(handler-case (ece:evaluate (list (quote load) "tests/conformance/run-conformance.scm")) (error (c) (format t "Error: ~A~%" c)))' \
	  --quit 2>&1 | tee $(TEST_OUTPUT_DIR)/test-conformance.txt

test-wasm: wasm
	@echo "Compiling WASM test suite..."
	@cat $(WASM_TEST_SRCS) > /tmp/ece-wasm-tests.scm
	@echo '(run-tests)' >> /tmp/ece-wasm-tests.scm
	@qlot exec sbcl --disable-debugger --eval '(asdf:load-system :ece)' \
	  --eval '(ece:evaluate (list (intern "compile-file" :ece) "/tmp/ece-wasm-tests.scm"))' \
	  --quit
	@echo "Running WASM tests..."
	@node --max-old-space-size=4096 wasm/test.js /tmp/ece-wasm-tests.ecec 2>&1 | tee $(TEST_OUTPUT_DIR)/test-wasm.txt

check-test-counts:
	@echo ""
	@echo "=== Test Count Baseline Check ==="
	@ECE_COUNT=$$(grep -o '[0-9]* passed' $(TEST_OUTPUT_DIR)/test-ece.txt 2>/dev/null | tail -1 | grep -o '^[0-9]*') && \
	  [ -n "$$ECE_COUNT" ] && bash scripts/check-test-counts.sh cl-ece "$$ECE_COUNT" || true
	@CONF_COUNT=$$(grep 'Conformance results:' $(TEST_OUTPUT_DIR)/test-conformance.txt 2>/dev/null | grep -o '[0-9]* passed' | grep -o '[0-9]*') && \
	  [ -n "$$CONF_COUNT" ] && bash scripts/check-test-counts.sh conformance "$$CONF_COUNT" || true
	@WASM_COUNT=$$(grep -o '[0-9]* passed' $(TEST_OUTPUT_DIR)/test-wasm.txt 2>/dev/null | tail -1 | grep -o '^[0-9]*') && \
	  [ -n "$$WASM_COUNT" ] && bash scripts/check-test-counts.sh wasm-ece "$$WASM_COUNT" || true

repl:
	qlot exec sbcl --load ece.asd --eval '(asdf:load-system :ece)' --eval '(ece:repl)'

bootstrap:
	@mkdir -p $(BOOTSTRAP_DIR)
	qlot exec sbcl --eval '(asdf:load-system :ece)' \
	  --eval '(in-package :ece)' \
	  --eval '(evaluate (list (quote eval) (list (quote read) (list (quote open-input-string) "(load \"src/compilation-unit.scm\")"))))' \
	  --eval '(dolist (f (list "src/prelude.scm" "src/compiler.scm" "src/reader.scm" "src/assembler.scm" "src/compilation-unit.scm" "src/syntax-rules.scm")) (format t "Compiling ~A~%" f) (evaluate (list (quote eval) (list (quote read) (list (quote open-input-string) (format nil "(compile-file ~S)" f))))))' \
	  --quit
	mv -f src/*.ecec $(BOOTSTRAP_DIR)/
	@echo "Bootstrap .ecec files regenerated in $(BOOTSTRAP_DIR)/"

sandbox: wasm
	bash scripts/build-sandbox.sh

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
	@echo "Running test suites to capture counts..."
	@CL_COUNT=$$(qlot exec sbcl --dynamic-space-size 4096 --disable-debugger \
	  --eval '(asdf:load-system :ece)' \
	  --eval '(handler-case (progn (ece:evaluate (list (quote load) "tests/ece/run-common.scm")) (ece:evaluate (list (quote load) "tests/ece/test-compilation-units.scm")) (ece:evaluate (list (intern "run-tests" :ece)))) (error ()))' \
	  --eval '(format t "~%ECE_PASS_COUNT=~D~%" (ece::lookup-variable-value (intern "*test-passes*" :ece) ece::*global-env*))' \
	  --quit 2>&1 | grep ECE_PASS_COUNT= | sed 's/ECE_PASS_COUNT=//') && \
	CONF_COUNT=$$(make test-conformance 2>&1 | grep 'Conformance results:' | grep -o '[0-9]* passed' | grep -o '[0-9]*') && \
	WASM_COUNT=$$(make test-wasm 2>&1 | grep 'passed,' | grep -o '^[0-9]*') && \
	python3 -c "import json; json.dump({'cl-ece': int('$$CL_COUNT'), 'cl-rove': 42, 'wasm-ece': int('$$WASM_COUNT'), 'conformance': int('$$CONF_COUNT')}, open('tests/test-counts.json','w'), indent=2); print(open('tests/test-counts.json').read())"

clean:
	rm -rf .fasl-cache/

clean-fasl:
	rm -rf .fasl-cache/
