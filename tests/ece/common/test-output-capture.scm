;;; Output capture tests — R7RS with-output-to-string / with-input-from-string

(test "with-output-to-string captures display" (lambda ()
  (assert-equal (with-output-to-string (display "hello")) "hello")))

(test "with-output-to-string captures multiple writes" (lambda ()
  (assert-equal (with-output-to-string
                 (display "a")
                 (display "b")
                 (newline))
                "ab\n")))

(test "with-output-to-string captures write in readable form" (lambda ()
  (assert-equal (with-output-to-string (write "hi")) "\"hi\"")))

(test "with-output-to-string does not leak after body exits" (lambda ()
  ;; Capture, then ensure subsequent output goes to the outer port.
  (with-output-to-string (display "x"))
  (assert-equal (with-output-to-string (display "y")) "y")))

(test "with-output-to-string nested captures are disjoint" (lambda ()
  (let ((outer (with-output-to-string
                (display "outer-pre")
                (let ((inner (with-output-to-string (display "inner"))))
                  (display "outer-post")
                  (assert-equal inner "inner")))))
    (assert-equal outer "outer-preouter-post"))))

(test "with-output-to-string restores port on error" (lambda ()
  (let ((p0 (current-output-port)))
    (let ((result (guard (e (#t 'caught))
                    (with-output-to-string (display "before") (raise 'boom)))))
      (assert-equal result 'caught)
      (assert-true (eq? p0 (current-output-port)))))))

(test "with-output-to-string captures write-char" (lambda ()
  (assert-equal (with-output-to-string (write-char #\X) (write-char #\Y)) "XY")))

(test "with-output-to-string captures write-string" (lambda ()
  (assert-equal (with-output-to-string (write-string "abc") (write-string "def"))
                "abcdef")))

(test "with-input-from-string reads characters" (lambda ()
  (assert-true (char=? (with-input-from-string "abc" (read-char)) #\a))))

(test "with-input-from-string reads structured data" (lambda ()
  (assert-equal (with-input-from-string "(1 2 3)" (read)) '(1 2 3))))

(test "with-input-from-string peek-char does not advance" (lambda ()
  (assert-equal
   (with-input-from-string "xy"
     (let ((p (peek-char)))
       (list p (read-char))))
   '(#\x #\x))))

(test "with-output-to-port uses supplied port" (lambda ()
  (let ((p (open-output-string)))
    (with-output-to-port p (display "hi"))
    (assert-equal (get-output-string p) "hi"))))

(test "with-input-from-port uses supplied port" (lambda ()
  (let ((p (open-input-string "xyz")))
    (assert-true (char=? (with-input-from-port p (read-char)) #\x)))))

(test "current-output-port is a parameter object" (lambda ()
  (assert-true (parameter? current-output-port))))

(test "current-input-port is a parameter object" (lambda ()
  (assert-true (parameter? current-input-port))))

(test "parameterize rebinds current-output-port across calls" (lambda ()
  (define (greet) (display "hello"))
  (let ((p (open-output-string)))
    (parameterize ((current-output-port p)) (greet))
    (assert-equal (get-output-string p) "hello"))))

(test "parameterize restores current-output-port after body" (lambda ()
  (let ((p0 (current-output-port)))
    (parameterize ((current-output-port (open-output-string))) (display "ignored"))
    (assert-true (eq? p0 (current-output-port))))))

(test "parameterize restores on guard-caught error" (lambda ()
  (let ((p0 (current-output-port)))
    (let ((result (guard (e (#t 'caught))
                    (parameterize ((current-output-port (open-output-string)))
                      (raise 'boom)))))
      (assert-equal result 'caught)
      (assert-true (eq? p0 (current-output-port)))))))

(test "parameterize restores on continuation escape" (lambda ()
  (let ((p0 (current-output-port)))
    (let ((result (call/cc (lambda (k)
                             (parameterize ((current-output-port (open-output-string)))
                               (k 'done))))))
      (assert-equal result 'done)
      (assert-true (eq? p0 (current-output-port)))))))
