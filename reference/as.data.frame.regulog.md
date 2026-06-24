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
#> 1        1 2026-06-24T10:22:47.546491Z analysis         1.0 ndoh.penn ACTION
#> 2        2 2026-06-24T10:22:47.547260Z analysis         1.0 ndoh.penn   NOTE
#>   action    object field before after                   reason
#> 1    run primary.R  <NA>   <NA>  <NA>     Primary model fitted
#> 2   note      <NA>  <NA>   <NA>  <NA> Outlier retained per SAP
#>                                                         entry_hash
#> 1 9bdc447554f7d84a8e0b44b701a096f8acfaa85600940e3e75f6b53109069232
#> 2 48673ef905c37c658dbb04320e5edad7e1560ee2f569130aab99bb7b6cdad634
#>                                                          prev_hash
#> 1 2e6192ea7871ed034121cdaf0ef33e1c879be5163329b116de163b4eb0c767ca
#> 2 9bdc447554f7d84a8e0b44b701a096f8acfaa85600940e3e75f6b53109069232
```
