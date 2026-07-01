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
#> 1        1 2026-07-01T16:19:25.496463Z analysis         1.0 jsmith    ACTION
#> 2        2 2026-07-01T16:19:25.497447Z analysis         1.0 jsmith      NOTE
#> 3        3 2026-07-01T16:19:25.498305Z analysis         1.0 jsmith    ACTION
#> 4        4 2026-07-01T16:19:25.499216Z analysis         1.0 jsmith SIGNATURE
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
#> 1 d2151550859dcee9a5a6d7ecdb6a6ae1959221992b62f6557c83ace15d83858b
#> 2 4d5038d5a23d9c21c104e17dde0322ecdd6b0c9d2c2b84602d4a5457a33430aa
#> 3 8257b40ef3536a888bdfea803d6412a3827bd30e326a10210105bd28e328809d
#> 4 96236b7a95378a440da1b2cc8c6021449311e4f4d67162b6e73387527ae72d41
#>                                                          prev_hash
#> 1 480cf09108056a12c4728a55f05822532334dd0f7244645f018af84e596af037
#> 2 d2151550859dcee9a5a6d7ecdb6a6ae1959221992b62f6557c83ace15d83858b
#> 3 4d5038d5a23d9c21c104e17dde0322ecdd6b0c9d2c2b84602d4a5457a33430aa
#> 4 8257b40ef3536a888bdfea803d6412a3827bd30e326a10210105bd28e328809d

# Only signatures
filter_log(log, type = "SIGNATURE")
#>   entry_id                   timestamp      app app_version   user      type
#> 1        4 2026-07-01T16:19:25.499216Z analysis         1.0 jsmith SIGNATURE
#>      action object           field before after
#> 1 signature jsmith entries_covered   <NA>     3
#>                                      reason text meaning
#> 1 Analysis complete and accurate per SAP v2 <NA>    <NA>
#>                                                         entry_hash
#> 1 96236b7a95378a440da1b2cc8c6021449311e4f4d67162b6e73387527ae72d41
#>                                                          prev_hash
#> 1 8257b40ef3536a888bdfea803d6412a3827bd30e326a10210105bd28e328809d

# Actions and notes by a specific user
filter_log(log, type = c("ACTION", "NOTE"), user = "jsmith")
#>   entry_id                   timestamp      app app_version   user   type
#> 1        1 2026-07-01T16:19:25.496463Z analysis         1.0 jsmith ACTION
#> 2        2 2026-07-01T16:19:25.497447Z analysis         1.0 jsmith   NOTE
#> 3        3 2026-07-01T16:19:25.498305Z analysis         1.0 jsmith ACTION
#>   action      object field before after                                  reason
#> 1    run   primary.R  <NA>   <NA>  <NA>                    Primary model fitted
#> 2   note        <NA>  <NA>   <NA>  <NA> Outlier in subject 042 retained per SAP
#> 3 export results.csv  <NA>   <NA>  <NA>                         Sent to sponsor
#>   text meaning                                                       entry_hash
#> 1 <NA>    <NA> d2151550859dcee9a5a6d7ecdb6a6ae1959221992b62f6557c83ace15d83858b
#> 2 <NA>    <NA> 4d5038d5a23d9c21c104e17dde0322ecdd6b0c9d2c2b84602d4a5457a33430aa
#> 3 <NA>    <NA> 8257b40ef3536a888bdfea803d6412a3827bd30e326a10210105bd28e328809d
#>                                                          prev_hash
#> 1 480cf09108056a12c4728a55f05822532334dd0f7244645f018af84e596af037
#> 2 d2151550859dcee9a5a6d7ecdb6a6ae1959221992b62f6557c83ace15d83858b
#> 3 4d5038d5a23d9c21c104e17dde0322ecdd6b0c9d2c2b84602d4a5457a33430aa

# Entries within a date range
filter_log(log, from = "2026-06-01", to = "2026-12-31")
#>   entry_id                   timestamp      app app_version   user      type
#> 1        1 2026-07-01T16:19:25.496463Z analysis         1.0 jsmith    ACTION
#> 2        2 2026-07-01T16:19:25.497447Z analysis         1.0 jsmith      NOTE
#> 3        3 2026-07-01T16:19:25.498305Z analysis         1.0 jsmith    ACTION
#> 4        4 2026-07-01T16:19:25.499216Z analysis         1.0 jsmith SIGNATURE
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
#> 1 d2151550859dcee9a5a6d7ecdb6a6ae1959221992b62f6557c83ace15d83858b
#> 2 4d5038d5a23d9c21c104e17dde0322ecdd6b0c9d2c2b84602d4a5457a33430aa
#> 3 8257b40ef3536a888bdfea803d6412a3827bd30e326a10210105bd28e328809d
#> 4 96236b7a95378a440da1b2cc8c6021449311e4f4d67162b6e73387527ae72d41
#>                                                          prev_hash
#> 1 480cf09108056a12c4728a55f05822532334dd0f7244645f018af84e596af037
#> 2 d2151550859dcee9a5a6d7ecdb6a6ae1959221992b62f6557c83ace15d83858b
#> 3 4d5038d5a23d9c21c104e17dde0322ecdd6b0c9d2c2b84602d4a5457a33430aa
#> 4 8257b40ef3536a888bdfea803d6412a3827bd30e326a10210105bd28e328809d

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
#> 1        1 2026-07-01T16:19:25.530165Z analysis         1.0 jsmith ACTION
#>   action    object field before after               reason text meaning
#> 1    run primary.R  <NA>   <NA>  <NA> Primary model fitted <NA>    <NA>
#>                                                         entry_hash
#> 1 f7d041bad69b60d12469c2c947d9a7c77290a59774a8a5f59ea6ed05c40240f6
#>                                                          prev_hash
#> 1 7594379bc62a422d0ded8e10bea44894de1cb04b201348d20052fa5ee7c33d7b
# }
```
