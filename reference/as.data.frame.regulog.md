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
#> 1        1 2026-07-01T16:19:25.160916Z analysis         1.0 jsmith ACTION
#> 2        2 2026-07-01T16:19:25.162007Z analysis         1.0 jsmith   NOTE
#>   action    object field before after                                  reason
#> 1    run primary.R  <NA>   <NA>  <NA>                    Primary model fitted
#> 2   note      <NA>  <NA>   <NA>  <NA> Outlier in subject 042 retained per SAP
#>   text meaning                                                       entry_hash
#> 1 <NA>    <NA> afa7b287c92b39201ed1ff1f7b231ef0c33cba48a71ba88f6c3975ddb8d5751c
#> 2 <NA>    <NA> f7b3969b7904eb1aa7c38e861eb7b58a851a0542c18992ad3ff7fe0c034c0867
#>                                                          prev_hash
#> 1 1d81e34db541e88e3c3a469c428b16c772a29dbbb3febff15daf1d23e735dd2c
#> 2 afa7b287c92b39201ed1ff1f7b231ef0c33cba48a71ba88f6c3975ddb8d5751c
```
