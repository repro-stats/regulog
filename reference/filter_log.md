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
#> 1        1 2026-07-01T19:54:29.555531Z analysis         1.0 jsmith    ACTION
#> 2        2 2026-07-01T19:54:29.556521Z analysis         1.0 jsmith      NOTE
#> 3        3 2026-07-01T19:54:29.557423Z analysis         1.0 jsmith    ACTION
#> 4        4 2026-07-01T19:54:29.558393Z analysis         1.0 jsmith SIGNATURE
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
#> 1 903a7b296a7d43a57d05da09fb0644f4775908ebccf1ee4fb78e756a8d47b7de
#> 2 04d02dfd2c734e20048060552ade4ae9b59da83aa532fa32de729385d95e99d1
#> 3 d689da186187089fa7dc86e85b9d7fe45a94aac1caa54ceb2fc80f8206342bd5
#> 4 5798a23d16010845fa145dedb6e8f49f39daeebb0b02dced4a0fb87e71f0d575
#>                                                          prev_hash
#> 1 cb63cd05752ce928528e505702d53fce1f7a709f16f42c63d110efb7f24b83c6
#> 2 903a7b296a7d43a57d05da09fb0644f4775908ebccf1ee4fb78e756a8d47b7de
#> 3 04d02dfd2c734e20048060552ade4ae9b59da83aa532fa32de729385d95e99d1
#> 4 d689da186187089fa7dc86e85b9d7fe45a94aac1caa54ceb2fc80f8206342bd5

# Only signatures
filter_log(log, type = "SIGNATURE")
#>   entry_id                   timestamp      app app_version   user      type
#> 1        4 2026-07-01T19:54:29.558393Z analysis         1.0 jsmith SIGNATURE
#>      action object           field before after
#> 1 signature jsmith entries_covered   <NA>     3
#>                                      reason text meaning
#> 1 Analysis complete and accurate per SAP v2 <NA>    <NA>
#>                                                         entry_hash
#> 1 5798a23d16010845fa145dedb6e8f49f39daeebb0b02dced4a0fb87e71f0d575
#>                                                          prev_hash
#> 1 d689da186187089fa7dc86e85b9d7fe45a94aac1caa54ceb2fc80f8206342bd5

# Actions and notes by a specific user
filter_log(log, type = c("ACTION", "NOTE"), user = "jsmith")
#>   entry_id                   timestamp      app app_version   user   type
#> 1        1 2026-07-01T19:54:29.555531Z analysis         1.0 jsmith ACTION
#> 2        2 2026-07-01T19:54:29.556521Z analysis         1.0 jsmith   NOTE
#> 3        3 2026-07-01T19:54:29.557423Z analysis         1.0 jsmith ACTION
#>   action      object field before after                                  reason
#> 1    run   primary.R  <NA>   <NA>  <NA>                    Primary model fitted
#> 2   note        <NA>  <NA>   <NA>  <NA> Outlier in subject 042 retained per SAP
#> 3 export results.csv  <NA>   <NA>  <NA>                         Sent to sponsor
#>   text meaning                                                       entry_hash
#> 1 <NA>    <NA> 903a7b296a7d43a57d05da09fb0644f4775908ebccf1ee4fb78e756a8d47b7de
#> 2 <NA>    <NA> 04d02dfd2c734e20048060552ade4ae9b59da83aa532fa32de729385d95e99d1
#> 3 <NA>    <NA> d689da186187089fa7dc86e85b9d7fe45a94aac1caa54ceb2fc80f8206342bd5
#>                                                          prev_hash
#> 1 cb63cd05752ce928528e505702d53fce1f7a709f16f42c63d110efb7f24b83c6
#> 2 903a7b296a7d43a57d05da09fb0644f4775908ebccf1ee4fb78e756a8d47b7de
#> 3 04d02dfd2c734e20048060552ade4ae9b59da83aa532fa32de729385d95e99d1

# Entries within a date range
filter_log(log, from = "2026-06-01", to = "2026-12-31")
#>   entry_id                   timestamp      app app_version   user      type
#> 1        1 2026-07-01T19:54:29.555531Z analysis         1.0 jsmith    ACTION
#> 2        2 2026-07-01T19:54:29.556521Z analysis         1.0 jsmith      NOTE
#> 3        3 2026-07-01T19:54:29.557423Z analysis         1.0 jsmith    ACTION
#> 4        4 2026-07-01T19:54:29.558393Z analysis         1.0 jsmith SIGNATURE
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
#> 1 903a7b296a7d43a57d05da09fb0644f4775908ebccf1ee4fb78e756a8d47b7de
#> 2 04d02dfd2c734e20048060552ade4ae9b59da83aa532fa32de729385d95e99d1
#> 3 d689da186187089fa7dc86e85b9d7fe45a94aac1caa54ceb2fc80f8206342bd5
#> 4 5798a23d16010845fa145dedb6e8f49f39daeebb0b02dced4a0fb87e71f0d575
#>                                                          prev_hash
#> 1 cb63cd05752ce928528e505702d53fce1f7a709f16f42c63d110efb7f24b83c6
#> 2 903a7b296a7d43a57d05da09fb0644f4775908ebccf1ee4fb78e756a8d47b7de
#> 3 04d02dfd2c734e20048060552ade4ae9b59da83aa532fa32de729385d95e99d1
#> 4 d689da186187089fa7dc86e85b9d7fe45a94aac1caa54ceb2fc80f8206342bd5

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
#> 1        1 2026-07-01T19:54:29.590901Z analysis         1.0 jsmith ACTION
#>   action    object field before after               reason text meaning
#> 1    run primary.R  <NA>   <NA>  <NA> Primary model fitted <NA>    <NA>
#>                                                         entry_hash
#> 1 92d2b5a8197467617ff91725d0061ef731ae1c808d7f0d562cdcff82a4d4b5dc
#>                                                          prev_hash
#> 1 b2ecffe873492d976f96aeca19705da64c0d8db8b70b3ed3d35991611fcdedb0
# }
```
