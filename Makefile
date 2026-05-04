.PHONY: all ece install uninstall test test-rove test-ece test-wasm test-conformance test-golden test-web-server test-ece-serve-live repl run run-lisp bootstrap wasm sandbox site slides fmt check-fmt setup clean clean-fasl update-golden

PREFIX ?= /usr/local
DESTDIR ?=

# Files to lay out at $PREFIX/share/ece/
SHARE_FILES := \
	bootstrap/bootstrap.ecec \
	wasm/runtime.wasm \
	wasm/glue.js \
	src/sdk-lib.scm src/ece-main.scm src/ece-unit.scm src/ece-build.scm src/ece-test.scm src/ece-serve.scm src/geiser-ece.scm src/http-codec.scm src/websocket-codec.scm src/json.scm src/scheduler.scm src/sha1.scm src/base64.scm src/wasm-host.scm src/codegen-wasm-zone.scm

# Default target: build the ece binary and ECE bundles so in-tree dev works.
all: ece

# Build bin/ece via save-lisp-and-die, compile ece-main.ecec, create in-tree
# symlinks, and stage share/ece/ so ece-home resolution works in-tree.
ece: bootstrap wasm bin/ece

bin/ece: scripts/build-ece-binary.lisp bootstrap/bootstrap.ecec share/ece/ece-main.ecec | .qlot/qlot.conf
	@mkdir -p bin
	qlot exec sbcl --dynamic-space-size 4096 --non-interactive --load scripts/build-ece-binary.lisp
	@ln -sf ece bin/ece-repl
	@ln -sf ece bin/ece-build
	@ln -sf ece bin/ece-test
	@ln -sf ece bin/ece-serve
	@echo "Built bin/ece + symlinks (ece-repl, ece-build, ece-test, ece-serve)"

share/ece/ece-main.ecec: src/sdk-lib.scm src/ece-main.scm src/ece-unit.scm src/base64.scm src/sha1.scm src/scheduler.scm src/http-codec.scm src/websocket-codec.scm src/json.scm src/wasm-host.scm src/codegen-wasm-zone.scm src/ece-build.scm src/ece-test.scm src/ece-serve.scm src/geiser-ece.scm bootstrap/bootstrap.ecec wasm/runtime.wasm wasm/glue.js | .qlot/qlot.conf
	@mkdir -p share/ece/templates
	qlot exec sbcl --dynamic-space-size 4096 --non-interactive --disable-debugger \
	  --eval '(asdf:load-system :ece)' \
	  --eval '(ece:evaluate (list (intern "compile-system" :ece) (quote (quote ("src/sdk-lib.scm" "src/ece-unit.scm" "src/base64.scm" "src/sha1.scm" "src/scheduler.scm" "src/http-codec.scm" "src/websocket-codec.scm" "src/json.scm" "src/wasm-host.scm" "src/codegen-wasm-zone.scm" "src/ece-main.scm" "src/ece-build.scm" "src/ece-test.scm" "src/ece-serve.scm" "src/geiser-ece.scm"))) "share/ece/ece-main.ecec"))' \
	  --quit
	@# Stage the other share/ece/ files so in-tree `bin/ece` works
	@cp bootstrap/bootstrap.ecec share/ece/bootstrap.ecec
	@cp wasm/runtime.wasm share/ece/runtime.wasm
	@cp wasm/glue.js share/ece/glue.js
	@cp -R templates/web share/ece/templates/web
	@cp -R templates/cl share/ece/templates/cl
	@cp -R templates/web-app share/ece/templates/web-app
	@echo "Staged share/ece/ tree"

