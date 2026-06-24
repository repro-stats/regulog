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
#> 1        1 2026-06-24T10:09:05.428381Z analysis         1.0 ndoh.penn ACTION
#> 2        2 2026-06-24T10:09:05.429491Z analysis         1.0 ndoh.penn   NOTE
#>   action    object field before after                   reason
#> 1    run primary.R  <NA>   <NA>  <NA>     Primary model fitted
#> 2   note      <NA>  <NA>   <NA>  <NA> Outlier retained per SAP
#>                                                         entry_hash
#> 1 c2d409111b11b4bed7c9c3091fdbbf79515b18695b9c72963ced6cd372dc0d37
#> 2 8e64a544f48245a2de9e6ff6cb3982aa4e9a1ddcf48ba50d11b0e1c16d744365
#>                                                          prev_hash
#> 1 d49e5f7808a576ba8fb3223cab46016910b7eeaf7ffd46858152addc3565a05f
#> 2 c2d409111b11b4bed7c9c3091fdbbf79515b18695b9c72963ced6cd372dc0d37
```
