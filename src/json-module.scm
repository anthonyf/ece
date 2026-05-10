;;; ECE JSON module
;;; Module exports for the JSON encoder helpers in json.scm.

(define-module (ece json)
  (export json-encode
          json-encode-string
          json-encode-object
          json-encode-array
          json-source-update
          json-eval-source
          json-program-reload)

  (define json-encode (%global-ref json-encode))
  (define json-encode-string (%global-ref json-encode-string))
  (define json-encode-object (%global-ref json-encode-object))
  (define json-encode-array (%global-ref json-encode-array))
  (define json-source-update (%global-ref json-source-update))
  (define json-eval-source (%global-ref json-eval-source))
  (define json-program-reload (%global-ref json-program-reload)))
