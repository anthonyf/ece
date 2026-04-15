;;; scheduler.scm — cooperative fiber scheduler built on first-class continuations.
;;;
;;; This is Stage 1 of the ece-serve change. It provides a standalone
;;; cooperative multitasking layer that the dev server (and any future
;;; async-ish ECE code) can use to run multiple logical tasks on a single
;;; thread. It deliberately does NOT touch the runtime's existing
;;; %yield! / $yield-continuation machinery used by the sandbox's
;;; requestAnimationFrame loop — the two mechanisms run in parallel during
;;; Stage 1. A future proposal (`unify-yield-and-scheduler`) may subsume
;;; the runtime yield into this scheduler.
;;;
;;; Reference: Dybvig & Hieb, "Engines from Continuations" (1989), which
;;; is the canonical construction of multitasking primitives in Scheme via
;;; call/cc. What we're building is essentially an engine per fiber with a
;;; scheduler loop on top.
;;;
;;; ─────────────────────────────────────────────────────────────────────
;;; Data model
;;; ─────────────────────────────────────────────────────────────────────
;;;
;;; A SCHEDULER owns:
;;;   - sched-k          the scheduler's own captured continuation, used by
;;;                      running fibers to transfer control back here when
;;;                      they yield or complete. Captured fresh each time
;;;                      `run-one-fiber!` is entered.
;;;   - ready-fibers     queue of fibers whose next step is immediate (FIFO).
;;;   - waiting-fibers   set of fibers blocked inside wait-for, each tagged
;;;                      with the event it is waiting for. (List order is
;;;                      not significant — notify walks the whole list.)
;;;   - event-sources    procedures called during scheduler-run!, each
;;;                      expected to call scheduler-notify! when they have
;;;                      events ready. Sources receive the scheduler as
;;;                      their single argument.
;;;   - current-fiber    the fiber presently executing, or #f when the
;;;                      scheduler loop itself is running.
;;;   - next-fiber-id    monotonic counter used to tag fibers for
;;;                      introspection / debugging.
;;;
;;; A FIBER owns:
;;;   - k                the procedure to invoke to (re)enter the fiber.
;;;                      For a freshly-spawned fiber, this is a bootstrap
;;;                      lambda that runs the user thunk then transfers
;;;                      back to sched-k with a 'fiber-done notification.
;;;                      For a resumed fiber, this is a call/cc-captured
;;;                      continuation from inside `wait-for`. Both forms
;;;                      are callable with one argument that the fiber
;;;                      ignores (new) or receives as its wait-for return
;;;                      value (resumed).
;;;   - waiting-on       #f while ready or running; (tag . args) while
;;;                      waiting.
;;;   - done?            #t after the user thunk has returned normally.
;;;   - id               integer, unique within a scheduler instance.
;;;
;;; ─────────────────────────────────────────────────────────────────────
;;; Control flow
;;; ─────────────────────────────────────────────────────────────────────
;;;
;;; Step:
;;;   scheduler-step! loops while ready-fibers is non-empty, calling
;;;   run-one-fiber! on each iteration. run-one-fiber! captures its own
;;;   continuation into sched-k, pops the head of the ready queue, and
;;;   invokes that fiber's k. Control transfers INTO the fiber; the
;;;   call/cc form in run-one-fiber! only returns once the fiber invokes
;;;   sched-k (via wait-for or by completing).
;;;
;;; Wait:
;;;   wait-for inside a fiber calls call/cc to capture the fiber's own
;;;   continuation, records the event tag in the fiber's waiting-on
;;;   field, moves the fiber from ready to waiting, then invokes sched-k.
;;;   Control returns to run-one-fiber!'s call/cc (it unwinds) which
;;;   returns to scheduler-step!'s loop, which checks for more ready
;;;   fibers.
;;;
;;; Notify:
;;;   scheduler-notify! walks waiting-fibers looking for any whose
;;;   waiting-on tag matches the notify tag. Matching fibers have their
;;;   waiting-on cleared and move to the back of the ready queue. The
;;;   next scheduler-step! pass picks them up. The notify args are NOT
;;;   currently plumbed through to the resumed fiber — Stage 1 treats
;;;   wait-for's return value as "woken, proceed"; refinements can pass
;;;   the notify payload via a shared slot in the fiber state.
;;;
;;; Completion:
;;;   When a fiber's thunk returns normally, the bootstrap wrapper sets
;;;   done?=#t and invokes sched-k with 'fiber-done. The fiber is
;;;   implicitly removed (it was already popped from ready-fibers and
;;;   never reaches waiting-fibers). Callers holding a reference to the
;;;   fiber can check (fiber-done? f).
;;;
;;; Match semantics for Stage 1:
;;;   `wait-for` takes a tag and any number of args. `notify!` takes a
;;;   tag and any number of args. A fiber matches if its tag is eq? to
;;;   the notify tag. Args are ignored for matching; they are reserved
;;;   for future per-resource refinement (e.g., wait only for reads on
;;;   this specific socket). Callers can use distinct tags per resource
;;;   today if they need that granularity.

