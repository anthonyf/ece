;;; File I/O tests
;;; Verify port operations, read/write char, and file primitives.
;;; Guarded: requires filesystem primitives (CL only).

(when (platform-has? 'open-input-file)

(test "write-char and read-char round-trip" (lambda ()
  (let ((out (open-output-file ".tmp/ece-test-io.txt")))
    (write-char #\H out)
    (write-char #\i out)
    (close-output-port out))
  (let ((in (open-input-file ".tmp/ece-test-io.txt")))
    (assert-equal (read-char in) #\H)
    (assert-equal (read-char in) #\i)
    (close-input-port in))))

(test "peek-char doesn't consume" (lambda ()
  (let* ((in (open-input-file ".tmp/ece-test-io.txt"))
         (peeked (peek-char in))
         (read1 (read-char in)))
    (assert-equal peeked read1)
    (close-input-port in))))

(test "eof detection with read-char" (lambda ()
  (let ((out (open-output-file ".tmp/ece-test-io-eof.txt")))
    (write-char #\X out)
    (close-output-port out))
  (let ((in (open-input-file ".tmp/ece-test-io-eof.txt")))
    (read-char in)  ;; consume X
    (assert (eof? (read-char in)))
    (close-input-port in))))

(test "with-output-to-file writes content" (lambda ()
  (with-output-to-file ".tmp/ece-test-io-with.txt"
    (lambda () (display "hello from with-output-to-file")))
  (let ((in (open-input-file ".tmp/ece-test-io-with.txt")))
    (assert-equal (read-char in) #\h)
    (close-input-port in))))

(test "with-input-from-file reads content" (lambda ()
  ;; File already written by previous test
  (let ((result
         (with-input-from-file ".tmp/ece-test-io-with.txt"
           (lambda () (read-line)))))
    (assert-equal result "hello from with-output-to-file"))))

(test "read-line from file" (lambda ()
  (let ((out (open-output-file ".tmp/ece-test-io-lines.txt")))
    (display "line one" out)
    (newline out)
    (display "line two" out)
    (close-output-port out))
  (let ((in (open-input-file ".tmp/ece-test-io-lines.txt")))
    (assert-equal (read-line in) "line one")
    (assert-equal (read-line in) "line two")
    (close-input-port in))))

) ;; end platform-has? guard
