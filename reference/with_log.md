# Run an expression with automatic data read logging

Evaluates `expr` with a local `read()` binding tied to `log`, so calls
inside the block don't need to repeat the `log` argument. Reads must use
`read()` explicitly inside the block; calling a reader function directly
(e.g. bare `haven::read_sas(...)`) is not logged. This keeps logging
coverage unambiguous: every logged read is visible at the call site, and
there are no implicit gaps.

## Usage

``` r
with_log(log, expr)
```

## Arguments

- log:

  A `regulog` object.

- expr:

  An expression, typically a [`{}`](https://rdrr.io/r/base/Paren.html)
  block. Inside the block, `read(reader, ...)` is available and logs to
  `log` automatically.

## Value

The value of `expr`, invisibly.

## See also

[`rl_read()`](https://reprostats.org/regulog/reference/rl_read.md)

## Examples

``` r
log <- regulog_init(app = "pipeline", version = "1.0", user = "jsmith")

if (FALSE) { # \dontrun{
with_log(log, {
  adsl <- read(haven::read_sas, "data/adsl.sas7bdat")
  adae <- read(haven::read_sas, "data/adae.sas7bdat")
})

filter_log(log, action = "data_read")
} # }
```
