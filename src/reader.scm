;;; ECE Reader
;;; S-expression reader written in ECE, using port-based character I/O.
;;; Replaces CL's read after bootstrap.

;;; Helper: is this a delimiter character?
(define (reader-delimiter? ch)
  (or (char-whitespace? ch)
      (char=? ch #\()
      (char=? ch #\))
      (char=? ch #\")
      (char=? ch #\;)
      (char=? ch #\{)
      (char=? ch #\})))

;;; Helper: is this a valid identifier character?
(define (reader-identifier-char? ch)
  (and (not (reader-delimiter? ch))
       (not (eof? ch))))

;;; Helper: is this a valid string interpolation identifier character?
(define (reader-interp-identifier-char? ch)
  (and ch
       (not (eof? ch))
       (or (char-alphabetic? ch)
           (char-numeric? ch)
           (char=? ch #\-)
           (char=? ch #\?)
           (char=? ch #\!)
           (char=? ch #\*)
           (char=? ch #\>)
           (char=? ch #\<)
           (char=? ch #\_)
           (char=? ch #\/))))

;;; Skip whitespace and comments
(define (skip-whitespace-and-comments port)
  (let ((ch (peek-char port)))
    (cond
     ((eof? ch) ch)
     ((char-whitespace? ch)
      (read-char port)
      (skip-whitespace-and-comments port))
     ((char=? ch #\;)
      ;; Skip to end of line
      (let loop ((c (read-char port)))
        (cond
         ((eof? c) c)
         ((char=? c #\newline)
          (skip-whitespace-and-comments port))
         (else (loop (read-char port))))))
     (else ch))))

;;; Read a symbol
(define (read-symbol port initial-char)
  (define buf (string-append "" (string initial-char)))
  (let loop ()
    (let ((ch (peek-char port)))
      (if (and (not (eof? ch)) (reader-identifier-char? ch))
          (begin
            (read-char port)
            (set buf (string-append buf (string ch)))
            (loop))
          (%intern-ece (string-upcase buf))))))

;;; Read a number (integer or float)
(define (read-number port initial-char)
  (define buf (string-append "" (string initial-char)))
  (let loop ()
    (let ((ch (peek-char port)))
      (if (and (not (eof? ch))
               (or (char-numeric? ch)
                   (char=? ch #\.)))
          (begin
            (read-char port)
            (set buf (string-append buf (string ch)))
            (loop))
          (let ((n (string->number buf)))
            (if n n
                ;; Not a valid number — treat as symbol (e.g., just "+" or "-")
                (%intern-ece (string-upcase buf))))))))

;;; Read a string with escape sequences
(define (read-string-simple port)
  "Read a simple string (no interpolation check). Handles escapes."
  (let loop ((acc ""))
    (let ((ch (read-char port)))
      (cond
       ((eof? ch) (error "Unexpected EOF in string"))
       ((char=? ch #\")
        acc)
       ((char=? ch #\\)
        (let ((next (read-char port)))
          (cond
           ((eof? next) (error "Unexpected EOF in string escape"))
           ((char=? next #\n) (loop (string-append acc (string #\newline))))
           ((char=? next #\t) (loop (string-append acc (string #\tab))))
           ((char=? next #\\) (loop (string-append acc "\\")))
           ((char=? next #\") (loop (string-append acc "\"")))
           (else (loop (string-append acc (string next)))))))
       (else
        (loop (string-append acc (string ch))))))))

;;; Read a string with interpolation support
(define (read-string-with-interpolation port)
  "Read a double-quoted string with interpolation support."
  (define segments '())
  (define buf "")
  (define (flush-buf!)
    (when (> (string-length buf) 0)
      (set segments (cons buf segments))
      (set buf "")))
  (let loop ()
    (let ((ch (read-char port)))
      (cond
       ((eof? ch) (error "Unexpected EOF in string"))
       ;; End of string
       ((char=? ch #\")
        (flush-buf!)
        (let ((segs (reverse segments)))
          (cond
           ;; Single literal string — return directly
           ((and (= (length segs) 1) (string? (car segs)))
            (car segs))
           ;; Single non-string expression — wrap in write-to-string
           ((and (= (length segs) 1) (not (string? (car segs))))
            (list 'write-to-string (car segs)))
           ;; Mixed — build (string-append ...) with write-to-string for non-strings
           (else
            (cons 'string-append
                  (map (lambda (seg)
                         (if (string? seg)
                             seg
                             (list 'write-to-string seg)))
                       segs))))))
       ;; Backslash escape
       ((char=? ch #\\)
        (let ((next (read-char port)))
          (cond
           ((eof? next) (error "Unexpected EOF in string escape"))
           ((char=? next #\n) (set buf (string-append buf (string #\newline))))
           ((char=? next #\t) (set buf (string-append buf (string #\tab))))
           ((char=? next #\\) (set buf (string-append buf "\\")))
           ((char=? next #\") (set buf (string-append buf "\"")))
           (else (set buf (string-append buf (string next))))))
        (loop))
       ;; Dollar interpolation
       ((char=? ch #\$)
        (let ((next (peek-char port)))
          (cond
           ;; $$ → literal $
           ((and (not (eof? next)) (char=? next #\$))
            (read-char port)
            (set buf (string-append buf "$"))
            (loop))
           ;; $(expr) → read s-expression
           ((and (not (eof? next)) (char=? next #\())
            (flush-buf!)
            (set segments (cons (ece-scheme-read port) segments))
            (loop))
           ;; $identifier → read symbol name
           ((and (not (eof? next)) (reader-interp-identifier-char? next))
            (flush-buf!)
            (let iloop ((sym-buf ""))
              (let ((sc (peek-char port)))
                (if (and (not (eof? sc)) (reader-interp-identifier-char? sc))
                    (begin
                      (read-char port)
                      (iloop (string-append sym-buf (string sc))))
                    (set segments (cons (%intern-ece (string-upcase sym-buf))
                                        segments)))))
            (loop))
           ;; $ followed by non-identifier → literal $
           (else
            (set buf (string-append buf "$"))
            (loop)))))
       ;; Regular character
       (else
        (set buf (string-append buf (string ch)))
        (loop))))))

;;; Read a list (after opening paren has been consumed)
(define (read-list port)
  (skip-whitespace-and-comments port)
  (let ((ch (peek-char port)))
    (cond
     ((eof? ch) (error "Unexpected EOF in list"))
     ((char=? ch #\))
      (read-char port)
      '())
     (else
      (let ((first (ece-scheme-read port)))
        ;; Check for dotted pair
        (skip-whitespace-and-comments port)
        (let ((next-ch (peek-char port)))
          (if (and (not (eof? next-ch)) (char=? next-ch #\.))
              ;; Might be a dotted pair — check if next char after dot is delimiter
              (begin
                (read-char port) ; consume the dot
                (let ((after-dot (peek-char port)))
                  (if (or (eof? after-dot)
                          (char-whitespace? after-dot)
                          (char=? after-dot #\()
                          (char=? after-dot #\")
                          (char=? after-dot #\;))
                      ;; It's a dotted pair
                      (let ((rest (ece-scheme-read port)))
                        (skip-whitespace-and-comments port)
                        (let ((close (read-char port)))
                          (if (and (not (eof? close)) (char=? close #\)))
                              (cons first rest)
                              (error "Expected ) after dotted pair"))))
                      ;; Not a dotted pair — it's a symbol starting with .
                      ;; Put the dot back by making a symbol
                      (let ((sym (read-symbol port #\.)))
                        (cons first (cons sym (read-list port)))))))
              ;; Normal list element
              (cons first (read-list port)))))))))

;;; Read a character literal (after #\ has been consumed)
(define (read-character port)
  (let ((ch (read-char port)))
    (cond
     ((eof? ch) (error "Unexpected EOF in character literal"))
     ;; Check for named characters
     ((and (char-alphabetic? ch)
           (let ((next (peek-char port)))
             (and (not (eof? next)) (char-alphabetic? next))))
      ;; Multi-character name — read the rest
      (let ((name (string-append "" (string ch))))
        (let loop ()
          (let ((nc (peek-char port)))
            (if (and (not (eof? nc)) (char-alphabetic? nc))
                (begin
                  (read-char port)
                  (set name (string-append name (string nc)))
                  (loop))
                (let ((lower-name (string-downcase name)))
                  (cond
                   ((string=? lower-name "space") #\space)
                   ((string=? lower-name "newline") #\newline)
                   ((string=? lower-name "tab") #\tab)
                   ((string=? lower-name "return") (integer->char 13))
                   ((string=? lower-name "page") (integer->char 12))
                   (else (error (string-append "Unknown character name: " name))))))))))
     ;; Single character
     (else ch))))

;;; Read a vector literal (after #( has been consumed — ( still to consume)
(define (read-vector port)
  ;; Opening paren already consumed by hash dispatch
  (let ((elems (read-list port)))
    (list->vector elems)))

;;; Read a hash table literal (after { has been consumed)
(define (read-hash-table-literal port)
  (define items '())
  (let loop ()
    (skip-whitespace-and-comments port)
    (let ((ch (peek-char port)))
      (cond
       ((eof? ch) (error "Unexpected EOF in hash table literal"))
       ((char=? ch #\})
        (read-char port)
        ;; Build HAMT from flat key-value list
        (let build ((lst (reverse items)) (root '()) (count 0))
          (if (null? lst)
              (cons :hash-table (cons count root))
              (if (null? (cdr lst))
                  (error "Odd number of elements in hash table literal")
                  (let* ((key (car lst))
                         (val (cadr lst))
                         (result (hamt-insert root key val (hash-code key) 0))
                         (new-root (car result))
                         (added? (cdr result)))
                    (build (cddr lst) new-root
                           (if added? (+ count 1) count)))))))
       (else
        (set items (cons (ece-scheme-read port) items))
        (loop))))))

;;; Hash dispatch (after # has been consumed)
(define (read-hash-dispatch port)
  (let ((ch (read-char port)))
    (cond
     ((eof? ch) (error "Unexpected EOF after #"))
     ;; #\ character literal
     ((char=? ch #\\)
      (read-character port))
     ;; #( vector literal
     ((char=? ch #\()
      (read-vector port))
     ;; #t → t
     ((or (char=? ch #\t) (char=? ch #\T))
      t)
     ;; #f → ()
     ((or (char=? ch #\f) (char=? ch #\F))
      '())
     (else
      (error (string-append "Unknown # dispatch: #" (string ch)))))))

;;; Main reader dispatch
(define (ece-scheme-read port)
  "Read one s-expression from PORT."
  (let ((ch (skip-whitespace-and-comments port)))
    (cond
     ;; EOF
     ((eof? ch) ch)
     ;; List
     ((char=? ch #\()
      (read-char port)
      (read-list port))
     ;; Quote shorthand
     ((char=? ch #\')
      (read-char port)
      (list 'quote (ece-scheme-read port)))
     ;; Quasiquote
     ((char=? ch #\`)
      (read-char port)
      (list 'quasiquote (ece-scheme-read port)))
     ;; Unquote / unquote-splicing
     ((char=? ch #\,)
      (read-char port)
      (let ((next (peek-char port)))
        (if (and (not (eof? next)) (char=? next #\@))
            (begin
              (read-char port)
              (list 'unquote-splicing (ece-scheme-read port)))
            (list 'unquote (ece-scheme-read port)))))
     ;; String
     ((char=? ch #\")
      (read-char port)
      (read-string-with-interpolation port))
     ;; Hash dispatch
     ((char=? ch #\#)
      (read-char port)
      (read-hash-dispatch port))
     ;; Hash table literal
     ((char=? ch #\{)
      (read-char port)
      (read-hash-table-literal port))
     ;; Digit — always a number
     ((char-numeric? ch)
      (read-char port)
      (read-number port ch))
     ;; Sign — could be number or symbol
     ((or (char=? ch #\+) (char=? ch #\-))
      (read-char port)
      (let ((next (peek-char port)))
        (if (and (not (eof? next))
                 (or (char-numeric? next) (char=? next #\.)))
            (read-number port ch)
            ;; It's a symbol like + or -
            (read-symbol port ch))))
     ;; Closing paren (error in top-level context)
     ((char=? ch #\))
      (read-char port)
      (error "Unexpected )"))
     ;; Closing brace
     ((char=? ch #\})
      (read-char port)
      (error "Unexpected }"))
     ;; Symbol (anything else)
     (else
      (read-char port)
      (read-symbol port ch)))))

;;; Switchover: rebind read to use the ECE reader.
;;; The REPL calls (read) which previously routed to CL's ece-read.
;;; Now it routes to ece-scheme-read with the default port.
(define (read . args)
  (if (null? args)
      (ece-scheme-read (current-input-port))
      (ece-scheme-read (car args))))