;; ---- Internal record types ----

(define-record sched-state
  sched-k ready-fibers waiting-fibers event-sources current-fiber next-fiber-id)

(define-record fiber-state k waiting-on done? id)

;; ---- Public constructors and predicates ----

(define (make-scheduler)
  "Create a fresh scheduler instance with empty ready and waiting queues."
  (make-sched-state #f '() '() '() #f 0))

(define (scheduler? v)
  "Test whether V is a scheduler instance."
  (sched-state? v))

(define (fiber? v)
  "Test whether V is a fiber instance."
  (fiber-state? v))

(define (fiber-done? f)
  "Test whether a fiber's thunk has returned normally."
  (fiber-state-done? f))

(define (fiber-id f)
  "Return the integer id assigned to this fiber by its scheduler."
  (fiber-state-id f))

;; ---- Introspection ----

(define (scheduler-current-fiber sched)
  "Return the fiber currently executing, or #f if the scheduler loop itself
is running (i.e., we're outside any fiber)."
  (sched-state-current-fiber sched))

(define (scheduler-ready-count sched)
  "Return the number of fibers currently in the ready queue."
  (length (sched-state-ready-fibers sched)))

(define (scheduler-waiting-count sched)
  "Return the number of fibers currently blocked on wait-for."
  (length (sched-state-waiting-fibers sched)))

;; ---- Internal queue helpers ----

(define (ready-push! sched fiber)
  "Append FIBER to the back of the ready queue (FIFO)."
  (set-sched-state-ready-fibers!
   sched
   (append (sched-state-ready-fibers sched) (list fiber))))

(define (ready-pop! sched)
  "Pop and return the head of the ready queue. Caller must check it is
non-empty first."
  (let ((fs (sched-state-ready-fibers sched)))
    (set-sched-state-ready-fibers! sched (cdr fs))
    (car fs)))

(define (waiting-add! sched fiber)
  "Append FIBER to the waiting list. Order is preserved so that notify
wakes fibers in the order they called wait-for — FIFO fairness for
fibers waiting on the same tag. O(n) per add, which is fine for the
dev server's small fiber counts."
  (set-sched-state-waiting-fibers!
   sched
   (append (sched-state-waiting-fibers sched) (list fiber))))

(define (waiting-remove-matching! sched tag)
  "Remove and return the list of waiting fibers whose tag is eq? to TAG.
The remaining waiting fibers stay in the waiting set."
  (let loop ((remaining (sched-state-waiting-fibers sched))
             (kept '())
             (removed '()))
    (cond
     ((null? remaining)
      (set-sched-state-waiting-fibers! sched kept)
      (reverse removed))
     (else
      (let* ((f (car remaining))
             (w (fiber-state-waiting-on f))
             (f-tag (and w (car w))))
        (cond
         ((eq? f-tag tag)
          (set-fiber-state-waiting-on! f #f)
          (loop (cdr remaining) kept (cons f removed)))
         (else
          (loop (cdr remaining) (cons f kept) removed))))))))

;; ---- Spawning fibers ----

(define (scheduler-spawn! sched thunk)
  "Create a new fiber that will run THUNK when next scheduled. Returns the
fiber record. The new fiber is appended to the ready queue."
  (let* ((id (sched-state-next-fiber-id sched))
         (fiber (make-fiber-state #f #f #f id)))
    (set-sched-state-next-fiber-id! sched (+ id 1))
    ;; Bootstrap continuation: run THUNK, mark the fiber done, return to
    ;; the scheduler via sched-k. The single argument is ignored; both
    ;; this lambda and a resumed call/cc continuation are invoked with
    ;; one arg for uniformity.
    (set-fiber-state-k!
     fiber
     (lambda (ignored)
       (thunk)
       (set-fiber-state-done?! fiber #t)
       ((sched-state-sched-k sched) 'fiber-done)))
    (ready-push! sched fiber)
    fiber))

;; ---- Yielding from inside a fiber ----

(define (wait-for sched tag . args)
  "Yield the current fiber until `scheduler-notify!` is called with a
matching TAG. ARGS are stored alongside the tag for future per-resource
matching but are not consulted by Stage 1's notify dispatch.

Must be called from inside a fiber's execution — the scheduler must have
a current-fiber set. Callers outside any fiber get an error."
  (let ((cur (sched-state-current-fiber sched)))
    (when (not cur)
      (error "wait-for: no current fiber; wait-for must be called from inside a fiber"))
    (call/cc
     (lambda (fk)
       (set-fiber-state-k! cur fk)
       (set-fiber-state-waiting-on! cur (cons tag args))
       (waiting-add! sched cur)
       ;; Transfer control back to the scheduler loop. sched-k was set by
       ;; run-one-fiber! just before invoking the fiber; invoking it here
       ;; unwinds back to the call/cc form inside run-one-fiber!.
       ((sched-state-sched-k sched) 'yielded)))))

;; ---- Waking waiting fibers ----

(define (scheduler-notify! sched tag . args)
  "Wake every fiber currently waiting on TAG. Moves them from waiting to
ready (in the order they appeared in the waiting list). Returns the
number of fibers woken. ARGS are accepted but ignored by Stage 1's
match semantics — callers can use distinct tags per resource today
if they need finer-grained wakeup."
  (let ((woken (waiting-remove-matching! sched tag)))
    (for-each (lambda (f) (ready-push! sched f)) woken)
    (length woken)))

;; ---- Running the scheduler ----

(define (run-one-fiber! sched)
  "Capture sched-k, pop one ready fiber, and invoke its continuation.
Returns a symbol describing why control returned:
  'yielded      fiber called wait-for
  'fiber-done   fiber completed normally
  'idle         no ready fibers were available"
  (call/cc
   (lambda (return-k)
     (cond
      ((null? (sched-state-ready-fibers sched))
       'idle)
      (else
       (set-sched-state-sched-k! sched return-k)
       (let ((fiber (ready-pop! sched)))
         (set-sched-state-current-fiber! sched fiber)
         ;; Transfer into the fiber. Either (a) the fiber runs to
         ;; wait-for which invokes return-k with 'yielded, (b) the
         ;; fiber completes which invokes return-k with 'fiber-done.
         ((fiber-state-k fiber) 'run)))))))

(define (scheduler-step! sched)
  "Run every currently-ready fiber once, stopping when the ready queue is
empty. Fibers that yield land in the waiting set; fibers that complete
are discarded. Returns 'ran if at least one fiber ran, or 'idle if the
ready queue was empty on entry."
  (cond
   ((null? (sched-state-ready-fibers sched)) 'idle)
   (else
    (let loop ()
      ;; Clear current-fiber so reentrant code (event source callbacks)
      ;; sees the correct "outside any fiber" state.
      (set-sched-state-current-fiber! sched #f)
      (when (pair? (sched-state-ready-fibers sched))
        (run-one-fiber! sched)
        (loop)))
    (set-sched-state-current-fiber! sched #f)
    'ran)))

(define (scheduler-poll-events! sched)
  "Invoke each registered event source with the scheduler as argument.
Sources are expected to call `scheduler-notify!` for any events they
have ready."
  (for-each
   (lambda (src) (src sched))
   (sched-state-event-sources sched)))

(define (scheduler-run! sched)
  "Loop poll-events + step until both the ready and waiting queues are
empty. Returns 'done when all fibers have completed, or 'deadlock if
only waiting fibers remain and no event sources exist to wake them.

Callers that want indefinite runs (e.g., the dev server) should
register at least one event source that will eventually notify a
waiting fiber. This procedure does NOT sleep between iterations —
that is the event source's responsibility if it cares about CPU."
  (let loop ()
    (scheduler-poll-events! sched)
    (scheduler-step! sched)
    (cond
     ((pair? (sched-state-ready-fibers sched))
      (loop))
     ((null? (sched-state-waiting-fibers sched))
      'done)
     ((null? (sched-state-event-sources sched))
      ;; Waiting fibers with no sources that could wake them.
      'deadlock)
     (else
      ;; Still have waiting fibers and at least one event source;
      ;; poll again. (Real dev server sources can sleep internally.)
      (loop)))))

;; ---- Pluggable event sources ----

(define (scheduler-register-event-source! sched source-proc)
  "Register SOURCE-PROC as a pluggable event source. It will be called
with the scheduler as its single argument during scheduler-poll-events!
(invoked by scheduler-run!). The source is expected to call
`scheduler-notify!` for any events it has ready."
  (set-sched-state-event-sources!
   sched
   (append (sched-state-event-sources sched) (list source-proc))))
