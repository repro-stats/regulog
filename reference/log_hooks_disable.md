# Disable automatic data I/O logging hooks

Restores all functions patched by
[`log_hooks_enable()`](https://repro-stats.github.io/regulog/reference/log_hooks_enable.md)
to their originals. Safe to call even if hooks were never enabled.

## Usage

``` r
log_hooks_disable()
```

## Value

Invisibly `NULL`.

## See also

[`log_hooks_enable()`](https://repro-stats.github.io/regulog/reference/log_hooks_enable.md),
[`with_log()`](https://repro-stats.github.io/regulog/reference/with_log.md)

## Examples

``` r
if (FALSE) { # \dontrun{
log_hooks_disable()
} # }
```
