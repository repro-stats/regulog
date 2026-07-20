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
#> 1        1 2026-07-20T11:22:45.655622Z analysis         1.0 jsmith    ACTION
#> 2        2 2026-07-20T11:22:45.656507Z analysis         1.0 jsmith      NOTE
#> 3        3 2026-07-20T11:22:45.657257Z analysis         1.0 jsmith    ACTION
#> 4        4 2026-07-20T11:22:45.658064Z analysis         1.0 jsmith SIGNATURE
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
#> 1 eb744664c27ea4820f839f99014319b3f9df073cf9d317b1420712f7a6c5a073
#> 2 0e861b7410cff0343561eff27a15d2fdd0cbafa99eecc2e32ee17ef58471d4de
#> 3 f777404c45349f5aec22acd174dceb9f728487152b5f77a573be871b21d5c4f1
#> 4 bc60089a5953d83b95630ebfb8d37a6aa3d4e784239148147d1fa1e67480cbc5
#>                                                          prev_hash
#> 1 c7f6621d87ec0cfffb0d4ad9b941fe0a626b93f8ed4c5181dc416e3e808444f2
#> 2 eb744664c27ea4820f839f99014319b3f9df073cf9d317b1420712f7a6c5a073
#> 3 0e861b7410cff0343561eff27a15d2fdd0cbafa99eecc2e32ee17ef58471d4de
#> 4 f777404c45349f5aec22acd174dceb9f728487152b5f77a573be871b21d5c4f1

# Only signatures
filter_log(log, type = "SIGNATURE")
#>   entry_id                   timestamp      app app_version   user      type
#> 1        4 2026-07-20T11:22:45.658064Z analysis         1.0 jsmith SIGNATURE
#>      action object           field before after
#> 1 signature jsmith entries_covered   <NA>     3
#>                                      reason text meaning
#> 1 Analysis complete and accurate per SAP v2 <NA>    <NA>
#>                                                         entry_hash
#> 1 bc60089a5953d83b95630ebfb8d37a6aa3d4e784239148147d1fa1e67480cbc5
#>                                                          prev_hash
#> 1 f777404c45349f5aec22acd174dceb9f728487152b5f77a573be871b21d5c4f1

# Actions and notes by a specific user
filter_log(log, type = c("ACTION", "NOTE"), user = "jsmith")
#>   entry_id                   timestamp      app app_version   user   type
#> 1        1 2026-07-20T11:22:45.655622Z analysis         1.0 jsmith ACTION
#> 2        2 2026-07-20T11:22:45.656507Z analysis         1.0 jsmith   NOTE
#> 3        3 2026-07-20T11:22:45.657257Z analysis         1.0 jsmith ACTION
#>   action      object field before after                                  reason
#> 1    run   primary.R  <NA>   <NA>  <NA>                    Primary model fitted
#> 2   note        <NA>  <NA>   <NA>  <NA> Outlier in subject 042 retained per SAP
#> 3 export results.csv  <NA>   <NA>  <NA>                         Sent to sponsor
#>   text meaning                                                       entry_hash
#> 1 <NA>    <NA> eb744664c27ea4820f839f99014319b3f9df073cf9d317b1420712f7a6c5a073
#> 2 <NA>    <NA> 0e861b7410cff0343561eff27a15d2fdd0cbafa99eecc2e32ee17ef58471d4de
#> 3 <NA>    <NA> f777404c45349f5aec22acd174dceb9f728487152b5f77a573be871b21d5c4f1
#>                                                          prev_hash
#> 1 c7f6621d87ec0cfffb0d4ad9b941fe0a626b93f8ed4c5181dc416e3e808444f2
#> 2 eb744664c27ea4820f839f99014319b3f9df073cf9d317b1420712f7a6c5a073
#> 3 0e861b7410cff0343561eff27a15d2fdd0cbafa99eecc2e32ee17ef58471d4de

# Entries within a date range
filter_log(log, from = "2026-06-01", to = "2026-12-31")
#>   entry_id                   timestamp      app app_version   user      type
#> 1        1 2026-07-20T11:22:45.655622Z analysis         1.0 jsmith    ACTION
#> 2        2 2026-07-20T11:22:45.656507Z analysis         1.0 jsmith      NOTE
#> 3        3 2026-07-20T11:22:45.657257Z analysis         1.0 jsmith    ACTION
#> 4        4 2026-07-20T11:22:45.658064Z analysis         1.0 jsmith SIGNATURE
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
#> 1 eb744664c27ea4820f839f99014319b3f9df073cf9d317b1420712f7a6c5a073
#> 2 0e861b7410cff0343561eff27a15d2fdd0cbafa99eecc2e32ee17ef58471d4de
#> 3 f777404c45349f5aec22acd174dceb9f728487152b5f77a573be871b21d5c4f1
#> 4 bc60089a5953d83b95630ebfb8d37a6aa3d4e784239148147d1fa1e67480cbc5
#>                                                          prev_hash
#> 1 c7f6621d87ec0cfffb0d4ad9b941fe0a626b93f8ed4c5181dc416e3e808444f2
#> 2 eb744664c27ea4820f839f99014319b3f9df073cf9d317b1420712f7a6c5a073
#> 3 0e861b7410cff0343561eff27a15d2fdd0cbafa99eecc2e32ee17ef58471d4de
#> 4 f777404c45349f5aec22acd174dceb9f728487152b5f77a573be871b21d5c4f1

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
#> 1        1 2026-07-20T11:22:45.688403Z analysis         1.0 jsmith ACTION
#>   action    object field before after               reason text meaning
#> 1    run primary.R  <NA>   <NA>  <NA> Primary model fitted <NA>    <NA>
#>                                                         entry_hash
#> 1 7161b051c12ab7835a2ec8e42e99e4de5e19e42eddbac11a8d5ca114ca369ea2
#>                                                          prev_hash
#> 1 29ac4cfdff86675040b0c0040dfcacb462427e8d2d053c9419a111e2208deaef
# }
```
