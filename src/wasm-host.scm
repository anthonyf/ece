;;; wasm-host.scm — ECE-level WASM host/native-zone loading policy.
;;;
;;; This module defines the ECE-facing surface for dynamic WASM host work.
;;; Browser capabilities (fetch/cache reads, WebAssembly instantiation, export
;;; lookup, and import-object construction) are raw %wasm-* host primitives.
;;; This file owns the ECE policy above them: native-zone manifest parsing,
;;; validation, accessors, registration, and loader sequencing.

(define (wasm-host/error message)
  (error (string-append "wasm-host: " message)))

(define (wasm-host/not-implemented name)
  (wasm-host/error
   (string-append (symbol->string name)
                  " requires browser WASM host capabilities that are not implemented yet")))

(define (wasm-host/require-capability name thunk)
  (if (platform-has? name)
      (thunk)
      (wasm-host/not-implemented name)))

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

(define (wasm-host/optional-unit-id entry)
  (cond
   ((not (wasm-host/plist-has-key? entry ':unit-id)) '())
   (else
    (let ((unit-id (wasm-host/plist-get entry ':unit-id)))
      (cond
       (unit-id (list ':unit-id unit-id))
       (else
        (wasm-host/error "native-zone entry :unit-id must not be #f")))))))

(define (wasm-host/validate-entry entry)
  "Validate one native-zone manifest entry and return a normalized plist."
  (wasm-host/ensure-plist entry "native-zone entry")
  (let ((index (wasm-host/plist-get entry ':index))
        (export-name (wasm-host/plist-get entry ':export)))
    (cond
     ((not (wasm-host/plist-has-key? entry ':index))
      (wasm-host/error "native-zone entry missing :index"))
     ((not (wasm-host/non-negative-integer? index))
      (wasm-host/error "native-zone entry :index must be a non-negative integer"))
     ((not (wasm-host/plist-has-key? entry ':export))
      (wasm-host/error "native-zone entry missing :export"))
     ((not (wasm-host/non-empty-string? export-name))
      (wasm-host/error "native-zone entry :export must be a non-empty string"))
     (else
      (append
       (list ':index index ':export export-name)
       (wasm-host/optional-unit-id entry)
       (wasm-host/optional-string entry ':fingerprint "native-zone entry"))))))

(define (wasm-host/entry-key default-unit-id entry)
  (list (or (native-zone-entry-unit-id entry) default-unit-id)
        (native-zone-entry-index entry)))

(define (wasm-host/validate-entries default-unit-id entries)
  "Validate native-zone ENTRIES and return normalized entries."
  (cond
   ((not (list? entries))
    (wasm-host/error "native-zone manifest :entries must be a list"))
   (else
    (let loop ((rest entries) (seen '()) (acc '()))
      (cond
       ((null? rest) (reverse acc))
       (else
        (let* ((entry (wasm-host/validate-entry (car rest)))
               (key (wasm-host/entry-key default-unit-id entry)))
          (when (member key seen)
            (wasm-host/error
             "native-zone manifest has duplicate (:unit-id, :index) entry"))
          (loop (cdr rest) (cons key seen) (cons entry acc)))))))))

(define (validate-native-zone-manifest manifest)
  "Validate MANIFEST and return a normalized native-zone manifest plist.

Expected input shape:

  (:ece-native-zones
    :version 1
    :unit-id <default-archive-unit-id>
    :entries ((:index 0 :export \"zone_0\") ...))

Each entry may also include :unit-id to let one side module cover multiple
archive units. Optional string fields are :source, :module-url, and per-entry
:fingerprint."
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
                 ':entries (wasm-host/validate-entries unit-id entries))
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

(define (native-zone-entry-unit-id entry)
  (wasm-host/plist-get entry ':unit-id))

(define (native-zone-entry-effective-unit-id manifest entry)
  (or (native-zone-entry-unit-id entry)
      (native-zone-manifest-unit-id manifest)))

(define (native-zone-entry-export-name entry)
  (wasm-host/plist-get entry ':export))

(define (native-zone-entry-fingerprint entry)
  (wasm-host/plist-get entry ':fingerprint))

(define (wasm-host/registry-unit-key unit-id)
  "Return an interned key suitable for identity-keyed runtime registries."
  (cond
   ((not unit-id)
    (wasm-host/error "native-zone unit-id must not be #f"))
   ((symbol? unit-id) unit-id)
   ((string? unit-id) (string->symbol unit-id))
   (else (string->symbol (write-to-string-flat unit-id)))))

(define wasm-host/max-co-index 1073741823)

(define (wasm-host/validate-co-index co-index)
  (when (not (and (integer? co-index)
                  (>= co-index 0)
                  (<= co-index wasm-host/max-co-index)))
    (wasm-host/error
     "native-zone co-index must be an integer in the range 0..1073741823")))

(define (wasm-host/normalize-co-index co-index)
  (wasm-host/validate-co-index co-index)
  (truncate co-index))

(define (fetch-text url)
  (wasm-host/require-capability
   '%wasm-fetch-text
   (lambda () (%wasm-fetch-text url))))

(define (fetch-bytes url)
  (wasm-host/require-capability
   '%wasm-fetch-bytes
   (lambda () (%wasm-fetch-bytes url))))

(define (wasm-instantiate bytes imports)
  (wasm-host/require-capability
   '%wasm-instantiate
   (lambda () (%wasm-instantiate bytes imports))))

(define (wasm-export instance name)
  (wasm-host/require-capability
   '%wasm-export
   (lambda () (%wasm-export instance name))))

(define (register-native-zone! unit-id co-index export-ref)
  "Register EXPORT-REF as the native zone for UNIT-ID code object CO-INDEX."
  (when (not export-ref)
    (wasm-host/error "native-zone export-ref must not be #f"))
  (%native-zone-register!
   (wasm-host/registry-unit-key unit-id)
   (wasm-host/normalize-co-index co-index)
   export-ref))

(define (native-zone-lookup unit-id co-index)
  "Return the registered native-zone export ref, or #f when absent."
  (%native-zone-lookup
   (wasm-host/registry-unit-key unit-id)
   (wasm-host/normalize-co-index co-index)))

(define (native-zone-registered? unit-id co-index)
  (if (native-zone-lookup unit-id co-index) #t #f))

(define (native-zone-imports)
  "Return the import object for side-loaded native-zone modules.
Generated zones import only handle-level constructors from the root runtime."
  (wasm-host/require-capability
   '%wasm-native-zone-imports
   (lambda () (%wasm-native-zone-imports))))

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
        (native-zone-entry-effective-unit-id manifest entry)
        (native-zone-entry-index entry)
        (wasm-export instance (native-zone-entry-export-name entry))))
     (native-zone-manifest-entries manifest))
    instance))

(define (wasm-host/register-reload-section! section)
  "Register SECTION for reload, replacing any prior unit record."
  (let* ((unit (archive/section-unit section))
         (cos (archive/section-cos section))
         (unit-id (wasm-host/plist-get unit ':unit-id))
         (unit-key (archive/unit-key unit-id)))
    (hash-remove! *module-instances* unit-key)
    (hash-set! *archive-units*
               unit-key
               (archive/make-unit-record unit cos))))

(define (reload-archive-bundle-text text)
  "Load and execute all .ecec archive sections from TEXT for reload.
Unlike load-bundle, this replaces existing unit records so future lookups and
fresh module imports observe the newly loaded archive."
  (let ((port (open-input-string text)))
    (define (read-sections sections)
      (let ((archive (read-archive-section-form port)))
        (if (eof? archive)
            (reverse sections)
            (read-sections
             (cons (archive/materialize-section archive) sections)))))
    (let ((sections (read-sections '())))
      (close-input-port port)
      (for-each wasm-host/register-reload-section! sections)
      (let loop ((rest sections) (last-result #f))
        (if (null? rest)
            last-result
            (loop (cdr rest)
                  (archive/load-materialized-section (car rest) #t)))))))

(define (reload-program archive-url zone-module-url manifest-url)
  "Fetch and load ARCHIVE-URL, then optionally load native-zone artifacts.
When both ZONE-MODULE-URL and MANIFEST-URL are provided, the native-zone module
is loaded after the archive. When both are #f, this performs an archive-only
reload. Supplying only one native-zone URL is an error. Returns the archive
bundle's last init result."
  (when (and (not (and zone-module-url manifest-url))
             (or zone-module-url manifest-url))
    (wasm-host/error
     "reload-program requires both native-zone module and manifest URLs"))
  (let ((archive-result (reload-archive-bundle-text (fetch-text archive-url))))
    (cond
     ((and zone-module-url manifest-url)
      (load-native-zone-module zone-module-url manifest-url))
     (else #f))
    archive-result))
