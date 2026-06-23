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

[`as.data.frame.regulog()`](https://repro-stats.github.io/regulog/reference/as.data.frame.regulog.md),
[`export_audit_trail()`](https://repro-stats.github.io/regulog/reference/export_audit_trail.md),
[`verify_log()`](https://repro-stats.github.io/regulog/reference/verify_log.md)

## Examples

``` r
log <- regulog_init(app = "analysis", version = "1.0", user = "ndoh.penn")
log_action(log, "run",    "primary.R",   "Primary model fitted")
#> regulog: logged action 'run' on 'primary.R'
log_note(log,   "Outlier in subject 042 retained per SAP")
#> regulog: note logged
log_action(log, "export", "results.csv", "Sent to sponsor")
#> regulog: logged action 'export' on 'results.csv'
log_signature(log, "Analysis complete and accurate per SAP v2")
#> regulog: signature applied by 'ndoh.penn' covering 3 entries

# All entries as a data frame
filter_log(log)
#>   entry_id                   timestamp      app app_version      user      type
#> 1        1 2026-06-23T19:32:42.676996Z analysis         1.0 ndoh.penn    ACTION
#> 2        2 2026-06-23T19:32:42.677814Z analysis         1.0 ndoh.penn      NOTE
#> 3        3 2026-06-23T19:32:42.678534Z analysis         1.0 ndoh.penn    ACTION
#> 4        4 2026-06-23T19:32:42.679357Z analysis         1.0 ndoh.penn SIGNATURE
#>      action      object           field before after
#> 1       run   primary.R            <NA>   <NA>  <NA>
#> 2      note        <NA>            <NA>   <NA>  <NA>
#> 3    export results.csv            <NA>   <NA>  <NA>
#> 4 signature   ndoh.penn entries_covered   <NA>     3
#>                                      reason
#> 1                      Primary model fitted
#> 2   Outlier in subject 042 retained per SAP
#> 3                           Sent to sponsor
#> 4 Analysis complete and accurate per SAP v2
#>                                                         entry_hash
#> 1 28dd8f04f508825310d3fe7bc1e72e15d3dd1e877569eacc35bd11d7d56d8a37
#> 2 4c08abd834a205203693619d2e2e56998c8e9ce17e40a7eae987287fcad882c1
#> 3 f2e5e36750dd2b59994d56bb06be7eb65e79ba1f7eefe3e6418458417c93d558
#> 4 838616d207d510931db295b3a5810e708075eb03f83e3989a9e0769c8f431ee0
#>                                                          prev_hash
#> 1 085543c46100e3fed86019203a18c0002a2943dd1f7cebf7d203f28e1c7e05eb
#> 2 28dd8f04f508825310d3fe7bc1e72e15d3dd1e877569eacc35bd11d7d56d8a37
#> 3 4c08abd834a205203693619d2e2e56998c8e9ce17e40a7eae987287fcad882c1
#> 4 f2e5e36750dd2b59994d56bb06be7eb65e79ba1f7eefe3e6418458417c93d558

# Only signatures
filter_log(log, type = "SIGNATURE")
#>   entry_id                   timestamp      app app_version      user      type
#> 1        4 2026-06-23T19:32:42.679357Z analysis         1.0 ndoh.penn SIGNATURE
#>      action    object           field before after
#> 1 signature ndoh.penn entries_covered   <NA>     3
#>                                      reason
#> 1 Analysis complete and accurate per SAP v2
#>                                                         entry_hash
#> 1 838616d207d510931db295b3a5810e708075eb03f83e3989a9e0769c8f431ee0
#>                                                          prev_hash
#> 1 f2e5e36750dd2b59994d56bb06be7eb65e79ba1f7eefe3e6418458417c93d558

# Actions and notes by a specific user
filter_log(log, type = c("ACTION", "NOTE"), user = "ndoh.penn")
#>   entry_id                   timestamp      app app_version      user   type
#> 1        1 2026-06-23T19:32:42.676996Z analysis         1.0 ndoh.penn ACTION
#> 2        2 2026-06-23T19:32:42.677814Z analysis         1.0 ndoh.penn   NOTE
#> 3        3 2026-06-23T19:32:42.678534Z analysis         1.0 ndoh.penn ACTION
#>   action      object field before after                                  reason
#> 1    run   primary.R  <NA>   <NA>  <NA>                    Primary model fitted
#> 2   note        <NA>  <NA>   <NA>  <NA> Outlier in subject 042 retained per SAP
#> 3 export results.csv  <NA>   <NA>  <NA>                         Sent to sponsor
#>                                                         entry_hash
#> 1 28dd8f04f508825310d3fe7bc1e72e15d3dd1e877569eacc35bd11d7d56d8a37
#> 2 4c08abd834a205203693619d2e2e56998c8e9ce17e40a7eae987287fcad882c1
#> 3 f2e5e36750dd2b59994d56bb06be7eb65e79ba1f7eefe3e6418458417c93d558
#>                                                          prev_hash
#> 1 085543c46100e3fed86019203a18c0002a2943dd1f7cebf7d203f28e1c7e05eb
#> 2 28dd8f04f508825310d3fe7bc1e72e15d3dd1e877569eacc35bd11d7d56d8a37
#> 3 4c08abd834a205203693619d2e2e56998c8e9ce17e40a7eae987287fcad882c1

# Entries within a date range
filter_log(log, from = "2026-06-01", to = "2026-12-31")
#>   entry_id                   timestamp      app app_version      user      type
#> 1        1 2026-06-23T19:32:42.676996Z analysis         1.0 ndoh.penn    ACTION
#> 2        2 2026-06-23T19:32:42.677814Z analysis         1.0 ndoh.penn      NOTE
#> 3        3 2026-06-23T19:32:42.678534Z analysis         1.0 ndoh.penn    ACTION
#> 4        4 2026-06-23T19:32:42.679357Z analysis         1.0 ndoh.penn SIGNATURE
#>      action      object           field before after
#> 1       run   primary.R            <NA>   <NA>  <NA>
#> 2      note        <NA>            <NA>   <NA>  <NA>
#> 3    export results.csv            <NA>   <NA>  <NA>
#> 4 signature   ndoh.penn entries_covered   <NA>     3
#>                                      reason
#> 1                      Primary model fitted
#> 2   Outlier in subject 042 retained per SAP
#> 3                           Sent to sponsor
#> 4 Analysis complete and accurate per SAP v2
#>                                                         entry_hash
#> 1 28dd8f04f508825310d3fe7bc1e72e15d3dd1e877569eacc35bd11d7d56d8a37
#> 2 4c08abd834a205203693619d2e2e56998c8e9ce17e40a7eae987287fcad882c1
#> 3 f2e5e36750dd2b59994d56bb06be7eb65e79ba1f7eefe3e6418458417c93d558
#> 4 838616d207d510931db295b3a5810e708075eb03f83e3989a9e0769c8f431ee0
#>                                                          prev_hash
#> 1 085543c46100e3fed86019203a18c0002a2943dd1f7cebf7d203f28e1c7e05eb
#> 2 28dd8f04f508825310d3fe7bc1e72e15d3dd1e877569eacc35bd11d7d56d8a37
#> 3 4c08abd834a205203693619d2e2e56998c8e9ce17e40a7eae987287fcad882c1
#> 4 f2e5e36750dd2b59994d56bb06be7eb65e79ba1f7eefe3e6418458417c93d558

# Works directly on a .rlog file — no live session needed
if (FALSE) { # \dontrun{
filter_log("logs/audit.rlog", type = "SIGNATURE")
} # }
```
