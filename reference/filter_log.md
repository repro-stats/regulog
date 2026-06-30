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
  `"signature"`, `"note"`, `"data_read"`). `NULL` returns all actions.

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
log_action(log, "run", "primary.R", "Primary model fitted")
#> regulog: logged action 'run' on 'primary.R'
log_note(log, "Outlier in subject 042 retained per SAP")
#> regulog: note logged
log_action(log, "export", "results.csv", "Sent to sponsor")
#> regulog: logged action 'export' on 'results.csv'
log_signature(log, "Analysis complete and accurate per SAP v2")
#> regulog: signature applied by 'jsmith' covering 3 entries

# All entries as a data frame
filter_log(log)
#>   entry_id                   timestamp      app app_version   user      type
#> 1        1 2026-06-30T19:02:18.191481Z analysis         1.0 jsmith    ACTION
#> 2        2 2026-06-30T19:02:18.192379Z analysis         1.0 jsmith      NOTE
#> 3        3 2026-06-30T19:02:18.193193Z analysis         1.0 jsmith    ACTION
#> 4        4 2026-06-30T19:02:18.194074Z analysis         1.0 jsmith SIGNATURE
#>      action      object           field before after
#> 1       run   primary.R            <NA>   <NA>  <NA>
#> 2      note        <NA>            <NA>   <NA>  <NA>
#> 3    export results.csv            <NA>   <NA>  <NA>
#> 4 signature      jsmith entries_covered   <NA>     3
#>                                      reason
#> 1                      Primary model fitted
#> 2   Outlier in subject 042 retained per SAP
#> 3                           Sent to sponsor
#> 4 Analysis complete and accurate per SAP v2
#>                                                         entry_hash
#> 1 69628b859243b27a707d2b909982c4b4a0df051fcdcb6548a67179f5c63da99d
#> 2 764cd64b7ee46c9f87c38e732a707ff4fc2890a0313afa2e727bbe07538ae827
#> 3 8108a22cefcf0e0dbc69dd959d26f93d85cdb96a7f17140dde8d1ad26147d98b
#> 4 cf986b301d62872e8ed14cff9a83ffaf5f582e4818495d5ed2286a3b2cd89cd5
#>                                                          prev_hash
#> 1 14a3eed0d0bf1ecf52e758156ecaec5cf2aae467cf5170c7566e52046b92f617
#> 2 69628b859243b27a707d2b909982c4b4a0df051fcdcb6548a67179f5c63da99d
#> 3 764cd64b7ee46c9f87c38e732a707ff4fc2890a0313afa2e727bbe07538ae827
#> 4 8108a22cefcf0e0dbc69dd959d26f93d85cdb96a7f17140dde8d1ad26147d98b

# Only signatures
filter_log(log, type = "SIGNATURE")
#>   entry_id                   timestamp      app app_version   user      type
#> 1        4 2026-06-30T19:02:18.194074Z analysis         1.0 jsmith SIGNATURE
#>      action object           field before after
#> 1 signature jsmith entries_covered   <NA>     3
#>                                      reason
#> 1 Analysis complete and accurate per SAP v2
#>                                                         entry_hash
#> 1 cf986b301d62872e8ed14cff9a83ffaf5f582e4818495d5ed2286a3b2cd89cd5
#>                                                          prev_hash
#> 1 8108a22cefcf0e0dbc69dd959d26f93d85cdb96a7f17140dde8d1ad26147d98b

# Actions and notes by a specific user
filter_log(log, type = c("ACTION", "NOTE"), user = "jsmith")
#>   entry_id                   timestamp      app app_version   user   type
#> 1        1 2026-06-30T19:02:18.191481Z analysis         1.0 jsmith ACTION
#> 2        2 2026-06-30T19:02:18.192379Z analysis         1.0 jsmith   NOTE
#> 3        3 2026-06-30T19:02:18.193193Z analysis         1.0 jsmith ACTION
#>   action      object field before after                                  reason
#> 1    run   primary.R  <NA>   <NA>  <NA>                    Primary model fitted
#> 2   note        <NA>  <NA>   <NA>  <NA> Outlier in subject 042 retained per SAP
#> 3 export results.csv  <NA>   <NA>  <NA>                         Sent to sponsor
#>                                                         entry_hash
#> 1 69628b859243b27a707d2b909982c4b4a0df051fcdcb6548a67179f5c63da99d
#> 2 764cd64b7ee46c9f87c38e732a707ff4fc2890a0313afa2e727bbe07538ae827
#> 3 8108a22cefcf0e0dbc69dd959d26f93d85cdb96a7f17140dde8d1ad26147d98b
#>                                                          prev_hash
#> 1 14a3eed0d0bf1ecf52e758156ecaec5cf2aae467cf5170c7566e52046b92f617
#> 2 69628b859243b27a707d2b909982c4b4a0df051fcdcb6548a67179f5c63da99d
#> 3 764cd64b7ee46c9f87c38e732a707ff4fc2890a0313afa2e727bbe07538ae827

# Entries within a date range
filter_log(log, from = "2026-06-01", to = "2026-12-31")
#>   entry_id                   timestamp      app app_version   user      type
#> 1        1 2026-06-30T19:02:18.191481Z analysis         1.0 jsmith    ACTION
#> 2        2 2026-06-30T19:02:18.192379Z analysis         1.0 jsmith      NOTE
#> 3        3 2026-06-30T19:02:18.193193Z analysis         1.0 jsmith    ACTION
#> 4        4 2026-06-30T19:02:18.194074Z analysis         1.0 jsmith SIGNATURE
#>      action      object           field before after
#> 1       run   primary.R            <NA>   <NA>  <NA>
#> 2      note        <NA>            <NA>   <NA>  <NA>
#> 3    export results.csv            <NA>   <NA>  <NA>
#> 4 signature      jsmith entries_covered   <NA>     3
#>                                      reason
#> 1                      Primary model fitted
#> 2   Outlier in subject 042 retained per SAP
#> 3                           Sent to sponsor
#> 4 Analysis complete and accurate per SAP v2
#>                                                         entry_hash
#> 1 69628b859243b27a707d2b909982c4b4a0df051fcdcb6548a67179f5c63da99d
#> 2 764cd64b7ee46c9f87c38e732a707ff4fc2890a0313afa2e727bbe07538ae827
#> 3 8108a22cefcf0e0dbc69dd959d26f93d85cdb96a7f17140dde8d1ad26147d98b
#> 4 cf986b301d62872e8ed14cff9a83ffaf5f582e4818495d5ed2286a3b2cd89cd5
#>                                                          prev_hash
#> 1 14a3eed0d0bf1ecf52e758156ecaec5cf2aae467cf5170c7566e52046b92f617
#> 2 69628b859243b27a707d2b909982c4b4a0df051fcdcb6548a67179f5c63da99d
#> 3 764cd64b7ee46c9f87c38e732a707ff4fc2890a0313afa2e727bbe07538ae827
#> 4 8108a22cefcf0e0dbc69dd959d26f93d85cdb96a7f17140dde8d1ad26147d98b

# Works directly on a .rlog file — no live session needed
if (FALSE) { # \dontrun{
filter_log("logs/audit.rlog", type = "SIGNATURE")
} # }
```
