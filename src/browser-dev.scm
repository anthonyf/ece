;;; ECE Browser Dev module
;;; Module exports for browser live-development policy in browser-lib.scm.

(define-module (ece browser dev)
  (export dev-client-error-message
          handle-source-update
          browser-dev-client/%error-message
          browser-dev-client-handle-source-update)

  (define browser-dev-client/%error-message
    (%global-ref browser-dev-client/%error-message))
  (define browser-dev-client-handle-source-update
    (%global-ref browser-dev-client-handle-source-update))

  (define dev-client-error-message browser-dev-client/%error-message)
  (define handle-source-update browser-dev-client-handle-source-update))
