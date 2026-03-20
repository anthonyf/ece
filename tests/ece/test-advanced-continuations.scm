;;; Advanced continuation tests
;;; Multiple invocation, parameterize interaction, mutable state.

(test "invoke continuation multiple times" (lambda ()
  (define results '())
  (define k #f)
  (define val (call/cc (lambda (c) (set k c) 0)))
  (set results (cons val results))
  (when (< val 3)
    (k (+ val 1)))
  ;; k was invoked with 1, 2, 3 — results accumulated in reverse
  (assert-equal results (list 3 2 1 0))))

(test "continuation as accumulator" (lambda ()
  (define total 0)
  (define k #f)
  (define n (call/cc (lambda (c) (set k c) 1)))
  (set total (+ total n))
  (cond
   ((= n 1) (k 2))
   ((= n 2) (k 3))
   ;; n=3: done
   )
  (assert-equal total 6)))  ;; 1+2+3

(test "continuation captured inside parameterize" (lambda ()
  (define p (make-parameter "outside"))
  (define k #f)
  (parameterize ((p "inside"))
    (call/cc (lambda (c) (set k c)))
    (assert-equal (p) "inside"))
  ;; After parameterize exits, p is restored
  (assert-equal (p) "outside")))

(test "nested parameterize with continuation" (lambda ()
  (define p (make-parameter 0))
  (define k #f)
  (parameterize ((p 10))
    (parameterize ((p 20))
      (set k (call/cc (lambda (c) c)))
      (assert-equal (p) 20))
    (assert-equal (p) 10))
  (assert-equal (p) 0)))

(test "continuation sees mutable state changes" (lambda ()
  ;; Mutable state via set-car!
  (define cell (cons 0 '()))
  (define k #f)
  (set k (call/cc (lambda (c) c)))
  ;; After first capture, cell is (0), after invoke cell is (99)
  (when (= (car cell) 0)
    (set-car! cell 99)
    (k k))  ;; re-invoke with self
  (assert-equal (car cell) 99)))
