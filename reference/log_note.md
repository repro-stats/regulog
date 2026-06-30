# Log a free-text note in the audit trail

Records a NOTE entry — a free-text annotation that adds context, intent,
or an observation without requiring a discrete action verb or a
before/after value. Use it to document analytical decisions,
assumptions, or rationale that do not fit
[`log_action()`](https://reprostats.org/regulog/reference/log_action.md)
or
[`log_change()`](https://reprostats.org/regulog/reference/log_change.md).

## Usage

``` r
log_note(log, text)
```

## Arguments

- log:

  A `regulog` object returned by
  [`regulog_init()`](https://reprostats.org/regulog/reference/regulog_init.md)
  or
  [`regulog_shiny_init()`](https://reprostats.org/regulog/reference/regulog_shiny_init.md).

- text:

  The note text. Cannot be blank or whitespace-only.

## Value

The `regulog` object, invisibly (pipe-friendly).

## Details

Like all `regulog` entries, `text` is mandatory with no default and is
included in the hash chain, making it tamper-evident.

## See also

[`log_action()`](https://reprostats.org/regulog/reference/log_action.md),
[`log_change()`](https://reprostats.org/regulog/reference/log_change.md),
[`log_signature()`](https://reprostats.org/regulog/reference/log_signature.md)

## Examples

``` r
log <- regulog_init(app = "analysis", version = "1.0", user = "jsmith")

log_note(log, "Baseline window defined as Day -1 to Day 1 per protocol v3 §5.2")
#> regulog: note logged
log_note(log, "Outlier in subject 042 discussed with medical monitor — retained per SAP")
#> regulog: note logged
```
