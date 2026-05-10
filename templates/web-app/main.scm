(define-module (app main)
  (import (ece browser dom)
          (ece browser html))
  (export start tick)

  (define counter 0)

  (define (app-style)
    (string-append
     "* { box-sizing: border-box; }\n"
     "html, body { margin: 0; min-height: 100%; background: #101014; color: #f4f4f5; font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace; }\n"
     "body { display: grid; grid-template-rows: 1fr 160px; min-height: 100vh; }\n"
     "#app-root { min-height: 0; }\n"
     "main { display: grid; grid-template-rows: 1fr auto; min-height: 100%; }\n"
     "canvas { display: block; width: 100%; height: 100%; background: #050507; }\n"
     ".hud { padding: 12px; border-top: 1px solid #33333d; background: #15151a; }\n"
     ".hud p { margin: 0; }\n"
     "pre { margin: 0; padding: 12px; overflow: auto; border-top: 1px solid #33333d; background: #18181d; white-space: pre-wrap; }\n"))

  (define (app-shell)
    (html-render-fragment
     (list
      (list ':style (app-style))
      '(:main :class "app-shell"
        (:canvas :id "sandbox-canvas")
        (:section :class "hud"
          (:p "Hello from ECE"))))))

  (define (render!)
    (set-html! (element-by-id "app-root") (app-shell)))

  (define (tick)
    (set! counter (+ counter 1))
    (display "tick ")
    (display counter)
    (newline)
    counter)

  (define (start)
    (render!)
    (tick))

  (start))
