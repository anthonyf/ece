;;; Module system tests.

(define phase-a-core-count 0)

(define (module-test-cleanup! unit-ids)
  (for-each
   (lambda (unit-id)
     (let ((key (archive/unit-key unit-id)))
       (hash-remove! *archive-units* key)
       (hash-remove! *module-instances* key)))
   unit-ids))

(define (with-module-test-units* unit-ids thunk)
  (dynamic-wind
    (lambda () (module-test-cleanup! unit-ids))
    thunk
    (lambda () (module-test-cleanup! unit-ids))))

(define (write-module-test-file filename text)
  (let ((port #f))
    (dynamic-wind
     (lambda () (set! port (open-output-file filename)))
     (lambda () (display text port))
     (lambda () (when port (close-output-port port))))))

(define (write-module-test-archive-bundle filename archives)
  (let ((port #f))
    (dynamic-wind
     (lambda () (set! port (open-output-file filename)))
     (lambda ()
       (for-each
        (lambda (archive)
          (display (write-to-string-flat archive) port)
          (newline port))
        archives))
     (lambda () (when port (close-output-port port))))))

(define (module-test-error-message thunk)
  (guard (e (#t (if (error-object? e)
                    (error-object-message e)
                    "non-error-object")))
    (thunk)
    #f))

(test "modules: bundle load resolves reversed dependency order" (lambda ()
  (let ((base-id '(module (phase-a reverse-base) 0))
        (user-id '(module (phase-a reverse-user) 0))
        (base-path ".tmp/phase-a-reverse-base.scm")
        (user-path ".tmp/phase-a-reverse-user.scm")
        (bundle-path ".tmp/phase-a-reversed.ecec"))
    (with-module-test-units*
     (list base-id user-id)
     (lambda ()
       (write-module-test-file
        base-path
        "(define-module (phase-a reverse-base)\n  (export answer)\n  (define answer 42)\n  answer)\n")
       (write-module-test-file
        user-path
        "(define-module (phase-a reverse-user)\n  (import (phase-a reverse-base))\n  (export doubled)\n  (define doubled (+ answer answer))\n  doubled)\n")
       (compile-system (list user-path base-path) bundle-path)
       (load-bundle bundle-path)
       (let* ((user-instance (hash-ref *module-instances*
                                       (archive/unit-key user-id)
                                       #f))
              (exports (archive/module-instance-exports user-instance)))
         (assert-equal 84 (hash-ref exports 'doubled))))))))

(test "modules: bundle load resolves shuffled transitive dependencies" (lambda ()
  (let ((core-id '(module (phase-a graph-core) 0))
        (service-id '(module (phase-a graph-service) 0))
        (app-id '(module (phase-a graph-app) 0))
        (core-path ".tmp/phase-a-graph-core.scm")
        (service-path ".tmp/phase-a-graph-service.scm")
        (app-path ".tmp/phase-a-graph-app.scm")
        (bundle-path ".tmp/phase-a-graph.ecec"))
    (with-module-test-units*
     (list core-id service-id app-id)
     (lambda ()
       (write-module-test-file
        core-path
        "(define-module (phase-a graph-core)\n  (export base)\n  (define base 10)\n  base)\n")
       (write-module-test-file
        service-path
        "(define-module (phase-a graph-service)\n  (import (phase-a graph-core))\n  (export service)\n  (define service (+ base 5))\n  service)\n")
       (write-module-test-file
        app-path
        "(define-module (phase-a graph-app)\n  (import (phase-a graph-service))\n  (export main)\n  (define main (+ service 1))\n  main)\n")
       (compile-system (list app-path service-path core-path) bundle-path)
       (load-bundle bundle-path)
       (let* ((app-instance (hash-ref *module-instances*
                                      (archive/unit-key app-id)
                                      #f))
              (exports (archive/module-instance-exports app-instance)))
         (assert-equal 16 (hash-ref exports 'main))))))))

(test "modules: shared dependency is instantiated once" (lambda ()
  (let ((core-id '(module (phase-a shared-core) 0))
        (left-id '(module (phase-a shared-left) 0))
        (right-id '(module (phase-a shared-right) 0))
        (app-id '(module (phase-a shared-app) 0))
        (core-path ".tmp/phase-a-shared-core.scm")
        (left-path ".tmp/phase-a-shared-left.scm")
        (right-path ".tmp/phase-a-shared-right.scm")
        (app-path ".tmp/phase-a-shared-app.scm")
        (bundle-path ".tmp/phase-a-shared.ecec"))
    (with-module-test-units*
     (list core-id left-id right-id app-id)
     (lambda ()
       (set! phase-a-core-count 0)
       (write-module-test-file
        core-path
        "(define-module (phase-a shared-core)\n  (export value)\n  (define value (begin (set! phase-a-core-count (+ phase-a-core-count 1)) 5))\n  value)\n")
       (write-module-test-file
        left-path
        "(define-module (phase-a shared-left)\n  (import (phase-a shared-core))\n  (export left)\n  (define left value)\n  left)\n")
       (write-module-test-file
        right-path
        "(define-module (phase-a shared-right)\n  (import (phase-a shared-core))\n  (export right)\n  (define right value)\n  right)\n")
       (write-module-test-file
        app-path
        "(define-module (phase-a shared-app)\n  (import (phase-a shared-left) (phase-a shared-right))\n  (export total)\n  (define total (+ left right))\n  total)\n")
       (compile-system (list app-path left-path right-path core-path)
                       bundle-path)
       (load-bundle bundle-path)
       (let* ((app-instance (hash-ref *module-instances*
                                      (archive/unit-key app-id)
                                      #f))
              (exports (archive/module-instance-exports app-instance)))
         (assert-equal 1 phase-a-core-count)
         (assert-equal 10 (hash-ref exports 'total))))))))

(test "modules: graph loader missing module error names importer" (lambda ()
  (let ((user-id '(module (phase-a missing-user) 0))
        (missing-id '(module (phase-a missing-dep) 0))
        (user-path ".tmp/phase-a-missing-user.scm")
        (bundle-path ".tmp/phase-a-missing.ecec"))
    (with-module-test-units*
     (list user-id missing-id)
     (lambda ()
       (write-module-test-file
        user-path
        "(define-module (phase-a missing-user)\n  (import (phase-a missing-dep))\n  (export value)\n  (define value 1)\n  value)\n")
       (compile-system (list user-path) bundle-path)
       (let ((message (module-test-error-message
                       (lambda () (load-bundle bundle-path)))))
         (assert-true (string-contains? message "Module import not found"))
         (assert-true (string-contains? message "missing-user"))
         (assert-true (string-contains? message "missing-dep"))))))))

(test "modules: graph loader reports import cycles" (lambda ()
  (let ((a-id '(module (phase-a cycle-a) 0))
        (b-id '(module (phase-a cycle-b) 0))
        (c-id '(module (phase-a cycle-c) 0))
        (a-path ".tmp/phase-a-cycle-a.scm")
        (b-path ".tmp/phase-a-cycle-b.scm")
        (c-path ".tmp/phase-a-cycle-c.scm")
        (bundle-path ".tmp/phase-a-cycle.ecec"))
    (with-module-test-units*
     (list a-id b-id c-id)
     (lambda ()
       (write-module-test-file
        a-path
        "(define-module (phase-a cycle-a)\n  (import (phase-a cycle-b))\n  (export a)\n  (define a 1)\n  a)\n")
       (write-module-test-file
        b-path
        "(define-module (phase-a cycle-b)\n  (import (phase-a cycle-c))\n  (export b)\n  (define b 2)\n  b)\n")
       (write-module-test-file
        c-path
        "(define-module (phase-a cycle-c)\n  (import (phase-a cycle-a))\n  (export c)\n  (define c 3)\n  c)\n")
       (compile-system (list a-path b-path c-path) bundle-path)
       (let ((message (module-test-error-message
                       (lambda () (load-bundle bundle-path)))))
         (assert-true (string-contains? message "Module import cycle"))
         (assert-true (string-contains? message "cycle-a"))))))))

(test "modules: non-module archive unit cannot satisfy module import" (lambda ()
  (let* ((file-id '(module (phase-a file-unit) 0))
         (user-id '(module (phase-a imports-file) 0))
         (user-path ".tmp/phase-a-imports-file.scm")
         (bundle-path ".tmp/phase-a-imports-file.ecec")
         (file-archive
          (code-object->archive-sexp
           (mc-compile-to-code-object 123)
           "phase-a-file-unit.scm"
           (list ':unit-id file-id))))
    (with-module-test-units*
     (list file-id user-id)
     (lambda ()
       (write-module-test-file
        user-path
        "(define-module (phase-a imports-file)\n  (import (module (phase-a file-unit) 0))\n  (export value)\n  (define value 1)\n  value)\n")
       (let* ((sink (open-output-string)))
         (compile-file-to-archive user-path sink)
         (let ((user-archive
                (ece-scheme-read
                 (open-input-string (get-output-string sink)))))
           (write-module-test-archive-bundle
            bundle-path
            (list file-archive user-archive))))
       (let ((message (module-test-error-message
                       (lambda () (load-bundle bundle-path)))))
         (assert-true
          (string-contains? message
                            "does not name a module archive unit"))))))))
