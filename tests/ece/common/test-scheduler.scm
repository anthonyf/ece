;;; Unit tests for src/scheduler.scm — the cooperative fiber scheduler.
;;;
;;; Tests cover the baseline properties the ece-serve design doc mandates:
;;;   - spawn + step lets a single fiber run to completion or yield
;;;   - two fibers interleave via wait-for + notify
;;;   - a fiber that finishes normally is reported as done
;;;   - scheduler-notify! only wakes fibers matching the tag
;;;   - scheduler-run! drains both ready and waiting queues
;;;   - event sources plug into scheduler-run! and can notify
;;;
;;; These tests exercise the call/cc dance in isolation — no TCP, no fs-watch,
;;; no networking. If any of these fail, the server logic in section 4 of
;;; ece-serve cannot be trusted.

;; ── Single-fiber lifecycle ──────────────────────────────────────────────

(test "scheduler: fresh scheduler is idle" (lambda ()
  (let ((s (make-scheduler)))
    (assert-true (scheduler? s))
    (assert-equal (scheduler-ready-count s) 0)
    (assert-equal (scheduler-waiting-count s) 0)
    (assert-equal (scheduler-step! s) 'idle))))

(test "scheduler: spawn a fiber that runs to completion via step" (lambda ()
  (let* ((s (make-scheduler))
         (result-box (cons #f #f))
         (f (scheduler-spawn! s (lambda ()
                                  (set-car! result-box 'ran)))))
    (assert-true (fiber? f))
    (assert-true (integer? (fiber-id f)))
    (assert-equal (scheduler-ready-count s) 1)
    (assert-false (fiber-done? f))
    (scheduler-step! s)
    (assert-true (fiber-done? f))
    (assert-equal (car result-box) 'ran)
    (assert-equal (scheduler-ready-count s) 0)
    (assert-equal (scheduler-waiting-count s) 0))))

(test "scheduler: step with nothing to do is idle" (lambda ()
  (let ((s (make-scheduler)))
    (assert-equal (scheduler-step! s) 'idle)
    (assert-equal (scheduler-run! s) 'done))))

;; ── Yield + notify ──────────────────────────────────────────────────────

(test "scheduler: wait-for suspends fiber until notify" (lambda ()
  (let* ((s (make-scheduler))
         (log '())
         (f (scheduler-spawn! s (lambda ()
                                  (set! log (cons 'before log))
                                  (wait-for s 'signal)
                                  (set! log (cons 'after log))))))
    (scheduler-step! s)
    ;; The fiber ran up to wait-for and suspended
    (assert-equal log '(before))
    (assert-false (fiber-done? f))
    (assert-equal (scheduler-waiting-count s) 1)
    (assert-equal (scheduler-ready-count s) 0)
    ;; Notify wakes the fiber
    (assert-equal (scheduler-notify! s 'signal) 1)
    (assert-equal (scheduler-waiting-count s) 0)
    (assert-equal (scheduler-ready-count s) 1)
    ;; Step runs it through
    (scheduler-step! s)
    (assert-equal log '(after before))
    (assert-true (fiber-done? f)))))

(test "scheduler: two fibers interleave via wait-for (FIFO wakeup)" (lambda ()
  (let* ((s (make-scheduler))
         (log '())
         (log! (lambda (x) (set! log (cons x log)))))
    (scheduler-spawn! s (lambda ()
                          (log! 'a1)
                          (wait-for s 'tick)
                          (log! 'a2)))
    (scheduler-spawn! s (lambda ()
                          (log! 'b1)
                          (wait-for s 'tick)
                          (log! 'b2)))
    (scheduler-step! s)
    ;; Both fibers ran up to their wait-for
    (assert-equal (reverse log) '(a1 b1))
    (assert-equal (scheduler-waiting-count s) 2)
    ;; One notify wakes BOTH fibers (tag-only match). FIFO order:
    ;; A yielded first, so A resumes first.
    (assert-equal (scheduler-notify! s 'tick) 2)
    (scheduler-step! s)
    (assert-equal (reverse log) '(a1 b1 a2 b2)))))

(test "scheduler: notify with mismatched tag wakes nobody" (lambda ()
  (let ((s (make-scheduler)))
    (scheduler-spawn! s (lambda () (wait-for s 'needle)))
    (scheduler-step! s)
    (assert-equal (scheduler-waiting-count s) 1)
    (assert-equal (scheduler-notify! s 'haystack) 0)
    (assert-equal (scheduler-waiting-count s) 1))))

(test "scheduler: notify only wakes fibers with the matching tag" (lambda ()
  (let* ((s (make-scheduler))
         (log '())
         (log! (lambda (x) (set! log (cons x log)))))
    (scheduler-spawn! s (lambda () (wait-for s 'red) (log! 'red-done)))
    (scheduler-spawn! s (lambda () (wait-for s 'blue) (log! 'blue-done)))
    (scheduler-step! s)
    (assert-equal (scheduler-notify! s 'red) 1)
    (assert-equal (scheduler-waiting-count s) 1)
    (scheduler-step! s)
    (assert-equal (reverse log) '(red-done))
    (assert-equal (scheduler-notify! s 'blue) 1)
    (scheduler-step! s)
    (assert-equal (reverse log) '(red-done blue-done)))))

(test "scheduler: FIFO order survives notifies of interleaved tags" (lambda ()
  ;; Four fibers wait in alternating tags: A(red) B(blue) C(red) D(blue).
  ;; Notify blue first (wakes B and D). A and C must remain in the waiting
  ;; set IN ORIGINAL ORDER — without the reverse fix in waiting-remove-matching!
  ;; they'd end up reversed, and the subsequent red notify would run C before A.
  (let* ((s (make-scheduler))
         (log '())
         (log! (lambda (x) (set! log (cons x log)))))
    (scheduler-spawn! s (lambda () (wait-for s 'red)  (log! 'a-red)))
    (scheduler-spawn! s (lambda () (wait-for s 'blue) (log! 'b-blue)))
    (scheduler-spawn! s (lambda () (wait-for s 'red)  (log! 'c-red)))
    (scheduler-spawn! s (lambda () (wait-for s 'blue) (log! 'd-blue)))
    (scheduler-step! s)
    (assert-equal (scheduler-waiting-count s) 4)
    ;; Notify blue — wakes B and D in FIFO order.
    (assert-equal (scheduler-notify! s 'blue) 2)
    (scheduler-step! s)
    (assert-equal (reverse log) '(b-blue d-blue))
    ;; A and C still waiting, and must remain in their original order.
    (assert-equal (scheduler-waiting-count s) 2)
    (assert-equal (scheduler-notify! s 'red) 2)
    (scheduler-step! s)
    ;; If waiting order was preserved, A runs before C.
    (assert-equal (reverse log) '(b-blue d-blue a-red c-red)))))

;; ── Scheduler-run! ──────────────────────────────────────────────────────

(test "scheduler-run!: drains ready queue of independent fibers" (lambda ()
  (let* ((s (make-scheduler))
         (counter 0))
    (scheduler-spawn! s (lambda () (set! counter (+ counter 1))))
    (scheduler-spawn! s (lambda () (set! counter (+ counter 10))))
    (scheduler-spawn! s (lambda () (set! counter (+ counter 100))))
    (assert-equal (scheduler-run! s) 'done)
    (assert-equal counter 111))))

(test "scheduler-run!: reports deadlock when fibers wait with no sources" (lambda ()
  (let ((s (make-scheduler)))
    (scheduler-spawn! s (lambda () (wait-for s 'never-notified)))
    (assert-equal (scheduler-run! s) 'deadlock)
    (assert-equal (scheduler-waiting-count s) 1))))

;; ── Event sources ───────────────────────────────────────────────────────

(test "scheduler: event source can wake a waiting fiber during run!" (lambda ()
  ;; Source unconditionally notifies 'source-event each poll — this is how
  ;; real event sources behave (they fire when their underlying state says
  ;; "ready", regardless of whether any fiber is currently waiting). Polls
  ;; that happen before the fiber is waiting are no-ops because no fibers
  ;; match the tag.
  (let* ((s (make-scheduler))
         (log '())
         (source (lambda (sched) (scheduler-notify! sched 'source-event))))
    (scheduler-register-event-source! s source)
    (scheduler-spawn! s (lambda ()
                          (set! log (cons 'a1 log))
                          (wait-for s 'source-event)
                          (set! log (cons 'a2 log))
                          (wait-for s 'source-event)
                          (set! log (cons 'a3 log))))
    (assert-equal (scheduler-run! s) 'done)
    (assert-equal (reverse log) '(a1 a2 a3)))))

(test "scheduler: fiber spawning another fiber mid-run" (lambda ()
  (let* ((s (make-scheduler))
         (log '())
         (log! (lambda (x) (set! log (cons x log)))))
    (scheduler-spawn! s (lambda ()
                          (log! 'parent-before)
                          (scheduler-spawn! s (lambda () (log! 'child)))
                          (log! 'parent-after)))
    (scheduler-run! s)
    ;; FIFO order: parent completes before child runs because the child
    ;; is pushed to the back of the ready queue.
    (assert-equal (reverse log) '(parent-before parent-after child)))))

(test "scheduler: current-fiber reflects the running fiber" (lambda ()
  (let* ((s (make-scheduler))
         (seen #f))
    (scheduler-spawn! s (lambda ()
                          (set! seen (scheduler-current-fiber s))))
    (assert-false (scheduler-current-fiber s))
    (scheduler-step! s)
    (assert-true (fiber? seen))
    (assert-false (scheduler-current-fiber s)))))

;; ── Error cases ─────────────────────────────────────────────────────────

(test "scheduler: wait-for outside a fiber raises an error" (lambda ()
  (let ((s (make-scheduler)))
    (assert-error (wait-for s 'any-tag)))))
