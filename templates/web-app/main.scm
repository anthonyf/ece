(set-html!
 (get-element-by-id "app-root")
 (html (:main :class "app-shell"
        (:canvas :id "sandbox-canvas")
        (:section :class "hud"
          (:p "Hello from ECE")))))

(define counter 0)

(define (tick)
  (set! counter (+ counter 1))
  (display "tick ")
  (display counter)
  (newline)
  counter)

(tick)
