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
`after`, `reason`, `text`, `meaning`, `entry_hash`, `prev_hash`.

## Details

Called implicitly by
[`filter_log()`](https://reprostats.org/regulog/reference/filter_log.md)
and useful for direct inspection.

## Examples

``` r
log <- regulog_init(app = "analysis", version = "1.0", user = "jsmith")
log_action(log,
  action = "run",
  object = "primary.R",
  reason = "Primary model fitted"
)
#> regulog: logged action 'run' on 'primary.R'
log_note(log, "Outlier in subject 042 retained per SAP")
#> regulog: note logged

as.data.frame(log)
#>   entry_id                   timestamp      app app_version   user   type
#> 1        1 2026-07-01T20:00:40.903149Z analysis         1.0 jsmith ACTION
#> 2        2 2026-07-01T20:00:40.904188Z analysis         1.0 jsmith   NOTE
#>   action    object field before after                                  reason
#> 1    run primary.R  <NA>   <NA>  <NA>                    Primary model fitted
#> 2   note      <NA>  <NA>   <NA>  <NA> Outlier in subject 042 retained per SAP
#>   text meaning                                                       entry_hash
#> 1 <NA>    <NA> 5d0f2c1ed18ca4f73bc278da739edc82e515c574b3861dba1fbf3b7dfe8aa107
#> 2 <NA>    <NA> 6a5cd7966511c4b146a738190bafa57d4cc26ac9d2fc01cb22b813b5174b336d
#>                                                          prev_hash
#> 1 5c2fbec8e5fed87db38f64b2535423a6dc3dcf52edc31cf0019a8385e47e2262
#> 2 5d0f2c1ed18ca4f73bc278da739edc82e515c574b3861dba1fbf3b7dfe8aa107
```