install: ece
	install -d $(DESTDIR)$(PREFIX)/bin
	install -m 755 bin/ece $(DESTDIR)$(PREFIX)/bin/ece
	ln -sf ece $(DESTDIR)$(PREFIX)/bin/ece-repl
	ln -sf ece $(DESTDIR)$(PREFIX)/bin/ece-build
	ln -sf ece $(DESTDIR)$(PREFIX)/bin/ece-test
	ln -sf ece $(DESTDIR)$(PREFIX)/bin/ece-serve
	install -d $(DESTDIR)$(PREFIX)/share/ece
	install -d $(DESTDIR)$(PREFIX)/share/ece/templates
	install -m 644 share/ece/bootstrap.ecec $(DESTDIR)$(PREFIX)/share/ece/bootstrap.ecec
	install -m 644 share/ece/ece-main.ecec $(DESTDIR)$(PREFIX)/share/ece/ece-main.ecec
	install -m 644 share/ece/runtime.wasm $(DESTDIR)$(PREFIX)/share/ece/runtime.wasm
	install -m 644 share/ece/glue.js $(DESTDIR)$(PREFIX)/share/ece/glue.js
	install -m 644 src/sdk-lib.scm $(DESTDIR)$(PREFIX)/share/ece/sdk-lib.scm
	install -m 644 src/ece-main.scm $(DESTDIR)$(PREFIX)/share/ece/ece-main.scm
	install -m 644 src/ece-unit.scm $(DESTDIR)$(PREFIX)/share/ece/ece-unit.scm
	install -m 644 src/ece-build.scm $(DESTDIR)$(PREFIX)/share/ece/ece-build.scm
	install -m 644 src/ece-test.scm $(DESTDIR)$(PREFIX)/share/ece/ece-test.scm
	install -m 644 src/ece-serve.scm $(DESTDIR)$(PREFIX)/share/ece/ece-serve.scm
	install -m 644 src/geiser-ece.scm $(DESTDIR)$(PREFIX)/share/ece/geiser-ece.scm
	install -m 644 src/sha1.scm $(DESTDIR)$(PREFIX)/share/ece/sha1.scm
	install -m 644 src/base64.scm $(DESTDIR)$(PREFIX)/share/ece/base64.scm
	install -m 644 src/scheduler.scm $(DESTDIR)$(PREFIX)/share/ece/scheduler.scm
	install -m 644 src/http-codec.scm $(DESTDIR)$(PREFIX)/share/ece/http-codec.scm
	install -m 644 src/websocket-codec.scm $(DESTDIR)$(PREFIX)/share/ece/websocket-codec.scm
	install -m 644 src/json.scm $(DESTDIR)$(PREFIX)/share/ece/json.scm
	install -m 644 src/wasm-host.scm $(DESTDIR)$(PREFIX)/share/ece/wasm-host.scm
	install -m 644 src/codegen-wasm-zone.scm $(DESTDIR)$(PREFIX)/share/ece/codegen-wasm-zone.scm
	cp -R share/ece/templates/web $(DESTDIR)$(PREFIX)/share/ece/templates/web
	cp -R share/ece/templates/cl $(DESTDIR)$(PREFIX)/share/ece/templates/cl
	cp -R share/ece/templates/web-app $(DESTDIR)$(PREFIX)/share/ece/templates/web-app
	@echo "Installed to $(DESTDIR)$(PREFIX)"

uninstall:
	rm -f $(DESTDIR)$(PREFIX)/bin/ece
	rm -f $(DESTDIR)$(PREFIX)/bin/ece-repl
	rm -f $(DESTDIR)$(PREFIX)/bin/ece-build
	rm -f $(DESTDIR)$(PREFIX)/bin/ece-test
	rm -f $(DESTDIR)$(PREFIX)/bin/ece-serve
	rm -rf $(DESTDIR)$(PREFIX)/share/ece
	@echo "Uninstalled from $(DESTDIR)$(PREFIX)"

# FASL output goes to project-local .fasl-cache/ (sandbox-friendly, portable)
export ASDF_OUTPUT_TRANSLATIONS = (:output-translations ("$(CURDIR)/" "$(CURDIR)/.fasl-cache/") :inherit-configuration)

