## MODIFIED Requirements

### Requirement: primitives.def updated
Migrated primitives SHALL have their platform annotation changed from `core` to `ece` in `primitives.def` to document that they are now prelude-level. Additionally, new core primitives `truncate` (108) and `floor` (109) SHALL be added.

#### Scenario: annotation reflects migration
- **WHEN** `primitives.def` is read
- **THEN** `char-whitespace?` (47), `char-alphabetic?` (48), `char-numeric?` (49), `equal?` (21), `eqv?` (174), `gensym` (82), `string-downcase` (36), `string-upcase` (37), `string-split` (38), `string-trim` (39), `string-contains?` (40), `string-join` (41), `print` (66), `modulo` (4), `number->string` (30), `string=?` (33), `string<?` (34), `string>?` (35), `char=?` (45), `char<?` (46), `vector->list` (55), `list->vector` (56), `boolean?` (19), and `string->number` (29) SHALL have platform `ece`

#### Scenario: new core primitives registered
- **WHEN** `primitives.def` is read
- **THEN** `truncate` (108) and `floor` (109) SHALL have platform `core`
