;;; File I/O tests
;;; Verify port operations, read/write char, and file primitives.

(test "write-char and read-char round-trip" (lambda ()
  (define out (open-output-file "/tmp/ece-test-io.txt"))
  (write-char #\H out)
  (write-char #\i out)
  (close-output-port out)
  (define in (open-input-file "/tmp/ece-test-io.txt"))
  (assert-equal (read-char in) #\H)
  (assert-equal (read-char in) #\i)
  (close-input-port in)))

(test "peek-char doesn't consume" (lambda ()
  (define in (open-input-file "/tmp/ece-test-io.txt"))
  (define peeked (peek-char in))
  (define read1 (read-char in))
  (assert-equal peeked read1)
  (close-input-port in)))

(test "eof detection with read-char" (lambda ()
  (define out (open-output-file "/tmp/ece-test-io-eof.txt"))
  (write-char #\X out)
  (close-output-port out)
  (define in (open-input-file "/tmp/ece-test-io-eof.txt"))
  (read-char in)  ;; consume X
  (assert (eof? (read-char in)))
  (close-input-port in)))

(test "with-output-to-file writes content" (lambda ()
  (with-output-to-file "/tmp/ece-test-io-with.txt"
    (lambda () (display "hello from with-output-to-file")))
  (define in (open-input-file "/tmp/ece-test-io-with.txt"))
  (assert-equal (read-char in) #\h)
  (close-input-port in)))

(test "with-input-from-file reads content" (lambda ()
  ;; File already written by previous test
  (define result
    (with-input-from-file "/tmp/ece-test-io-with.txt"
      (lambda () (read-line))))
  (assert-equal result "hello from with-output-to-file")))

(test "read-line from file" (lambda ()
  (define out (open-output-file "/tmp/ece-test-io-lines.txt"))
  (display "line one" out)
  (newline out)
  (display "line two" out)
  (close-output-port out)
  (define in (open-input-file "/tmp/ece-test-io-lines.txt"))
  (assert-equal (read-line in) "line one")
  (assert-equal (read-line in) "line two")
  (close-input-port in)))
