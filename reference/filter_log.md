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
#> 1        1 2026-07-20T09:08:20.914039Z analysis         1.0 jsmith    ACTION
#> 2        2 2026-07-20T09:08:20.914949Z analysis         1.0 jsmith      NOTE
#> 3        3 2026-07-20T09:08:20.915675Z analysis         1.0 jsmith    ACTION
#> 4        4 2026-07-20T09:08:20.916469Z analysis         1.0 jsmith SIGNATURE
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
#> 1 d73f8769c52135f56d7f8632c0be0424a2b4daa0ab976c00b29a7018bb008b2b
#> 2 6c85ea4c7d6dc8cd7823e05c53648ed1f3abe64bc62986ec2be743e1eedfd1a0
#> 3 6c8abc4562cfee008c5e93ad612e6a75720a4b7ce644b68c090ef38bee71fcdd
#> 4 16816604806e2f2b1e7417d38b7ba328ad315ae7d46b24374ac5738492453c03
#>                                                          prev_hash
#> 1 4367a5f0fd1667033b1a59b43c8ce45e58e6aa0666daf8af9ee995fe7510e701
#> 2 d73f8769c52135f56d7f8632c0be0424a2b4daa0ab976c00b29a7018bb008b2b
#> 3 6c85ea4c7d6dc8cd7823e05c53648ed1f3abe64bc62986ec2be743e1eedfd1a0
#> 4 6c8abc4562cfee008c5e93ad612e6a75720a4b7ce644b68c090ef38bee71fcdd

# Only signatures
filter_log(log, type = "SIGNATURE")
#>   entry_id                   timestamp      app app_version   user      type
#> 1        4 2026-07-20T09:08:20.916469Z analysis         1.0 jsmith SIGNATURE
#>      action object           field before after
#> 1 signature jsmith entries_covered   <NA>     3
#>                                      reason text meaning
#> 1 Analysis complete and accurate per SAP v2 <NA>    <NA>
#>                                                         entry_hash
#> 1 16816604806e2f2b1e7417d38b7ba328ad315ae7d46b24374ac5738492453c03
#>                                                          prev_hash
#> 1 6c8abc4562cfee008c5e93ad612e6a75720a4b7ce644b68c090ef38bee71fcdd

# Actions and notes by a specific user
filter_log(log, type = c("ACTION", "NOTE"), user = "jsmith")
#>   entry_id                   timestamp      app app_version   user   type
#> 1        1 2026-07-20T09:08:20.914039Z analysis         1.0 jsmith ACTION
#> 2        2 2026-07-20T09:08:20.914949Z analysis         1.0 jsmith   NOTE
#> 3        3 2026-07-20T09:08:20.915675Z analysis         1.0 jsmith ACTION
#>   action      object field before after                                  reason
#> 1    run   primary.R  <NA>   <NA>  <NA>                    Primary model fitted
#> 2   note        <NA>  <NA>   <NA>  <NA> Outlier in subject 042 retained per SAP
#> 3 export results.csv  <NA>   <NA>  <NA>                         Sent to sponsor
#>   text meaning                                                       entry_hash
#> 1 <NA>    <NA> d73f8769c52135f56d7f8632c0be0424a2b4daa0ab976c00b29a7018bb008b2b
#> 2 <NA>    <NA> 6c85ea4c7d6dc8cd7823e05c53648ed1f3abe64bc62986ec2be743e1eedfd1a0
#> 3 <NA>    <NA> 6c8abc4562cfee008c5e93ad612e6a75720a4b7ce644b68c090ef38bee71fcdd
#>                                                          prev_hash
#> 1 4367a5f0fd1667033b1a59b43c8ce45e58e6aa0666daf8af9ee995fe7510e701
#> 2 d73f8769c52135f56d7f8632c0be0424a2b4daa0ab976c00b29a7018bb008b2b
#> 3 6c85ea4c7d6dc8cd7823e05c53648ed1f3abe64bc62986ec2be743e1eedfd1a0

# Entries within a date range
filter_log(log, from = "2026-06-01", to = "2026-12-31")
#>   entry_id                   timestamp      app app_version   user      type
#> 1        1 2026-07-20T09:08:20.914039Z analysis         1.0 jsmith    ACTION
#> 2        2 2026-07-20T09:08:20.914949Z analysis         1.0 jsmith      NOTE
#> 3        3 2026-07-20T09:08:20.915675Z analysis         1.0 jsmith    ACTION
#> 4        4 2026-07-20T09:08:20.916469Z analysis         1.0 jsmith SIGNATURE
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
#> 1 d73f8769c52135f56d7f8632c0be0424a2b4daa0ab976c00b29a7018bb008b2b
#> 2 6c85ea4c7d6dc8cd7823e05c53648ed1f3abe64bc62986ec2be743e1eedfd1a0
#> 3 6c8abc4562cfee008c5e93ad612e6a75720a4b7ce644b68c090ef38bee71fcdd
#> 4 16816604806e2f2b1e7417d38b7ba328ad315ae7d46b24374ac5738492453c03
#>                                                          prev_hash
#> 1 4367a5f0fd1667033b1a59b43c8ce45e58e6aa0666daf8af9ee995fe7510e701
#> 2 d73f8769c52135f56d7f8632c0be0424a2b4daa0ab976c00b29a7018bb008b2b
#> 3 6c85ea4c7d6dc8cd7823e05c53648ed1f3abe64bc62986ec2be743e1eedfd1a0
#> 4 6c8abc4562cfee008c5e93ad612e6a75720a4b7ce644b68c090ef38bee71fcdd

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
#> 1        1 2026-07-20T09:08:20.941659Z analysis         1.0 jsmith ACTION
#>   action    object field before after               reason text meaning
#> 1    run primary.R  <NA>   <NA>  <NA> Primary model fitted <NA>    <NA>
#>                                                         entry_hash
#> 1 38725f6c27622a96a31324a0c3dd6802870d2d7927b06907c0a9e64c4f204c6d
#>                                                          prev_hash
#> 1 83ceabbcac743e847c5b3500e2745904b69c6fada988a5ac6e7e23924168a403
# }
```
