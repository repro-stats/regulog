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
#> 1        1 2026-07-01T08:44:05.960581Z analysis         1.0 jsmith ACTION
#> 2        2 2026-07-01T08:44:05.961605Z analysis         1.0 jsmith   NOTE
#>   action    object field before after                                  reason
#> 1    run primary.R  <NA>   <NA>  <NA>                    Primary model fitted
#> 2   note      <NA>  <NA>   <NA>  <NA> Outlier in subject 042 retained per SAP
#>   text meaning                                                       entry_hash
#> 1 <NA>    <NA> bc43d2281d7a436edc77ea4c9c3b40d90db13149ea6f4d2fd68145db00c55bbc
#> 2 <NA>    <NA> d1bc5d2e2e655ddadaa9d79069a6ff93754276d1f444125277a54c240ecdd9bb
#>                                                          prev_hash
#> 1 654b77e221941db7c8d0ea21cda56fe15eef729822f25253d360381e56852cc9
#> 2 bc43d2281d7a436edc77ea4c9c3b40d90db13149ea6f4d2fd68145db00c55bbc
```