# qlot-install marker. `.qlot/qlot.conf` is produced by `qlot install`
# and stays put across runs, so it's a reliable sentinel. No normal
# prereqs: make only runs the recipe when the target file is missing
# (i.e., on a fresh clone/worktree). If qlfile.lock is bumped, the
# user runs `rm -rf .qlot && make setup` explicitly, consistent with
# how most projects treat package-manager lockfiles. Lives under
# project-local .qlot/ (sandbox-writable); the exported
# ASDF_OUTPUT_TRANSLATIONS above ensures any SBCL invocation qlot
# makes during install writes FASLs to .fasl-cache/ too.
.qlot/qlot.conf:
	qlot install
	@test -f $@ || { echo "error: qlot install did not create $@"; exit 1; }

# WASM test bundle: framework + reusable utilities + common/ (platform-independent) tests + runner.
# base64.scm and sha1.scm must come before the test files so their exports
# are defined when test-base64 / test-sha1 run. Both run on CL and WASM now
# that the bitwise primitives handle large integers uniformly.
WASM_TEST_SRCS := src/sdk-lib.scm src/ece-unit.scm src/base64.scm src/sha1.scm src/scheduler.scm src/http-codec.scm src/websocket-codec.scm src/json.scm src/ece-serve.scm src/wasm-host.scm src/codegen-wasm-zone.scm src/geiser-ece.scm $(wildcard tests/ece/common/test-*.scm) wasm/wasm-test-runner.scm

# Temp dir for test output capture
TEST_OUTPUT_DIR := .tmp/test-output

BOOTSTRAP_DIR := bootstrap
BOOTSTRAP_ZONE_DIR := .tmp/bootstrap-zones
BOOTSTRAP_ZONE_BUNDLE := $(BOOTSTRAP_ZONE_DIR)/bootstrap-zones.lisp
BOOTSTRAP_SRCS := src/boot-env.scm src/prelude.scm src/compiler.scm src/reader.scm src/assembler.scm src/compilation-unit.scm src/syntax-rules.scm src/browser-lib.scm src/wasm-host.scm src/disassemble.scm

