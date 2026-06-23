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
#> 1        1 2026-06-23T19:32:42.409745Z analysis         1.0 ndoh.penn ACTION
#> 2        2 2026-06-23T19:32:42.410756Z analysis         1.0 ndoh.penn   NOTE
#>   action    object field before after                   reason
#> 1    run primary.R  <NA>   <NA>  <NA>     Primary model fitted
#> 2   note      <NA>  <NA>   <NA>  <NA> Outlier retained per SAP
#>                                                         entry_hash
#> 1 b2c30ab0e48f726f9587ae51eade7da22414e9b47cc340afb0a0ba109e6d2b9f
#> 2 b204041862a0e8896475044adb814966f99935c4dbb84cf8caa2b1e1a4d609eb
#>                                                          prev_hash
#> 1 bad485d48f2a09f881f9230d43981a2598e0071209c1996045c71d43c82a13e7
#> 2 b2c30ab0e48f726f9587ae51eade7da22414e9b47cc340afb0a0ba109e6d2b9f
```
