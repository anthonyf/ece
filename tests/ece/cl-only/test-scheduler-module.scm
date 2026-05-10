;;; Tests for the scheduler module boundary.

(define (scheduler-module/test-cleanup! unit-ids)
  (for-each
   (lambda (unit-id)
     (let ((key (archive/unit-key unit-id)))
       (hash-remove! *archive-units* key)
       (hash-remove! *module-instances* key)))
   unit-ids))

(define (scheduler-module/write-file filename text)
  (let ((port #f))
    (dynamic-wind
     (lambda () (set! port (open-output-file filename)))
     (lambda () (display text port))
     (lambda () (when port (close-output-port port))))))

(define scheduler-module/unit-ids
  '((module (ece scheduler) 0)))

(define scheduler-module/modules-loaded? #f)

(define (scheduler-module/ensure-modules!)
  (when (not scheduler-module/modules-loaded?)
    (scheduler-module/test-cleanup! scheduler-module/unit-ids)
    (compile-system
     (list "src/scheduler.scm" "src/scheduler-module.scm")
     ".tmp/scheduler-module.ecec")
    (load-bundle ".tmp/scheduler-module.ecec")
    (set! scheduler-module/modules-loaded? #t)))

(test "scheduler module: exports public scheduler operations" (lambda ()
  (scheduler-module/ensure-modules!)
  (for-each
   (lambda (name)
     (assert-true
      (procedure? (archive/module-export '(ece scheduler) name))))
   '(make-scheduler
     scheduler?
     fiber?
     fiber-done?
     fiber-id
     scheduler-current-fiber
     scheduler-ready-count
     scheduler-waiting-count
     scheduler-spawn!
     wait-for
     scheduler-notify!
     scheduler-step!
     scheduler-poll-events!
     scheduler-run!
     scheduler-register-event-source!))))

(test "scheduler module: exported operations run fibers" (lambda ()
  (scheduler-module/ensure-modules!)
  (let* ((make (archive/module-export '(ece scheduler) 'make-scheduler))
         (spawn! (archive/module-export '(ece scheduler) 'scheduler-spawn!))
         (run! (archive/module-export '(ece scheduler) 'scheduler-run!))
         (ready-count
          (archive/module-export '(ece scheduler) 'scheduler-ready-count))
         (sched (make))
         (log '()))
    (spawn! sched (lambda () (set! log (cons 'a log))))
    (spawn! sched (lambda () (set! log (cons 'b log))))
    (assert-equal (ready-count sched) 2)
    (assert-equal (run! sched) 'done)
    (assert-equal (reverse log) '(a b)))))

(test "scheduler module: imported names work in app modules" (lambda ()
  (scheduler-module/ensure-modules!)
  (let ((unit-id '(module (scheduler-module test-app) 0))
        (source ".tmp/scheduler-module-test-app.scm")
        (bundle ".tmp/scheduler-module-test-app.ecec"))
    (dynamic-wind
     (lambda () (scheduler-module/test-cleanup! (list unit-id)))
     (lambda ()
       (scheduler-module/write-file
        source
        "(define-module (scheduler-module test-app)\n  (import (ece scheduler))\n  (export run-demo)\n  (define (run-demo)\n    (let ((sched (make-scheduler))\n          (log '()))\n      (scheduler-spawn! sched (lambda ()\n                                (set! log (cons 'ready log))))\n      (scheduler-run! sched)\n      (reverse log))))\n")
       (compile-system (list source) bundle)
       (load-bundle bundle)
       (assert-equal
        ((archive/module-export '(scheduler-module test-app) 'run-demo))
        '(ready)))
     (lambda () (scheduler-module/test-cleanup! (list unit-id)))))))
