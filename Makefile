.PHONY: test test-ece repl run bootstrap wasm fmt check-fmt setup clean

BOOTSTRAP_DIR := bootstrap
BOOTSTRAP_SRCS := src/prelude.scm src/compiler.scm src/reader.scm src/assembler.scm src/compilation-unit.scm

test:
	qlot exec sbcl --eval '(asdf:test-system :ece)' --quit

test-ece:
	qlot exec sbcl --eval '(asdf:load-system :ece)' \
	  --eval '(handler-case (ece:evaluate (list (quote load) "tests/ece/run-all.scm")) (error ()))' \
	  --eval '(let ((f (ece::lookup-variable-value (intern "*test-failures*" :ece) ece::*global-env*))) (when (> f 0) (format t "~D ECE test failures~%" f) (sb-ext:exit :code 1)))' \
	  --quit

repl:
	qlot exec sbcl --load ece.asd --eval '(asdf:load-system :ece)' --eval '(ece:repl)'

bootstrap:
	@mkdir -p $(BOOTSTRAP_DIR)
	qlot exec sbcl --eval '(asdf:load-system :ece)' \
	  --eval '(in-package :ece)' \
	  --eval '(evaluate (list (quote eval) (list (quote read) (list (quote open-input-string) "(load \"src/compilation-unit.scm\")"))))' \
	  --eval '(dolist (f (list "src/prelude.scm" "src/compiler.scm" "src/reader.scm" "src/assembler.scm" "src/compilation-unit.scm")) (format t "Compiling ~A~%" f) (evaluate (list (quote eval) (list (quote read) (list (quote open-input-string) (format nil "(compile-file ~S)" f))))))' \
	  --quit
	mv -f src/*.ecec $(BOOTSTRAP_DIR)/
	@echo "Bootstrap .ecec files regenerated in $(BOOTSTRAP_DIR)/"
	@echo "Converting .ecec to .ececb..."
	qlot exec sbcl --eval '(asdf:load-system :ece)' \
	  --eval '(ece:evaluate (list (quote load) "src/ecec-to-binary.scm"))' \
	  --eval '(dolist (name (list "prelude" "compiler" "reader" "assembler" "compilation-unit")) (ece::convert-ecec-to-ececb (format nil "bootstrap/~A.ecec" name) (format nil "bootstrap/~A.ececb" name)))' \
	  --quit
	@echo "Bootstrap .ececb files generated."

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

clean:
	rm -rf ~/.cache/common-lisp/sbcl-2.6.1-macosx-arm64/Users/anthonyfairchild/git/ece/
