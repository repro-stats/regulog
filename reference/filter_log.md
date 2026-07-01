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
#> 1        1 2026-07-01T15:47:05.347418Z analysis         1.0 jsmith    ACTION
#> 2        2 2026-07-01T15:47:05.348335Z analysis         1.0 jsmith      NOTE
#> 3        3 2026-07-01T15:47:05.349152Z analysis         1.0 jsmith    ACTION
#> 4        4 2026-07-01T15:47:05.350040Z analysis         1.0 jsmith SIGNATURE
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
#> 1 3e547585fb6595a28a758e5fd0ad5e8678bf6b6c43ed29f8e24ee08646a696f9
#> 2 e73407b3b5848a9e2f02fe91930faca8d01a19cd7330eac1b59fd428454689c7
#> 3 a85781d6f702484ff2f5574f9f054322f25a8f560268e50a825abfb5a1708a2b
#> 4 992143d7c3ed55a32d45133f67f95d7aaae3cdfd9b4956a39b02279da4a5b30f
#>                                                          prev_hash
#> 1 d49bbc7cbe7d24bd306e262d02a1eb7cd72756acbaf131f8b735bad4f3664e33
#> 2 3e547585fb6595a28a758e5fd0ad5e8678bf6b6c43ed29f8e24ee08646a696f9
#> 3 e73407b3b5848a9e2f02fe91930faca8d01a19cd7330eac1b59fd428454689c7
#> 4 a85781d6f702484ff2f5574f9f054322f25a8f560268e50a825abfb5a1708a2b

# Only signatures
filter_log(log, type = "SIGNATURE")
#>   entry_id                   timestamp      app app_version   user      type
#> 1        4 2026-07-01T15:47:05.350040Z analysis         1.0 jsmith SIGNATURE
#>      action object           field before after
#> 1 signature jsmith entries_covered   <NA>     3
#>                                      reason text meaning
#> 1 Analysis complete and accurate per SAP v2 <NA>    <NA>
#>                                                         entry_hash
#> 1 992143d7c3ed55a32d45133f67f95d7aaae3cdfd9b4956a39b02279da4a5b30f
#>                                                          prev_hash
#> 1 a85781d6f702484ff2f5574f9f054322f25a8f560268e50a825abfb5a1708a2b

# Actions and notes by a specific user
filter_log(log, type = c("ACTION", "NOTE"), user = "jsmith")
#>   entry_id                   timestamp      app app_version   user   type
#> 1        1 2026-07-01T15:47:05.347418Z analysis         1.0 jsmith ACTION
#> 2        2 2026-07-01T15:47:05.348335Z analysis         1.0 jsmith   NOTE
#> 3        3 2026-07-01T15:47:05.349152Z analysis         1.0 jsmith ACTION
#>   action      object field before after                                  reason
#> 1    run   primary.R  <NA>   <NA>  <NA>                    Primary model fitted
#> 2   note        <NA>  <NA>   <NA>  <NA> Outlier in subject 042 retained per SAP
#> 3 export results.csv  <NA>   <NA>  <NA>                         Sent to sponsor
#>   text meaning                                                       entry_hash
#> 1 <NA>    <NA> 3e547585fb6595a28a758e5fd0ad5e8678bf6b6c43ed29f8e24ee08646a696f9
#> 2 <NA>    <NA> e73407b3b5848a9e2f02fe91930faca8d01a19cd7330eac1b59fd428454689c7
#> 3 <NA>    <NA> a85781d6f702484ff2f5574f9f054322f25a8f560268e50a825abfb5a1708a2b
#>                                                          prev_hash
#> 1 d49bbc7cbe7d24bd306e262d02a1eb7cd72756acbaf131f8b735bad4f3664e33
#> 2 3e547585fb6595a28a758e5fd0ad5e8678bf6b6c43ed29f8e24ee08646a696f9
#> 3 e73407b3b5848a9e2f02fe91930faca8d01a19cd7330eac1b59fd428454689c7

# Entries within a date range
filter_log(log, from = "2026-06-01", to = "2026-12-31")
#>   entry_id                   timestamp      app app_version   user      type
#> 1        1 2026-07-01T15:47:05.347418Z analysis         1.0 jsmith    ACTION
#> 2        2 2026-07-01T15:47:05.348335Z analysis         1.0 jsmith      NOTE
#> 3        3 2026-07-01T15:47:05.349152Z analysis         1.0 jsmith    ACTION
#> 4        4 2026-07-01T15:47:05.350040Z analysis         1.0 jsmith SIGNATURE
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
#> 1 3e547585fb6595a28a758e5fd0ad5e8678bf6b6c43ed29f8e24ee08646a696f9
#> 2 e73407b3b5848a9e2f02fe91930faca8d01a19cd7330eac1b59fd428454689c7
#> 3 a85781d6f702484ff2f5574f9f054322f25a8f560268e50a825abfb5a1708a2b
#> 4 992143d7c3ed55a32d45133f67f95d7aaae3cdfd9b4956a39b02279da4a5b30f
#>                                                          prev_hash
#> 1 d49bbc7cbe7d24bd306e262d02a1eb7cd72756acbaf131f8b735bad4f3664e33
#> 2 3e547585fb6595a28a758e5fd0ad5e8678bf6b6c43ed29f8e24ee08646a696f9
#> 3 e73407b3b5848a9e2f02fe91930faca8d01a19cd7330eac1b59fd428454689c7
#> 4 a85781d6f702484ff2f5574f9f054322f25a8f560268e50a825abfb5a1708a2b

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
#> 1        1 2026-07-01T15:47:05.378182Z analysis         1.0 jsmith ACTION
#>   action    object field before after               reason text meaning
#> 1    run primary.R  <NA>   <NA>  <NA> Primary model fitted <NA>    <NA>
#>                                                         entry_hash
#> 1 8c6ac4247d3fdbb5405aa68a1ece22140b49e571be9a48aacd9954a7468e18b5
#>                                                          prev_hash
#> 1 b4651eafa54b0ff4ce50958b3e8c9ab43a8c640b6738bd5961f7ff76616c2df0
# }
```
