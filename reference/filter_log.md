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
#> 1        1 2026-07-01T16:04:02.614017Z analysis         1.0 jsmith    ACTION
#> 2        2 2026-07-01T16:04:02.615891Z analysis         1.0 jsmith      NOTE
#> 3        3 2026-07-01T16:04:02.617526Z analysis         1.0 jsmith    ACTION
#> 4        4 2026-07-01T16:04:02.619218Z analysis         1.0 jsmith SIGNATURE
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
#> 1 b2fd9bdf3eefc16a7e97f13e7ab67d493c1d0c9b11668952c6b5db34c16785c8
#> 2 d76f5c8d61067f3b0cf69240ec5cb7c923e3e579e741dfff17f1af1451bb5e7d
#> 3 4c4d897dd06b5a891213084e549ad51518b9fd6ab0c29bb011fa70cb6e703954
#> 4 63286e39bd7cb3f6fd37cc19853a05da32f965c95db0845d40eb763d5c0e2335
#>                                                          prev_hash
#> 1 74c31e46983ce29fc5eb4ccd63369f969073a1356ed001beb1bb3493b493c655
#> 2 b2fd9bdf3eefc16a7e97f13e7ab67d493c1d0c9b11668952c6b5db34c16785c8
#> 3 d76f5c8d61067f3b0cf69240ec5cb7c923e3e579e741dfff17f1af1451bb5e7d
#> 4 4c4d897dd06b5a891213084e549ad51518b9fd6ab0c29bb011fa70cb6e703954

# Only signatures
filter_log(log, type = "SIGNATURE")
#>   entry_id                   timestamp      app app_version   user      type
#> 1        4 2026-07-01T16:04:02.619218Z analysis         1.0 jsmith SIGNATURE
#>      action object           field before after
#> 1 signature jsmith entries_covered   <NA>     3
#>                                      reason text meaning
#> 1 Analysis complete and accurate per SAP v2 <NA>    <NA>
#>                                                         entry_hash
#> 1 63286e39bd7cb3f6fd37cc19853a05da32f965c95db0845d40eb763d5c0e2335
#>                                                          prev_hash
#> 1 4c4d897dd06b5a891213084e549ad51518b9fd6ab0c29bb011fa70cb6e703954

# Actions and notes by a specific user
filter_log(log, type = c("ACTION", "NOTE"), user = "jsmith")
#>   entry_id                   timestamp      app app_version   user   type
#> 1        1 2026-07-01T16:04:02.614017Z analysis         1.0 jsmith ACTION
#> 2        2 2026-07-01T16:04:02.615891Z analysis         1.0 jsmith   NOTE
#> 3        3 2026-07-01T16:04:02.617526Z analysis         1.0 jsmith ACTION
#>   action      object field before after                                  reason
#> 1    run   primary.R  <NA>   <NA>  <NA>                    Primary model fitted
#> 2   note        <NA>  <NA>   <NA>  <NA> Outlier in subject 042 retained per SAP
#> 3 export results.csv  <NA>   <NA>  <NA>                         Sent to sponsor
#>   text meaning                                                       entry_hash
#> 1 <NA>    <NA> b2fd9bdf3eefc16a7e97f13e7ab67d493c1d0c9b11668952c6b5db34c16785c8
#> 2 <NA>    <NA> d76f5c8d61067f3b0cf69240ec5cb7c923e3e579e741dfff17f1af1451bb5e7d
#> 3 <NA>    <NA> 4c4d897dd06b5a891213084e549ad51518b9fd6ab0c29bb011fa70cb6e703954
#>                                                          prev_hash
#> 1 74c31e46983ce29fc5eb4ccd63369f969073a1356ed001beb1bb3493b493c655
#> 2 b2fd9bdf3eefc16a7e97f13e7ab67d493c1d0c9b11668952c6b5db34c16785c8
#> 3 d76f5c8d61067f3b0cf69240ec5cb7c923e3e579e741dfff17f1af1451bb5e7d

# Entries within a date range
filter_log(log, from = "2026-06-01", to = "2026-12-31")
#>   entry_id                   timestamp      app app_version   user      type
#> 1        1 2026-07-01T16:04:02.614017Z analysis         1.0 jsmith    ACTION
#> 2        2 2026-07-01T16:04:02.615891Z analysis         1.0 jsmith      NOTE
#> 3        3 2026-07-01T16:04:02.617526Z analysis         1.0 jsmith    ACTION
#> 4        4 2026-07-01T16:04:02.619218Z analysis         1.0 jsmith SIGNATURE
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
#> 1 b2fd9bdf3eefc16a7e97f13e7ab67d493c1d0c9b11668952c6b5db34c16785c8
#> 2 d76f5c8d61067f3b0cf69240ec5cb7c923e3e579e741dfff17f1af1451bb5e7d
#> 3 4c4d897dd06b5a891213084e549ad51518b9fd6ab0c29bb011fa70cb6e703954
#> 4 63286e39bd7cb3f6fd37cc19853a05da32f965c95db0845d40eb763d5c0e2335
#>                                                          prev_hash
#> 1 74c31e46983ce29fc5eb4ccd63369f969073a1356ed001beb1bb3493b493c655
#> 2 b2fd9bdf3eefc16a7e97f13e7ab67d493c1d0c9b11668952c6b5db34c16785c8
#> 3 d76f5c8d61067f3b0cf69240ec5cb7c923e3e579e741dfff17f1af1451bb5e7d
#> 4 4c4d897dd06b5a891213084e549ad51518b9fd6ab0c29bb011fa70cb6e703954

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
#> 1        1 2026-07-01T16:04:02.656026Z analysis         1.0 jsmith ACTION
#>   action    object field before after               reason text meaning
#> 1    run primary.R  <NA>   <NA>  <NA> Primary model fitted <NA>    <NA>
#>                                                         entry_hash
#> 1 2f454b92fa61d61a9d5abe2fb83be9b9575c6452e5f56ca21ea4fc4c2009b5ca
#>                                                          prev_hash
#> 1 c879d59f6bb949f08f0b9c731f0a5da56b149f5d9a3f9d6f8af6d0270a17f357
# }
```
