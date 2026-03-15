.PHONY: test test-ece repl run image disasm fmt check-fmt setup clean

BOOTSTRAP_IMAGE := bootstrap/ece.image

test:
	qlot exec sbcl --eval '(asdf:test-system :ece)' --quit

test-ece:
	qlot exec sbcl --eval '(asdf:load-system :ece)' \
	  --eval '(unless (ece:evaluate (list (quote load) "tests/ece/run-all.scm")) (sb-ext:exit :code 1))' \
	  --quit

repl:
	qlot exec sbcl --load ece.asd --eval '(asdf:load-system :ece)' --eval '(ece:repl)'

image:
	@mkdir -p bootstrap
	qlot exec sbcl --dynamic-space-size 4096 --load ece.asd --eval '(asdf:load-system :ece/cold)' --eval '(ece::ece-save-image "$(BOOTSTRAP_IMAGE)")' --quit
	@echo "Bootstrap image saved to $(BOOTSTRAP_IMAGE)"

disasm:
	@qlot exec sbcl --noinform --dynamic-space-size 4096 --load ece.asd --eval '(asdf:load-system :ece)' --eval '(ece:ece-disassemble-image "$(BOOTSTRAP_IMAGE)")' --quit

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
