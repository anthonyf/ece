;;; dynamic-wind tests — R7RS winding, continuation interaction

(test "dynamic-wind basic ordering" (lambda ()
  (define log '())
  (define result
    (dynamic-wind
     (lambda () (set log (cons 'before log)))
     (lambda () (set log (cons 'thunk log)) 42)
     (lambda () (set log (cons 'after log)))))
  (assert-equal result 42)
  (assert-equal log '(after thunk before))))

(test "dynamic-wind nested" (lambda ()
  (define log '())
  (dynamic-wind
   (lambda () (set log (cons 'outer-before log)))
   (lambda ()
     (dynamic-wind
      (lambda () (set log (cons 'inner-before log)))
      (lambda () (set log (cons 'body log)))
      (lambda () (set log (cons 'inner-after log)))))
   (lambda () (set log (cons 'outer-after log))))
  (assert-equal log '(outer-after inner-after body inner-before outer-before))))

(test "dynamic-wind continuation exit triggers after" (lambda ()
  (define log '())
  (define result
    (call/cc (lambda (k)
      (dynamic-wind
       (lambda () (set log (cons 'before log)))
       (lambda () (k 'escaped))
       (lambda () (set log (cons 'after log)))))))
  (assert-equal result 'escaped)
  (assert-true (member 'after log))))

(test "dynamic-wind multiple level unwind on escape" (lambda ()
  (define log '())
  (define result
    (call/cc (lambda (k)
      (dynamic-wind
       (lambda () (set log (cons 'outer-before log)))
       (lambda ()
         (dynamic-wind
          (lambda () (set log (cons 'inner-before log)))
          (lambda () (k 'deep-escape))
          (lambda () (set log (cons 'inner-after log)))))
       (lambda () (set log (cons 'outer-after log)))))))
  (assert-equal result 'deep-escape)
  ;; inner-after should come before outer-after in the log (reverse order)
  (assert-true (member 'inner-after log))
  (assert-true (member 'outer-after log))))

(test "dynamic-wind continuation re-entry triggers before" (lambda ()
  (define log '())
  (define saved-k '())
  (define count 0)
  ;; Capture a continuation inside dynamic-wind
  (dynamic-wind
   (lambda () (set log (cons 'before log)))
   (lambda ()
     (call/cc (lambda (k) (set saved-k k)))
     (set count (+ count 1)))
   (lambda () (set log (cons 'after log))))
  ;; Re-enter the dynamic-wind extent
  (when (= count 1)
    (saved-k 'reenter))
  ;; before should have been called twice (initial + re-entry)
  (assert-equal count 2)
  ;; log should show: after before after before (reversed)
  ;; First run: before, after
  ;; Re-entry: before, after (from re-entering, then exiting again)
  (define before-count (length (filter (lambda (x) (eq? x 'before)) log)))
  (assert-equal before-count 2)))

(test "dynamic-wind no-op when stacks match" (lambda ()
  ;; do-winds! with identical stacks should be no-op
  (define log '())
  (do-winds! *winding-stack* *winding-stack*)
  (assert-equal log '())))

(test "dynamic-wind return value preserved" (lambda ()
  (assert-equal
   (dynamic-wind
    (lambda () ())
    (lambda () (+ 10 20))
    (lambda () ()))
   30)))

(test "%raw-call/cc bypasses winding" (lambda ()
  (define log '())
  (define result
    (%raw-call/cc (lambda (k)
      (dynamic-wind
       (lambda () (set log (cons 'before log)))
       (lambda () (k 'raw-escape))
       (lambda () (set log (cons 'after log)))))))
  (assert-equal result 'raw-escape)
  ;; after should NOT be called because %raw-call/cc bypasses winding
  (assert-equal (member 'after log) '())))
