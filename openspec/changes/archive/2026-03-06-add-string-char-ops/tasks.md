## 1. Character support

- [x] 1.1 Add `characterp` to `self-evaluating-p` so characters self-evaluate
- [x] 1.2 Add character primitives: `char?`, `char=?`, `char<?`, `char->integer`, `integer->char`
- [x] 1.3 Export character symbols from ECE package

## 2. String operations

- [x] 2.1 Add string primitives: `string-length`, `string-ref`, `substring`
- [x] 2.2 Add `string-append` with variadic support (custom wrapper)
- [x] 2.3 Add conversion primitives: `string->number`, `number->string`, `string->symbol`, `symbol->string`
- [x] 2.4 Export string symbols from ECE package

## 3. Tests

- [x] 3.1 Add character tests (self-eval, char?, char=?, char<?, char->integer, integer->char)
- [x] 3.2 Add string tests (string-length, string-ref, string-append, substring, conversions)
- [x] 3.3 Run all tests and verify pass
