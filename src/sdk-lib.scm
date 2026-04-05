;;; sdk-lib.scm — Shared ECE SDK helpers used by ece-main, ece-build, ece-test.
;;; Pure string/list operations. No host primitives beyond those in prelude.

;; ---- Path helpers ----

(define (ends-with? s suffix)
  "Return #t if string S ends with SUFFIX."
  (let ((slen (string-length s))
        (sulen (string-length suffix)))
    (if (< slen sulen)
        #f
        (string=? (substring s (- slen sulen) slen) suffix))))

(define (starts-with? s prefix)
  "Return #t if string S starts with PREFIX."
  (let ((slen (string-length s))
        (plen (string-length prefix)))
    (if (< slen plen)
        #f
        (string=? (substring s 0 plen) prefix))))

(define (has-extension? filename ext)
  "Return #t if FILENAME ends with .EXT."
  (ends-with? filename (string-append "." ext)))

(define (last-index-of s ch)
  "Return index of last occurrence of CH in S, or -1 if not present."
  (let loop ((i (- (string-length s) 1)))
    (cond
     ((< i 0) -1)
     ((char=? (string-ref s i) ch) i)
     (else (loop (- i 1))))))

(define (basename path)
  "Strip directory prefix from PATH."
  (let ((idx (last-index-of path #\/)))
    (if (< idx 0) path
        (substring path (+ idx 1) (string-length path)))))

(define (dirname path)
  "Return the directory part of PATH (without trailing /).
Returns \".\" when PATH has no directory component."
  (let ((idx (last-index-of path #\/)))
    (cond
     ((< idx 0) ".")
     ((= idx 0) "/")
     (else (substring path 0 idx)))))

(define (path-join . parts)
  "Join path components with /, stripping duplicate separators between them."
  (if (null? parts) ""
      (let loop ((rest (cdr parts)) (acc (car parts)))
        (if (null? rest) acc
            (let* ((next (car rest))
                   (acc-has-sep
                    (and (> (string-length acc) 0)
                         (char=? (string-ref acc (- (string-length acc) 1)) #\/)))
                   (next-has-sep
                    (and (> (string-length next) 0)
                         (char=? (string-ref next 0) #\/))))
              (loop (cdr rest)
                    (cond
                     ((and acc-has-sep next-has-sep)
                      (string-append acc (substring next 1 (string-length next))))
                     ((or acc-has-sep next-has-sep)
                      (string-append acc next))
                     (else
                      (string-append acc "/" next)))))))))

;; ---- Argument-parsing helpers ----

(define (split-on s ch)
  "Split S on character CH at the first occurrence. Returns two-element list
(before after), or one-element (s) if CH not present."
  (let loop ((i 0) (len (string-length s)))
    (cond
     ((>= i len) (list s))
     ((char=? (string-ref s i) ch)
      (list (substring s 0 i) (substring s (+ i 1) len)))
     (else (loop (+ i 1) len)))))

(define (parse-long-opt arg)
  "Parse a --name=value or --name long-option. Returns a list
 (name maybe-value-or-#f) or #f if ARG is not a long option."
  (let ((len (string-length arg)))
    (if (and (>= len 2)
             (char=? (string-ref arg 0) #\-)
             (char=? (string-ref arg 1) #\-))
        (let* ((body (substring arg 2 len))
               (parts (split-on body #\=)))
          (if (= (length parts) 2)
              (list (car parts) (cadr parts))
              (list body #f)))
        #f)))

(define (parse-short-opt arg)
  "Parse a -x short-option. Returns the option character as string, or #f."
  (let ((len (string-length arg)))
    (if (and (= len 2)
             (char=? (string-ref arg 0) #\-)
             (not (char=? (string-ref arg 1) #\-)))
        (substring arg 1 2)
        #f)))

(define (long-opt? arg)
  "Return #t if ARG starts with -- and is longer than 2 chars."
  (and (>= (string-length arg) 3)
       (char=? (string-ref arg 0) #\-)
       (char=? (string-ref arg 1) #\-)))

(define (short-opt? arg)
  "Return #t if ARG is a single-char flag like -x."
  (and (= (string-length arg) 2)
       (char=? (string-ref arg 0) #\-)
       (not (char=? (string-ref arg 1) #\-))))

(define (opt-terminator? arg)
  "Return #t if ARG is the -- option terminator."
  (and (= (string-length arg) 2)
       (string=? arg "--")))
