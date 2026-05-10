;;; ECE Scheduler module
;;; Module exports for the cooperative scheduler in scheduler.scm.

(define-module (ece scheduler)
  (export make-scheduler
          scheduler?
          fiber?
          fiber-done?
          fiber-id
          scheduler-current-fiber
          scheduler-ready-count
          scheduler-waiting-count
          scheduler-spawn!
          wait-for
          scheduler-notify!
          scheduler-step!
          scheduler-poll-events!
          scheduler-run!
          scheduler-register-event-source!)

  (define make-scheduler (%global-ref make-scheduler))
  (define scheduler? (%global-ref scheduler?))
  (define fiber? (%global-ref fiber?))
  (define fiber-done? (%global-ref fiber-done?))
  (define fiber-id (%global-ref fiber-id))
  (define scheduler-current-fiber (%global-ref scheduler-current-fiber))
  (define scheduler-ready-count (%global-ref scheduler-ready-count))
  (define scheduler-waiting-count (%global-ref scheduler-waiting-count))
  (define scheduler-spawn! (%global-ref scheduler-spawn!))
  (define wait-for (%global-ref wait-for))
  (define scheduler-notify! (%global-ref scheduler-notify!))
  (define scheduler-step! (%global-ref scheduler-step!))
  (define scheduler-poll-events! (%global-ref scheduler-poll-events!))
  (define scheduler-run! (%global-ref scheduler-run!))
  (define scheduler-register-event-source!
    (%global-ref scheduler-register-event-source!)))
