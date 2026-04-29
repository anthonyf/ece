;;; wasm-host.scm — ECE-level WASM host/native-zone loading policy.
;;;
;;; This module defines the ECE-facing surface for dynamic WASM host work.
;;; The actual browser capabilities (fetch, WebAssembly.instantiate, exported
;;; function references) are intentionally not implemented here yet; those are
;;; the next phase's host primitives. This file owns the policy-shaped parts
;;; that can already be tested in ordinary ECE: native-zone manifest parsing,
;;; validation, accessors, and the public loading API shape.

(define (wasm-host/error message)
  (error (string-append "wasm-host: " message)))

(define (wasm-host/not-implemented name)
  (wasm-host/error
   (string-append (symbol->string name)
                  " requires browser WASM host capabilities that are not implemented yet")))

(define (wasm-host/plist? plist)
  "Return #t when PLIST is a proper keyword plist."
  (cond
   ((null? plist) #t)
   ((not (pair? plist)) #f)
   ((not (keyword? (car plist))) #f)
   ((not (pair? (cdr plist))) #f)
   (else (wasm-host/plist? (cdr (cdr plist))))))

(define (wasm-host/plist-get plist key)
  "Return the value after KEY in PLIST, or #f when absent."
  (cond
   ((null? plist) #f)
   ((not (pair? plist)) #f)
   ((not (pair? (cdr plist))) #f)
   ((eq? (car plist) key) (car (cdr plist)))
   (else (wasm-host/plist-get (cdr (cdr plist)) key))))

(define (wasm-host/plist-has-key? plist key)
  "Return #t when PLIST contains KEY, preserving explicit #f values."
  (cond
   ((null? plist) #f)
   ((not (pair? plist)) #f)
   ((not (pair? (cdr plist))) #f)
   ((eq? (car plist) key) #t)
   (else (wasm-host/plist-has-key? (cdr (cdr plist)) key))))

(define (wasm-host/ensure-plist plist context)
  (when (not (wasm-host/plist? plist))
    (wasm-host/error (string-append context " must be a keyword plist"))))

(define (wasm-host/non-empty-string? value)
  (and (string? value) (> (string-length value) 0)))

(define (wasm-host/non-negative-integer? value)
  (and (integer? value) (>= value 0)))

(define (wasm-host/optional-string fields key context)
  (cond
   ((not (wasm-host/plist-has-key? fields key)) '())
   ((string? (wasm-host/plist-get fields key))
    (list key (wasm-host/plist-get fields key)))
   (else
    (wasm-host/error
     (string-append context " " (symbol->string key) " must be a string")))))

(define (wasm-host/validate-entry entry seen-indices)
  "Validate one native-zone manifest entry and return a normalized plist."
  (wasm-host/ensure-plist entry "native-zone entry")
  (let ((index (wasm-host/plist-get entry ':index))
        (export-name (wasm-host/plist-get entry ':export)))
    (cond
     ((not (wasm-host/plist-has-key? entry ':index))
      (wasm-host/error "native-zone entry missing :index"))
     ((not (wasm-host/non-negative-integer? index))
      (wasm-host/error "native-zone entry :index must be a non-negative integer"))
     ((member index seen-indices)
      (wasm-host/error "native-zone manifest has duplicate :index"))
     ((not (wasm-host/plist-has-key? entry ':export))
      (wasm-host/error "native-zone entry missing :export"))
     ((not (wasm-host/non-empty-string? export-name))
      (wasm-host/error "native-zone entry :export must be a non-empty string"))
     (else
      (append
       (list ':index index ':export export-name)
       (wasm-host/optional-string entry ':fingerprint "native-zone entry"))))))

(define (wasm-host/validate-entries entries)
  "Validate native-zone ENTRIES and return normalized entries."
  (cond
   ((not (list? entries))
    (wasm-host/error "native-zone manifest :entries must be a list"))
   (else
    (let loop ((rest entries) (seen '()) (acc '()))
      (cond
       ((null? rest) (reverse acc))
       (else
        (let* ((entry (wasm-host/validate-entry (car rest) seen))
               (index (native-zone-entry-index entry)))
          (loop (cdr rest) (cons index seen) (cons entry acc)))))))))

(define (validate-native-zone-manifest manifest)
  "Validate MANIFEST and return a normalized native-zone manifest plist.

Expected input shape:

  (:ece-native-zones
    :version 1
    :unit-id <archive-unit-id>
    :entries ((:index 0 :export \"zone_0\") ...))

Optional string fields are :source, :module-url, and per-entry :fingerprint."
  (cond
   ((not (and (pair? manifest) (eq? (car manifest) ':ece-native-zones)))
    (wasm-host/error "native-zone manifest must start with :ece-native-zones"))
   (else
    (let ((fields (cdr manifest)))
      (wasm-host/ensure-plist fields "native-zone manifest")
      (let ((version (wasm-host/plist-get fields ':version))
            (unit-id (wasm-host/plist-get fields ':unit-id))
            (entries (wasm-host/plist-get fields ':entries)))
        (cond
         ((not (wasm-host/plist-has-key? fields ':version))
          (wasm-host/error "native-zone manifest missing :version"))
         ((not (and (integer? version) (= version 1)))
          (wasm-host/error "native-zone manifest :version must be 1"))
         ((not (wasm-host/plist-has-key? fields ':unit-id))
          (wasm-host/error "native-zone manifest missing :unit-id"))
         ((not unit-id)
          (wasm-host/error "native-zone manifest :unit-id must not be #f"))
         ((not (wasm-host/plist-has-key? fields ':entries))
          (wasm-host/error "native-zone manifest missing :entries"))
         (else
          (append
           (list ':unit-id unit-id
                 ':entries (wasm-host/validate-entries entries))
           (wasm-host/optional-string fields ':source "native-zone manifest")
           (wasm-host/optional-string fields ':module-url "native-zone manifest")))))))))

(define (parse-native-zone-manifest text)
  "Read and validate a native-zone manifest from TEXT."
  (validate-native-zone-manifest
   (ece-scheme-read (open-input-string text))))

(define (native-zone-manifest-unit-id manifest)
  (wasm-host/plist-get manifest ':unit-id))

(define (native-zone-manifest-entries manifest)
  (wasm-host/plist-get manifest ':entries))

(define (native-zone-manifest-source manifest)
  (wasm-host/plist-get manifest ':source))

(define (native-zone-manifest-module-url manifest)
  (wasm-host/plist-get manifest ':module-url))

(define (native-zone-entry-index entry)
  (wasm-host/plist-get entry ':index))

(define (native-zone-entry-export-name entry)
  (wasm-host/plist-get entry ':export))

(define (native-zone-entry-fingerprint entry)
  (wasm-host/plist-get entry ':fingerprint))

(define (fetch-text url)
  (wasm-host/not-implemented 'fetch-text))

(define (fetch-bytes url)
  (wasm-host/not-implemented 'fetch-bytes))

(define (wasm-instantiate bytes imports)
  (wasm-host/not-implemented 'wasm-instantiate))

(define (wasm-export instance name)
  (wasm-host/not-implemented 'wasm-export))

(define (register-native-zone! unit-id co-index export-ref)
  (wasm-host/not-implemented 'register-native-zone!))

(define (native-zone-imports)
  "Return the import object for side-loaded native-zone modules.
Phase 1 has no host bridge yet, so this is an empty placeholder."
  '())

(define (load-native-zone-manifest manifest-url)
  "Fetch, read, and validate a native-zone manifest."
  (parse-native-zone-manifest (fetch-text manifest-url)))

(define (load-native-zone-module module-url manifest-url)
  "Fetch a native-zone module, instantiate it, and register its exports.
This policy is ECE-owned, but it depends on future browser host primitives."
  (let* ((manifest (load-native-zone-manifest manifest-url))
         (bytes (fetch-bytes module-url))
         (instance (wasm-instantiate bytes (native-zone-imports))))
    (for-each
     (lambda (entry)
       (register-native-zone!
        (native-zone-manifest-unit-id manifest)
        (native-zone-entry-index entry)
        (wasm-export instance (native-zone-entry-export-name entry))))
     (native-zone-manifest-entries manifest))
    instance))

(define (reload-program archive-url zone-module-url manifest-url)
  (wasm-host/not-implemented 'reload-program))
