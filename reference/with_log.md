# Run an expression with automatic data I/O logging

Enables hooks for the duration of `expr` and guarantees they are
disabled on exit – whether the expression completes normally, errors, or
is interrupted. The recommended way to scope automatic logging to a
block of analysis code.

## Usage

``` r
with_log(log, expr)
```

## Arguments

- log:

  A `regulog` object.

- expr:

  An R expression. Curly-brace blocks work as expected.

## Value

The value of `expr`, invisibly.

## See also

[`log_hooks_enable()`](https://reprostats.org/regulog/reference/log_hooks_enable.md),
[`log_hooks_disable()`](https://reprostats.org/regulog/reference/log_hooks_disable.md)

## Examples

``` r
if (FALSE) { # \dontrun{
log <- regulog_init(app = "pipeline", version = "1.0", user = "ndoh.penn",
                    path = "logs/audit.rlog")

with_log(log, {
  adsl <- haven::read_sas("data/adsl.sas7bdat")
  adae <- haven::read_sas("data/adae.sas7bdat")
})

# Hooks are always restored, even on error
filter_log(log, action = "data_read")
} # }
```
