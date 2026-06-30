# Convert a regulog object to a data frame

Coerces the entries list of a `regulog` object into a flat `data.frame`,
one row per entry (genesis record excluded). Columns match those
produced by
[`export_audit_trail()`](https://reprostats.org/regulog/reference/export_audit_trail.md)
with `format = "csv"`.

## Usage

``` r
# S3 method for class 'regulog'
as.data.frame(x, ...)
```

## Arguments

- x:

  A `regulog` object.

- ...:

  Unused; for S3 compatibility.

## Value

A `data.frame` with columns `entry_id`, `timestamp`, `app`,
`app_version`, `user`, `type`, `action`, `object`, `field`, `before`,
`after`, `reason`, `entry_hash`, `prev_hash`.

## Details

Called implicitly by
[`filter_log()`](https://reprostats.org/regulog/reference/filter_log.md)
and useful for direct inspection.

## Examples

``` r
log <- regulog_init(app = "analysis", version = "1.0", user = "jsmith")
log_action(log, "run", "primary.R", "Primary model fitted")
#> regulog: logged action 'run' on 'primary.R'
log_note(log, "Outlier retained per SAP")
#> regulog: note logged

as.data.frame(log)
#>   entry_id                   timestamp      app app_version   user   type
#> 1        1 2026-06-30T19:02:17.887228Z analysis         1.0 jsmith ACTION
#> 2        2 2026-06-30T19:02:17.888231Z analysis         1.0 jsmith   NOTE
#>   action    object field before after                   reason
#> 1    run primary.R  <NA>   <NA>  <NA>     Primary model fitted
#> 2   note      <NA>  <NA>   <NA>  <NA> Outlier retained per SAP
#>                                                         entry_hash
#> 1 32f990dd0b73b45c292e018987aa5a1134c1e42347ee234e46da7e7f98bb80b7
#> 2 a9aea89738240dc9a7a857f568bc0b5efba1a70e4027c1c8ad138f54bca370d9
#>                                                          prev_hash
#> 1 9c55554e94f348b0f8923094bcc520dbc5dbc91a20fb7d10f3ed75680456ad1c
#> 2 32f990dd0b73b45c292e018987aa5a1134c1e42347ee234e46da7e7f98bb80b7
```
