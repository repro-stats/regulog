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
log <- regulog_init(app = "analysis", version = "1.0", user = "ndoh.penn")
log_action(log, "run", "primary.R", "Primary model fitted")
#> regulog: logged action 'run' on 'primary.R'
log_note(log, "Outlier retained per SAP")
#> regulog: note logged

as.data.frame(log)
#>   entry_id                   timestamp      app app_version      user   type
#> 1        1 2026-06-24T22:24:03.545775Z analysis         1.0 ndoh.penn ACTION
#> 2        2 2026-06-24T22:24:03.546757Z analysis         1.0 ndoh.penn   NOTE
#>   action    object field before after                   reason
#> 1    run primary.R  <NA>   <NA>  <NA>     Primary model fitted
#> 2   note      <NA>  <NA>   <NA>  <NA> Outlier retained per SAP
#>                                                         entry_hash
#> 1 391990c019a55b8bd587c0227839f19cceb5ed6717efd8cf6fb960b5b9af535d
#> 2 45ea83143145f7eac32d365ba9732563caa2626f4672150a62d815d0c5c7ad5a
#>                                                          prev_hash
#> 1 39d60704ab01075f87f8808bb831e57ce9a99f7d2796ebc8d70f72bfe7867e09
#> 2 391990c019a55b8bd587c0227839f19cceb5ed6717efd8cf6fb960b5b9af535d
```