GOLDEN_SRCS := $(wildcard tests/golden/*.scm)

test: test-rove test-ece test-wasm test-conformance test-golden test-web-server test-web-apps test-ece-serve-live

# Note: rove:run doesn't discover suites from FASL-cached files, so we use
# call-with-suite/all-suites/run-suite which work after asdf:load-system.
test-rove: | .qlot/qlot.conf
	@mkdir -p $(TEST_OUTPUT_DIR)
	@bash -o pipefail -c 'qlot exec sbcl --dynamic-space-size 4096 --disable-debugger --eval "(asdf:load-system :ece)" --eval "(asdf:load-system :ece/tests)" \
	  --eval "(let ((passedp (funcall (find-symbol \"CALL-WITH-SUITE\" :rove/core/suite) (lambda () (dolist (s (funcall (find-symbol \"ALL-SUITES\" :rove/core/suite/package))) (funcall (find-symbol \"RUN-SUITE\" :rove/core/suite/package) s)))))) (unless passedp (uiop:quit 1)))" \
	  --quit 2>&1 | tee $(TEST_OUTPUT_DIR)/test-rove.txt'

test-ece: | .qlot/qlot.conf
	@mkdir -p .tmp $(TEST_OUTPUT_DIR)
	@qlot exec sbcl --dynamic-space-size 4096 --disable-debugger \
	  --eval '(asdf:load-system :ece)' \
	  --eval '(ece:evaluate (list (quote load) "src/sdk-lib.scm"))' \
	  --eval '(ece:evaluate (list (quote load) "src/sha1.scm"))' \
	  --eval '(ece:evaluate (list (quote load) "src/base64.scm"))' \
	  --eval '(ece:evaluate (list (quote load) "src/scheduler.scm"))' \
	  --eval '(ece:evaluate (list (quote load) "src/http-codec.scm"))' \
	  --eval '(ece:evaluate (list (quote load) "src/websocket-codec.scm"))' \
	  --eval '(ece:evaluate (list (quote load) "src/json.scm"))' \
	  --eval '(ece:evaluate (list (quote load) "src/ece-serve.scm"))' \
	  --eval '(ece:evaluate (list (quote load) "src/wasm-host.scm"))' \
	  --eval '(ece:evaluate (list (quote load) "src/codegen-wasm-zone.scm"))' \
	  --eval '(ece:evaluate (list (quote load) "src/geiser-ece.scm"))' \
	  --eval '(ece:evaluate (list (quote load) "src/ece-unit.scm"))' \
	  --eval '(ece:evaluate (list (quote load) "src/ece-test.scm"))' \
	  --eval '(ece:evaluate (list (intern "ece-test-main" :ece) (list (quote list) "tests/ece/common" "tests/ece/cl-only")))' \
	  --quit 2>&1 | tee $(TEST_OUTPUT_DIR)/test-ece.txt
	@grep -q "0 failed" $(TEST_OUTPUT_DIR)/test-ece.txt

test-conformance: | .qlot/qlot.conf
	@mkdir -p $(TEST_OUTPUT_DIR)
	@qlot exec sbcl --dynamic-space-size 4096 --disable-debugger --eval '(asdf:load-system :ece)' \
	  --eval '(handler-case (ece:evaluate (list (quote load) "tests/conformance/run-conformance.scm")) (error (c) (format t "Error: ~A~%" c) (sb-ext:exit :code 1)))' \
	  --eval '(let ((f (ece::lookup-variable-value (intern "*conformance-failures*" :ece) ece::*global-env*))) (format t "~%~D conformance failures~%" f) (when (> f 0) (sb-ext:exit :code 1)))' \
	  --quit 2>&1 | tee $(TEST_OUTPUT_DIR)/test-conformance.txt
	@grep -q "Conformance results:" $(TEST_OUTPUT_DIR)/test-conformance.txt
	@! grep -q "[1-9][0-9]* failed" $(TEST_OUTPUT_DIR)/test-conformance.txt

test-wasm: wasm | .qlot/qlot.conf
	@mkdir -p .tmp $(TEST_OUTPUT_DIR)
	@echo "Compiling WASM test suite..."
	@cat $(WASM_TEST_SRCS) > .tmp/ece-wasm-tests.scm
	@qlot exec sbcl --dynamic-space-size 4096 --disable-debugger --eval '(asdf:load-system :ece)' \
	  --eval '(ece:evaluate (list (intern "compile-file" :ece) ".tmp/ece-wasm-tests.scm"))' \
	  --quit
	@echo "Running WASM tests..."
	@node --max-old-space-size=4096 wasm/test.js .tmp/ece-wasm-tests.ecec 2>&1 | tee $(TEST_OUTPUT_DIR)/test-wasm.txt
	@grep -q "0 failed" $(TEST_OUTPUT_DIR)/test-wasm.txt

test-golden: | .qlot/qlot.conf
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
	  cp "$$ecec" "$$actual"; \
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

update-golden: | .qlot/qlot.conf
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
	  cp "$$ecec" "$$expected"; \
	  rm -f "$$ecec"; \
	  echo "  Updated: $$base.expected ($$(wc -c < "$$expected") bytes)"; \
	done

test-web-server: ece
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
	@echo "Building native-zone server mode smoke..."
	@mkdir -p .tmp/server-mode-native-test
	@printf '123\n(display (if (native-zone-registered? (quote server-mode-native) 0) "Native zone registered!" "Native zone missing!"))\n(newline)\n' > .tmp/server-mode-native.scm
	@bin/ece-build --target web --native-zones -o .tmp/server-mode-native-test .tmp/server-mode-native.scm
	@wasm-as --enable-gc --enable-reference-types .tmp/server-mode-native-test/app-zones.wat -o .tmp/server-mode-native-test/app-zones.wasm
	@echo "Starting HTTP server for native-zone smoke..."
	@python3 -c '\
import http.server, socketserver, threading, sys, subprocess, functools; \
handler = functools.partial(http.server.SimpleHTTPRequestHandler, directory=".tmp/server-mode-native-test"); \
srv = socketserver.TCPServer(("127.0.0.1", 0), handler); \
port = srv.server_address[1]; \
print(f"Serving on port {port}"); \
t = threading.Thread(target=srv.serve_forever, daemon=True); \
t.start(); \
r = subprocess.run(["node", "wasm/test-server-mode.js", f"http://127.0.0.1:{port}", "Native zone registered!"], capture_output=True, text=True); \
print(r.stdout, end=""); \
print(r.stderr, end="", file=sys.stderr); \
srv.shutdown(); \
sys.exit(r.returncode)'
	@echo "Building native-zone reload smoke..."
	@mkdir -p .tmp/server-mode-reload-src-a .tmp/server-mode-reload-src-b .tmp/server-mode-reload-test .tmp/server-mode-reload-next
	@printf '11\n' > .tmp/server-mode-reload-src-a/server-reload.scm
	@printf '22\n' > .tmp/server-mode-reload-src-b/server-reload.scm
	@bin/ece-build --target web --native-zones -o .tmp/server-mode-reload-test .tmp/server-mode-reload-src-a/server-reload.scm
	@bin/ece-build --target web --native-zones -o .tmp/server-mode-reload-next .tmp/server-mode-reload-src-b/server-reload.scm
	@wasm-as --enable-gc --enable-reference-types .tmp/server-mode-reload-test/app-zones.wat -o .tmp/server-mode-reload-test/app-zones.wasm
	@wasm-as --enable-gc --enable-reference-types .tmp/server-mode-reload-next/app-zones.wat -o .tmp/server-mode-reload-next/app-zones.wasm
	@echo "Starting HTTP server for native-zone reload smoke..."
	@python3 -c '\
import http.server, socketserver, threading, sys, subprocess, functools; \
handler = functools.partial(http.server.SimpleHTTPRequestHandler, directory=".tmp/server-mode-reload-test"); \
srv = socketserver.TCPServer(("127.0.0.1", 0), handler); \
port = srv.server_address[1]; \
print(f"Serving on port {port}"); \
t = threading.Thread(target=srv.serve_forever, daemon=True); \
t.start(); \
r = subprocess.run(["node", "wasm/test-server-reload.js", f"http://127.0.0.1:{port}", ".tmp/server-mode-reload-test", ".tmp/server-mode-reload-next", "server-reload", "11", "22"], capture_output=True, text=True); \
print(r.stdout, end=""); \
print(r.stderr, end="", file=sys.stderr); \
srv.shutdown(); \
sys.exit(r.returncode)'

test-web-apps: sandbox
	@echo "Running web apps smoke test..."
	@node wasm/test-web-apps.js

test-ece-serve-live: ece
	@echo "Running ece-serve live reload smoke test..."
	@node wasm/test-ece-serve-live.js

repl: share/ece/ece-main.ecec | .qlot/qlot.conf
	qlot exec sbcl --dynamic-space-size 4096 --load ece.asd --eval '(asdf:load-system :ece)' \
	  --eval '(in-package :ece)' \
	  --eval '(evaluate (quote (begin (load-bundle "share/ece/ece-main.ecec") (repl))))'

# Run SBCL with ECE loaded — use for ad-hoc evaluation via --eval
# Example: make run-lisp ARGS="--eval '(ece:evaluate 42)' --quit"
run-lisp: | .qlot/qlot.conf
	qlot exec sbcl --dynamic-space-size 4096 --disable-debugger --eval '(asdf:load-system :ece)' $(ARGS)

# Code-object native CL generation emits one disposable aggregate zone bundle
# under $(BOOTSTRAP_ZONE_DIR), not bootstrap/, so stable bootstrap artifacts
# stay visible and the generated CL cache remains clearly disposable.
ZONE_SENTINEL := $(BOOTSTRAP_ZONE_BUNDLE)

bootstrap: $(BOOTSTRAP_DIR)/primitives-auto.lisp $(BOOTSTRAP_DIR)/bootstrap.ecec $(ZONE_SENTINEL)

# Bootstrap bundle: compiled-system output for all .scm modules. Must be
# regenerated whenever any .scm source changes (so the assembler space's
# instruction vector reflects current src/assembler.scm).
$(BOOTSTRAP_DIR)/bootstrap.ecec: $(BOOTSTRAP_SRCS) $(BOOTSTRAP_DIR)/primitives-auto.lisp | .qlot/qlot.conf
	@mkdir -p $(BOOTSTRAP_DIR)
	qlot exec sbcl --dynamic-space-size 4096 --eval '(asdf:load-system :ece)' \
	  --eval '(in-package :ece)' \
	  --eval '(evaluate (list (quote eval) (list (quote read) (list (quote open-input-string) "(load \"src/compilation-unit.scm\")"))))' \
	  --eval '(evaluate (list (quote eval) (list (quote read) (list (quote open-input-string) "(compile-system (quote (\"src/boot-env.scm\" \"src/prelude.scm\" \"src/compiler.scm\" \"src/reader.scm\" \"src/assembler.scm\" \"src/compilation-unit.scm\" \"src/syntax-rules.scm\" \"src/browser-lib.scm\" \"src/wasm-host.scm\" \"src/disassemble.scm\")) \"bootstrap/bootstrap.ecec\")"))))' \
	  --quit
	@echo "Bootstrap bundle regenerated: $(BOOTSTRAP_DIR)/bootstrap.ecec"
	@# Zones compiled against the old bootstrap.ecec have PC layouts that
	@# don't match the new one. Delete them so the zone target starts clean
	@# and subsequent sbcl invocations fall back to pure bytecode dispatch.
	@rm -rf $(BOOTSTRAP_ZONE_DIR) .fasl-cache/.tmp/bootstrap-zones 2>/dev/null || true
	@rm -f $(BOOTSTRAP_DIR)/*-zone.lisp .fasl-cache/bootstrap/*-zone.fasl 2>/dev/null || true

# Auto-generated CL primitive defuns. Source of truth: src/primitives.scm.
# The codegen tool (src/codegen-cl.scm) is itself an ECE program that runs
# through the existing ECE interpreter. The generated file is checked in.
$(BOOTSTRAP_DIR)/primitives-auto.lisp: primitives.def src/primitives.scm src/codegen-cl.scm | .qlot/qlot.conf
	@mkdir -p $(BOOTSTRAP_DIR)
	@echo "Regenerating $(BOOTSTRAP_DIR)/primitives-auto.lisp from src/primitives.scm..."
	qlot exec sbcl --dynamic-space-size 4096 --non-interactive --disable-debugger \
	  --eval '(asdf:load-system :ece)' \
	  --eval '(ece:evaluate (list (quote load) "src/codegen-cl.scm"))' \
	  --eval '(ece:evaluate (list (quote load) "src/primitives.scm"))' \
	  --eval '(ece:evaluate (list (intern "generate-primitives-auto-lisp!" :ece) "primitives.def" "$(BOOTSTRAP_DIR)/primitives-auto.lisp"))' \
	  --quit
	@echo "Generated $(BOOTSTRAP_DIR)/primitives-auto.lisp"

# Archive-driven compiled-zone generation. Reads the archive at
# $(BOOTSTRAP_DIR)/bootstrap.ecec and emits one aggregate CL native-zone bundle
# containing one defun and registration per code-object.
$(ZONE_SENTINEL): primitives.def src/primitives.scm src/codegen-cl.scm src/codegen-cl-inline.scm $(BOOTSTRAP_SRCS) $(BOOTSTRAP_DIR)/bootstrap.ecec | .qlot/qlot.conf
	@rm -rf $(BOOTSTRAP_ZONE_DIR)
	@mkdir -p $(BOOTSTRAP_ZONE_DIR)
	@rm -f $(BOOTSTRAP_DIR)/*-zone.lisp 2>/dev/null || true
	@echo "Regenerating compiled zone bundle $(BOOTSTRAP_ZONE_BUNDLE)..."
	qlot exec sbcl --dynamic-space-size 4096 --non-interactive --disable-debugger \
	  --eval '(asdf:load-system :ece)' \
	  --eval '(ece:evaluate (list (quote load) "src/codegen-cl.scm"))' \
	  --eval '(ece:evaluate (list (quote load) "src/primitives.scm"))' \
	  --eval '(ece:evaluate (list (quote load) "src/codegen-cl-inline.scm"))' \
	  --eval '(ece:evaluate (list (intern "generate-all-zones-from-archive!" :ece) "$(BOOTSTRAP_DIR)/bootstrap.ecec" "$(BOOTSTRAP_ZONE_DIR)"))' \
	  --quit
	@echo "Generated $(BOOTSTRAP_ZONE_BUNDLE)"

sandbox: ece
	@mkdir -p .tmp/sandbox-build sandbox
	@echo '(void)' > .tmp/sandbox-stub.scm
	@bin/ece-build --target web --standalone -o .tmp/sandbox-build .tmp/sandbox-stub.scm
	@cp .tmp/sandbox-build/ece-runtime.js sandbox/ece-runtime.js
	@cp .tmp/sandbox-build/ece-bootstrap.js sandbox/ece-bootstrap.js
	@# Generate ece-programs.js from manifest.sexp and referenced .scm files
	@echo "Generating program list from sandbox/programs/manifest.sexp..."
	@node scripts/gen-programs-js.js
	@# Pre-compile canned programs (Hello World .scm → .ecec → base64 in JS)
	@echo "Compiling canned programs..."
	@qlot exec sbcl --dynamic-space-size 4096 --disable-debugger --eval '(asdf:load-system :ece)' \
	  --eval '(ece:evaluate (list (intern "compile-file" :ece) "sandbox/programs/hello-world.scm"))' \
	  --quit 2>/dev/null
	@echo '// Pre-compiled ECE programs — auto-generated' > sandbox/ece-compiled.js
	@echo 'const ECE_COMPILED = {};' >> sandbox/ece-compiled.js
	@printf '%s' 'ECE_COMPILED["Hello World"] = "' >> sandbox/ece-compiled.js
	@base64 -i sandbox/programs/hello-world.ecec | tr -d '\n' >> sandbox/ece-compiled.js
	@echo '";' >> sandbox/ece-compiled.js
	@echo "Sandbox assets built in sandbox/"

slides: slides/presentation.html

slides/presentation.html: slides/presentation.md
	marp slides/presentation.md --html -o slides/presentation.html
	open slides/presentation.html

site: sandbox
	@echo "Assembling site..."
	@rm -rf _site
	@mkdir -p _site/sandbox
	@cp site/index.html _site/
	@cp sandbox/index.html sandbox/sandbox.js sandbox/ece-programs.js _site/sandbox/
	@cp sandbox/ece-runtime.js sandbox/ece-bootstrap.js sandbox/ece-compiled.js _site/sandbox/
	@# Build browser test page via ece-build (reuses WASM_TEST_SRCS)
	@mkdir -p .tmp
	@cat $(WASM_TEST_SRCS) > .tmp/ece-site-tests.scm
	@echo '(run-tests)' >> .tmp/ece-site-tests.scm
	@bin/ece-build --target test-page -o _site/tests .tmp/ece-site-tests.scm
	@echo "Site built at _site/"

wasm: wasm/runtime.wasm

wasm/runtime.wasm: wasm/runtime.wat
	wasm-as --enable-gc --enable-reference-types wasm/runtime.wat -o wasm/runtime.wasm

run: repl

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
		exit 1; \
	fi

setup: | .qlot/qlot.conf
	ln -sf ../../scripts/pre-commit .git/hooks/pre-commit
	@echo "Pre-commit hook installed."

clean:
	rm -rf .fasl-cache/ $(BOOTSTRAP_ZONE_DIR)
	rm -f $(BOOTSTRAP_DIR)/*-zone.lisp

clean-fasl: clean
