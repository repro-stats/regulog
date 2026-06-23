# Convert a regulog object to a data frame

Coerces the entries list of a `regulog` object into a flat `data.frame`,
one row per entry (genesis record excluded). Columns match those
produced by
[`export_audit_trail()`](https://repro-stats.github.io/regulog/reference/export_audit_trail.md)
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
[`filter_log()`](https://repro-stats.github.io/regulog/reference/filter_log.md)
and useful for direct inspection.

## Examples

``` r
log <- regulog_init(app = "analysis", version = "1.0", user = "ndoh.penn")
log_action(log, "run", "primary.R", "Primary model fitted")
#> regulog: logged action 'run' on 'primary.R'
log_note(log, "Outlier retained per SAP")
#> regulog: note logged

as.data.frame(log)
#>   entry_id                   timestamp      app app_version      user   type
#> 1        1 2026-06-23T19:13:53.444081Z analysis         1.0 ndoh.penn ACTION
#> 2        2 2026-06-23T19:13:53.445147Z analysis         1.0 ndoh.penn   NOTE
#>   action    object field before after                   reason
#> 1    run primary.R  <NA>   <NA>  <NA>     Primary model fitted
#> 2   note      <NA>  <NA>   <NA>  <NA> Outlier retained per SAP
#>                                                         entry_hash
#> 1 631250929c5eac61b682f96d792d1dff4dab68d80855b444cb53c920f268bb14
#> 2 a5a7e9ea5c16c9cb870e55f6aff05e35320fc69bba610062f860a4dee376ab02
#>                                                          prev_hash
#> 1 3d39bc34c42207f682983439c59872dd00994d952b699be5e5445d4a89e4998d
#> 2 631250929c5eac61b682f96d792d1dff4dab68d80855b444cb53c920f268bb14
```
