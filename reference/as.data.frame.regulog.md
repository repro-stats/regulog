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
#> 1        1 2026-07-07T13:57:25.593666Z analysis         1.0 jsmith ACTION
#> 2        2 2026-07-07T13:57:25.594675Z analysis         1.0 jsmith   NOTE
#>   action    object field before after                                  reason
#> 1    run primary.R  <NA>   <NA>  <NA>                    Primary model fitted
#> 2   note      <NA>  <NA>   <NA>  <NA> Outlier in subject 042 retained per SAP
#>   text meaning                                                       entry_hash
#> 1 <NA>    <NA> 68de80f4ad080db7d77b014e3f8fd322ba3d16c689fcd17870ac06898f7c86b8
#> 2 <NA>    <NA> 69ba06fcb73f5234610b79eae8a250e3f6b6c50f12b9276025b68b653b2ec00f
#>                                                          prev_hash
#> 1 f2b2b685c14003c45818a9a162ee0db223385fb7d7836bd99d9bd9e95e32cf0a
#> 2 68de80f4ad080db7d77b014e3f8fd322ba3d16c689fcd17870ac06898f7c86b8
```
