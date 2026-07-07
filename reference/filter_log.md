# Filter audit log entries

Extracts a subset of entries from a `regulog` object or a `.rlog` file
as a plain `data.frame`. All filter arguments are optional — omitting
all returns every entry.

## Usage

``` r
filter_log(
  log,
  type = NULL,
  user = NULL,
  action = NULL,
  from = NULL,
  to = NULL
)
```

## Arguments

- log:

  A `regulog` object **or** a path to a `.rlog` file.

- type:

  Character vector of entry types to keep: `"ACTION"`, `"CHANGE"`,
  `"NOTE"`, `"SIGNATURE"`. `NULL` returns all types.

- user:

  Character vector of user identifiers to keep. `NULL` returns all
  users.

- action:

  Character vector of action values to keep (e.g. `"approved"`,
  `"data_read"`). `NULL` returns all actions.

- from:

  Start of the time window. ISO 8601 string (`"2026-06-01"`) or `Date`.
  `NULL` applies no lower bound.

- to:

  End of the time window. Same format as `from`. Inclusive. `NULL`
  applies no upper bound.

## Value

A `data.frame` of matching entries, sorted by `entry_id`. Returns a
zero-row data frame when nothing matches.

## See also

[`as.data.frame.regulog()`](https://reprostats.org/regulog/reference/as.data.frame.regulog.md),
[`export_audit_trail()`](https://reprostats.org/regulog/reference/export_audit_trail.md),
[`verify_log()`](https://reprostats.org/regulog/reference/verify_log.md)

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
log_action(log,
  action = "export",
  object = "results.csv",
  reason = "Sent to sponsor"
)
#> regulog: logged action 'export' on 'results.csv'
log_signature(log, "Analysis complete and accurate per SAP v2")
#> regulog: signature applied by 'jsmith' covering 3 entries

# All entries as a data frame
filter_log(log)
#>   entry_id                   timestamp      app app_version   user      type
#> 1        1 2026-07-07T13:57:25.931313Z analysis         1.0 jsmith    ACTION
#> 2        2 2026-07-07T13:57:25.932227Z analysis         1.0 jsmith      NOTE
#> 3        3 2026-07-07T13:57:25.933046Z analysis         1.0 jsmith    ACTION
#> 4        4 2026-07-07T13:57:25.933944Z analysis         1.0 jsmith SIGNATURE
#>      action      object           field before after
#> 1       run   primary.R            <NA>   <NA>  <NA>
#> 2      note        <NA>            <NA>   <NA>  <NA>
#> 3    export results.csv            <NA>   <NA>  <NA>
#> 4 signature      jsmith entries_covered   <NA>     3
#>                                      reason text meaning
#> 1                      Primary model fitted <NA>    <NA>
#> 2   Outlier in subject 042 retained per SAP <NA>    <NA>
#> 3                           Sent to sponsor <NA>    <NA>
#> 4 Analysis complete and accurate per SAP v2 <NA>    <NA>
#>                                                         entry_hash
#> 1 4dc9295b8c09d1db894f7a1c693a1df0d857084d53b0252d3b7aeff14a06ad58
#> 2 e1e4379505da590ef9bc1631856a3495c21c49897c4b83a8cec7e5170cf8d6e4
#> 3 07dd58624ab6758c7615c8da29d9370cf9f8d0829082ec02f0e299a9eb6fef93
#> 4 fa3c246296be8e5b2d279a17885caf855adf63483e3988e99d3b4f00175e23f2
#>                                                          prev_hash
#> 1 d0966e81caeac722a4ca6bc251a783e347a699ee6a18f8f187c6fbffd0e31e21
#> 2 4dc9295b8c09d1db894f7a1c693a1df0d857084d53b0252d3b7aeff14a06ad58
#> 3 e1e4379505da590ef9bc1631856a3495c21c49897c4b83a8cec7e5170cf8d6e4
#> 4 07dd58624ab6758c7615c8da29d9370cf9f8d0829082ec02f0e299a9eb6fef93

# Only signatures
filter_log(log, type = "SIGNATURE")
#>   entry_id                   timestamp      app app_version   user      type
#> 1        4 2026-07-07T13:57:25.933944Z analysis         1.0 jsmith SIGNATURE
#>      action object           field before after
#> 1 signature jsmith entries_covered   <NA>     3
#>                                      reason text meaning
#> 1 Analysis complete and accurate per SAP v2 <NA>    <NA>
#>                                                         entry_hash
#> 1 fa3c246296be8e5b2d279a17885caf855adf63483e3988e99d3b4f00175e23f2
#>                                                          prev_hash
#> 1 07dd58624ab6758c7615c8da29d9370cf9f8d0829082ec02f0e299a9eb6fef93

# Actions and notes by a specific user
filter_log(log, type = c("ACTION", "NOTE"), user = "jsmith")
#>   entry_id                   timestamp      app app_version   user   type
#> 1        1 2026-07-07T13:57:25.931313Z analysis         1.0 jsmith ACTION
#> 2        2 2026-07-07T13:57:25.932227Z analysis         1.0 jsmith   NOTE
#> 3        3 2026-07-07T13:57:25.933046Z analysis         1.0 jsmith ACTION
#>   action      object field before after                                  reason
#> 1    run   primary.R  <NA>   <NA>  <NA>                    Primary model fitted
#> 2   note        <NA>  <NA>   <NA>  <NA> Outlier in subject 042 retained per SAP
#> 3 export results.csv  <NA>   <NA>  <NA>                         Sent to sponsor
#>   text meaning                                                       entry_hash
#> 1 <NA>    <NA> 4dc9295b8c09d1db894f7a1c693a1df0d857084d53b0252d3b7aeff14a06ad58
#> 2 <NA>    <NA> e1e4379505da590ef9bc1631856a3495c21c49897c4b83a8cec7e5170cf8d6e4
#> 3 <NA>    <NA> 07dd58624ab6758c7615c8da29d9370cf9f8d0829082ec02f0e299a9eb6fef93
#>                                                          prev_hash
#> 1 d0966e81caeac722a4ca6bc251a783e347a699ee6a18f8f187c6fbffd0e31e21
#> 2 4dc9295b8c09d1db894f7a1c693a1df0d857084d53b0252d3b7aeff14a06ad58
#> 3 e1e4379505da590ef9bc1631856a3495c21c49897c4b83a8cec7e5170cf8d6e4

# Entries within a date range
filter_log(log, from = "2026-06-01", to = "2026-12-31")
#>   entry_id                   timestamp      app app_version   user      type
#> 1        1 2026-07-07T13:57:25.931313Z analysis         1.0 jsmith    ACTION
#> 2        2 2026-07-07T13:57:25.932227Z analysis         1.0 jsmith      NOTE
#> 3        3 2026-07-07T13:57:25.933046Z analysis         1.0 jsmith    ACTION
#> 4        4 2026-07-07T13:57:25.933944Z analysis         1.0 jsmith SIGNATURE
#>      action      object           field before after
#> 1       run   primary.R            <NA>   <NA>  <NA>
#> 2      note        <NA>            <NA>   <NA>  <NA>
#> 3    export results.csv            <NA>   <NA>  <NA>
#> 4 signature      jsmith entries_covered   <NA>     3
#>                                      reason text meaning
#> 1                      Primary model fitted <NA>    <NA>
#> 2   Outlier in subject 042 retained per SAP <NA>    <NA>
#> 3                           Sent to sponsor <NA>    <NA>
#> 4 Analysis complete and accurate per SAP v2 <NA>    <NA>
#>                                                         entry_hash
#> 1 4dc9295b8c09d1db894f7a1c693a1df0d857084d53b0252d3b7aeff14a06ad58
#> 2 e1e4379505da590ef9bc1631856a3495c21c49897c4b83a8cec7e5170cf8d6e4
#> 3 07dd58624ab6758c7615c8da29d9370cf9f8d0829082ec02f0e299a9eb6fef93
#> 4 fa3c246296be8e5b2d279a17885caf855adf63483e3988e99d3b4f00175e23f2
#>                                                          prev_hash
#> 1 d0966e81caeac722a4ca6bc251a783e347a699ee6a18f8f187c6fbffd0e31e21
#> 2 4dc9295b8c09d1db894f7a1c693a1df0d857084d53b0252d3b7aeff14a06ad58
#> 3 e1e4379505da590ef9bc1631856a3495c21c49897c4b83a8cec7e5170cf8d6e4
#> 4 07dd58624ab6758c7615c8da29d9370cf9f8d0829082ec02f0e299a9eb6fef93

# Works directly on a .rlog file — no live session needed
# \donttest{
tmp <- tempfile(fileext = ".rlog")
log2 <- regulog_init(app = "analysis", version = "1.0", user = "jsmith",
  path = tmp)
log_action(log2,
  action = "run",
  object = "primary.R",
  reason = "Primary model fitted"
)
#> regulog: logged action 'run' on 'primary.R'
filter_log(tmp, type = "ACTION")
#>   entry_id                   timestamp      app app_version   user   type
#> 1        1 2026-07-07T13:57:25.963433Z analysis         1.0 jsmith ACTION
#>   action    object field before after               reason text meaning
#> 1    run primary.R  <NA>   <NA>  <NA> Primary model fitted <NA>    <NA>
#>                                                         entry_hash
#> 1 92fdaa44081de2ce5bacafd918f44195fe8442e8afcc40daed0d841eb12589f0
#>                                                          prev_hash
#> 1 9a1a6ef9dce1aa45dbb2a0cc87afecfe01338d090873e7814f560c025b2c60d4
# }
```
