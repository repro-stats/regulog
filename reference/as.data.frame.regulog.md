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
#> 1        1 2026-07-01T16:04:02.223754Z analysis         1.0 jsmith ACTION
#> 2        2 2026-07-01T16:04:02.224973Z analysis         1.0 jsmith   NOTE
#>   action    object field before after                                  reason
#> 1    run primary.R  <NA>   <NA>  <NA>                    Primary model fitted
#> 2   note      <NA>  <NA>   <NA>  <NA> Outlier in subject 042 retained per SAP
#>   text meaning                                                       entry_hash
#> 1 <NA>    <NA> 186b1951a1c1e495329aab8c50b6761e9b9be77a6f7b7dc93dd589f0927a6863
#> 2 <NA>    <NA> 6eacb60e505a4d96d4b406acd9fd23a16a640d50fbf96c0a3697c8d5f483dbfe
#>                                                          prev_hash
#> 1 0969f441c32a85720de6ae922d33b19e477741c2faa5e22db9b84310e1d373a7
#> 2 186b1951a1c1e495329aab8c50b6761e9b9be77a6f7b7dc93dd589f0927a6863
```
