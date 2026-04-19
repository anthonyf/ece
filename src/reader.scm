;;; ECE Reader
;;; S-expression reader written in ECE, using port-based character I/O.
;;; Replaces CL's read after bootstrap.

;;; Source location tracking
;;; Maps cons cell identity (eq?) → (file line col) for each list read.
;;; Populated during reading, consumed by the compiler for source-map emission.
(define *source-locations* (%make-hash-table))
(define *source-file-name* #f)

;;; Helper: record source location for a list expression.
;;; Only records when *source-file-name* is set (compile-file context).
;;; REPL and eval-string expressions don't need source locations.
(define (record-source-location! expr file line col)
  (when (and file (pair? expr))
    (hash-set! *source-locations* expr (list file line col)))
  expr)

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
  ;; Callers (ece-scheme-read) read-char the initial char before calling us,
  ;; so port-col is one past initial-char. Characters inside the loop are
  ;; peek-char'd (not yet consumed), so port-col points at them directly.
  (when (char=? initial-char #\\)
    (bad-symbol-char port "" (- (port-col port) 1)))
  (define buf (string-append "" (string initial-char)))
  (let loop ()
    (let ((ch (peek-char port)))
      (cond
       ((or (eof? ch) (not (reader-identifier-char? ch)))
        (%intern-ece buf))
       ((char=? ch #\\)
        (bad-symbol-char port buf (port-col port)))
       (else
        (read-char port)
        (set! buf (string-append buf (string ch)))
        (loop))))))

;;; NOTE: Intentionally no R6RS-style `|foo|` pipe-escape handler here.
;;; The codegen-cl infrastructure (src/codegen-cl.scm) relies on `|foo|`
;;; in primitive source templates parsing as a symbol whose NAME literally
;;; includes the surrounding pipes. That way, templates like
;;; `'|continuation|` emit `'|continuation|` verbatim into generated CL,
;;; where CL's upcase reader sees the pipes as escapes and preserves the
;;; lowercase name. Adding pipe stripping here would silently break every
;;; primitive template that depends on this round-trip.
;;;
;;; Consequence: archive files (.ecec) contain pipe-escaped symbols like
;;; `|:hash-table|` whose semantics only the CL reader understands. Boot
;;; uses CL's reader; post-boot archive reads (e.g., from
;;; generate-all-zones-from-archive!) must either use CL's reader or a
;;; dedicated archive parser that understands this convention.

;;; Signal a reader error for a stray backslash inside a bare symbol token.
;;; Includes source location when *source-file-name* is set. COL is the
;;; 0-indexed column of the offending backslash (caller supplies it because
;;; port-col points past or at the char depending on read-char vs peek-char).
(define (bad-symbol-char port partial col)
  (if *source-file-name*
      (error "invalid character in symbol: \\"
             partial
             (list *source-file-name* (port-line port) col))
      (error "invalid character in symbol: \\" partial)))

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
            (set! buf (string-append buf (string ch)))
            (loop))
          (let ((n (string->number buf)))
            (if n n
                ;; Not a valid number — treat as symbol (e.g., just "+" or "-")
                (%intern-ece buf)))))))

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
      (set! segments (cons buf segments))
      (set! buf "")))
  (let loop ()
    (let ((ch (read-char port)))
      (cond
       ((eof? ch) (error "Unexpected EOF in string"))
       ;; End of string
       ((char=? ch #\")
        (flush-buf!)
        (let ((segs (reverse segments)))
          (cond
           ;; Empty string — return literal ""
           ((null? segs) "")
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
           ((char=? next #\n) (set! buf (string-append buf (string #\newline))))
           ((char=? next #\t) (set! buf (string-append buf (string #\tab))))
           ((char=? next #\\) (set! buf (string-append buf "\\")))
           ((char=? next #\") (set! buf (string-append buf "\"")))
           (else (set! buf (string-append buf (string next))))))
        (loop))
       ;; Dollar interpolation
       ((char=? ch #\$)
        (let ((next (peek-char port)))
          (cond
           ;; $$ → literal $
           ((and (not (eof? next)) (char=? next #\$))
            (read-char port)
            (set! buf (string-append buf "$"))
            (loop))
           ;; $(expr) → read s-expression
           ((and (not (eof? next)) (char=? next #\())
            (flush-buf!)
            (set! segments (cons (ece-scheme-read port) segments))
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
                    (set! segments (cons (%intern-ece sym-buf)
                                         segments)))))
            (loop))
           ;; $ followed by non-identifier → literal $
           (else
            (set! buf (string-append buf "$"))
            (loop)))))
       ;; Regular character
       (else
        (set! buf (string-append buf (string ch)))
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
                  (set! name (string-append name (string nc)))
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
        ;; Return (hash-table 'key1 val1 'key2 val2 ...) form for the compiler
        ;; Keys are quoted so symbols evaluate to themselves.
        (let ((elems (reverse items)))
          (if (odd? (length elems))
              (error "Odd number of elements in hash table literal")
              (cons 'hash-table
                    (let quote-keys ((lst elems) (is-key #t))
                      (if (null? lst)
                          '()
                          (cons (if is-key (list 'quote (car lst)) (car lst))
                                (quote-keys (cdr lst) (not is-key)))))))))
       (else
        (set! items (cons (ece-scheme-read port) items))
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
     ;; #t → #t
     ((or (char=? ch #\t) (char=? ch #\T))
      #t)
     ;; #f → #f
     ((or (char=? ch #\f) (char=? ch #\F))
      #f)
     (else
      (error (string-append "Unknown # dispatch: #" (string ch)))))))

;;; Main reader dispatch
(define (ece-scheme-read port)
  "Read one s-expression from PORT."
  (let ((ch (skip-whitespace-and-comments port)))
    (cond
     ;; EOF
     ((eof? ch) ch)
     ;; List — capture position of opening paren
     ((char=? ch #\()
      (if *source-file-name*
          (let ((file *source-file-name*)
                (line (port-line port))
                (col (port-col port)))
            (read-char port)
            (record-source-location! (read-list port) file line col))
          (begin (read-char port) (read-list port))))
     ;; Quote shorthand — capture position of '
     ((char=? ch #\')
      (if *source-file-name*
          (let ((file *source-file-name*)
                (line (port-line port))
                (col (port-col port)))
            (read-char port)
            (record-source-location!
             (list 'quote (ece-scheme-read port)) file line col))
          (begin (read-char port) (list 'quote (ece-scheme-read port)))))
     ;; Quasiquote
     ((char=? ch #\`)
      (if *source-file-name*
          (let ((file *source-file-name*)
                (line (port-line port))
                (col (port-col port)))
            (read-char port)
            (record-source-location!
             (list 'quasiquote (ece-scheme-read port)) file line col))
          (begin (read-char port) (list 'quasiquote (ece-scheme-read port)))))
     ;; Unquote / unquote-splicing
     ((char=? ch #\,)
      (if *source-file-name*
          (let ((file *source-file-name*)
                (line (port-line port))
                (col (port-col port)))
            (read-char port)
            (let ((next (peek-char port)))
              (if (and (not (eof? next)) (char=? next #\@))
                  (begin
                    (read-char port)
                    (record-source-location!
                     (list 'unquote-splicing (ece-scheme-read port)) file line col))
                  (record-source-location!
                   (list 'unquote (ece-scheme-read port)) file line col))))
          (begin
            (read-char port)
            (let ((next (peek-char port)))
              (if (and (not (eof? next)) (char=? next #\@))
                  (begin (read-char port) (list 'unquote-splicing (ece-scheme-read port)))
                  (list 'unquote (ece-scheme-read port)))))))
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
