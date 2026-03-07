;;; simple-game.scm — A small IF game to validate the ECE IF library
;;; Run with: (load "simple-game.scm")

(load "if-lib.scm")

;; Game state
(define has-key nil)
(define door-unlocked nil)

;; --- Rooms ---

(room entrance-hall
  "You stand in a grand entrance hall. Dusty portraits line the walls.
A corridor leads north, and a locked door stands to the east."
  (choose
    ("Go north to the library" (library))
    (when has-key
      ("Unlock the east door" (begin (set door-unlocked t)
                                     (display "You turn the key. The lock clicks open.")
                                     (newline)
                                     (entrance-hall))))
    (when door-unlocked
      ("Go east through the unlocked door" (treasure-room)))))

(room library
  "The library is filled with towering bookshelves. Dust motes float
in the dim light. Something glints on a reading desk."
  (choose
    (when (not has-key)
      ("Pick up the brass key on the desk" (begin (set has-key t)
                                                  (display "You pocket the brass key.")
                                                  (newline)
                                                  (library))))
    ("Search the bookshelves" (begin (display "You find nothing but old novels and cobwebs.")
                                    (newline)
                                    (library)))
    ("Go south to the entrance hall" (entrance-hall))))

(room treasure-room
  "You enter a small chamber. In the center, a wooden chest sits on a
stone pedestal. Congratulations -- you found the treasure!"
  (choose
    ("Open the chest" (begin (display "Gold coins spill out! You win!")
                             (newline)))
    ("Go back to the entrance hall" (entrance-hall))))

;; Start the game
(newline)
(display "=== The Old Manor ===")
(newline)
(newline)
(entrance-hall)
