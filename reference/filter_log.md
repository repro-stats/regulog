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
#> 1        1 2026-07-01T20:00:41.263535Z analysis         1.0 jsmith    ACTION
#> 2        2 2026-07-01T20:00:41.264561Z analysis         1.0 jsmith      NOTE
#> 3        3 2026-07-01T20:00:41.265682Z analysis         1.0 jsmith    ACTION
#> 4        4 2026-07-01T20:00:41.266688Z analysis         1.0 jsmith SIGNATURE
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
#> 1 5909c84a16715946a46e86f2770dc0ce2fc532b8d95cfad7243e16239de3e5d3
#> 2 b851c85d08769714a21a4ef1b27022cb70de311f6464ee44e12780c3e42a642b
#> 3 09da5fc638b3a84bdfc774a7c19b40e03b440a15a6dc39fcda99a2b7445e5009
#> 4 0405dcc39bf4a09866c31579c7e4b4f567948df5e885886b5406d8eb95bbe0ee
#>                                                          prev_hash
#> 1 79c4cc6a7f6125effa21e709d1132fb13b83743acf24777c1e02dc29412bd860
#> 2 5909c84a16715946a46e86f2770dc0ce2fc532b8d95cfad7243e16239de3e5d3
#> 3 b851c85d08769714a21a4ef1b27022cb70de311f6464ee44e12780c3e42a642b
#> 4 09da5fc638b3a84bdfc774a7c19b40e03b440a15a6dc39fcda99a2b7445e5009

# Only signatures
filter_log(log, type = "SIGNATURE")
#>   entry_id                   timestamp      app app_version   user      type
#> 1        4 2026-07-01T20:00:41.266688Z analysis         1.0 jsmith SIGNATURE
#>      action object           field before after
#> 1 signature jsmith entries_covered   <NA>     3
#>                                      reason text meaning
#> 1 Analysis complete and accurate per SAP v2 <NA>    <NA>
#>                                                         entry_hash
#> 1 0405dcc39bf4a09866c31579c7e4b4f567948df5e885886b5406d8eb95bbe0ee
#>                                                          prev_hash
#> 1 09da5fc638b3a84bdfc774a7c19b40e03b440a15a6dc39fcda99a2b7445e5009

# Actions and notes by a specific user
filter_log(log, type = c("ACTION", "NOTE"), user = "jsmith")
#>   entry_id                   timestamp      app app_version   user   type
#> 1        1 2026-07-01T20:00:41.263535Z analysis         1.0 jsmith ACTION
#> 2        2 2026-07-01T20:00:41.264561Z analysis         1.0 jsmith   NOTE
#> 3        3 2026-07-01T20:00:41.265682Z analysis         1.0 jsmith ACTION
#>   action      object field before after                                  reason
#> 1    run   primary.R  <NA>   <NA>  <NA>                    Primary model fitted
#> 2   note        <NA>  <NA>   <NA>  <NA> Outlier in subject 042 retained per SAP
#> 3 export results.csv  <NA>   <NA>  <NA>                         Sent to sponsor
#>   text meaning                                                       entry_hash
#> 1 <NA>    <NA> 5909c84a16715946a46e86f2770dc0ce2fc532b8d95cfad7243e16239de3e5d3
#> 2 <NA>    <NA> b851c85d08769714a21a4ef1b27022cb70de311f6464ee44e12780c3e42a642b
#> 3 <NA>    <NA> 09da5fc638b3a84bdfc774a7c19b40e03b440a15a6dc39fcda99a2b7445e5009
#>                                                          prev_hash
#> 1 79c4cc6a7f6125effa21e709d1132fb13b83743acf24777c1e02dc29412bd860
#> 2 5909c84a16715946a46e86f2770dc0ce2fc532b8d95cfad7243e16239de3e5d3
#> 3 b851c85d08769714a21a4ef1b27022cb70de311f6464ee44e12780c3e42a642b

# Entries within a date range
filter_log(log, from = "2026-06-01", to = "2026-12-31")
#>   entry_id                   timestamp      app app_version   user      type
#> 1        1 2026-07-01T20:00:41.263535Z analysis         1.0 jsmith    ACTION
#> 2        2 2026-07-01T20:00:41.264561Z analysis         1.0 jsmith      NOTE
#> 3        3 2026-07-01T20:00:41.265682Z analysis         1.0 jsmith    ACTION
#> 4        4 2026-07-01T20:00:41.266688Z analysis         1.0 jsmith SIGNATURE
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
#> 1 5909c84a16715946a46e86f2770dc0ce2fc532b8d95cfad7243e16239de3e5d3
#> 2 b851c85d08769714a21a4ef1b27022cb70de311f6464ee44e12780c3e42a642b
#> 3 09da5fc638b3a84bdfc774a7c19b40e03b440a15a6dc39fcda99a2b7445e5009
#> 4 0405dcc39bf4a09866c31579c7e4b4f567948df5e885886b5406d8eb95bbe0ee
#>                                                          prev_hash
#> 1 79c4cc6a7f6125effa21e709d1132fb13b83743acf24777c1e02dc29412bd860
#> 2 5909c84a16715946a46e86f2770dc0ce2fc532b8d95cfad7243e16239de3e5d3
#> 3 b851c85d08769714a21a4ef1b27022cb70de311f6464ee44e12780c3e42a642b
#> 4 09da5fc638b3a84bdfc774a7c19b40e03b440a15a6dc39fcda99a2b7445e5009

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
#> 1        1 2026-07-01T20:00:41.298527Z analysis         1.0 jsmith ACTION
#>   action    object field before after               reason text meaning
#> 1    run primary.R  <NA>   <NA>  <NA> Primary model fitted <NA>    <NA>
#>                                                         entry_hash
#> 1 553254954edb4bb8da53a726b8e9ae6aa916fa7eb72ead3effa32f7bfd5f8cf1
#>                                                          prev_hash
#> 1 43690fd29b68310f44ad3ed34e618d3df6e30b236406a2fbc15439f824ae7d8d
# }
```
