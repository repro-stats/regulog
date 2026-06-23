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
#> 1        1 2026-06-23T19:13:53.713863Z analysis         1.0 ndoh.penn    ACTION
#> 2        2 2026-06-23T19:13:53.714711Z analysis         1.0 ndoh.penn      NOTE
#> 3        3 2026-06-23T19:13:53.715478Z analysis         1.0 ndoh.penn    ACTION
#> 4        4 2026-06-23T19:13:53.716289Z analysis         1.0 ndoh.penn SIGNATURE
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
#> 1 c0fb00f293af35e8b4919d2e81e7c374d187440cef60de4273620dd0a7a0bdf5
#> 2 b6af2153f8912b179be2ad8919f288d1effca68d492b9b6410769222119d633c
#> 3 72922e313f78cc7e5846baf5180b93c51ff9bb43a5bd0dc4536b37ae27036e27
#> 4 a371582780076dfbbdde5c1a3e8189ea0c5429ebad6b274b909f0b26eefe972f
#>                                                          prev_hash
#> 1 5115faeeb60e1a45ac3854bf081f9a4555e2d1d40c3740da66fd6b40e06b3e0f
#> 2 c0fb00f293af35e8b4919d2e81e7c374d187440cef60de4273620dd0a7a0bdf5
#> 3 b6af2153f8912b179be2ad8919f288d1effca68d492b9b6410769222119d633c
#> 4 72922e313f78cc7e5846baf5180b93c51ff9bb43a5bd0dc4536b37ae27036e27

# Only signatures
filter_log(log, type = "SIGNATURE")
#>   entry_id                   timestamp      app app_version      user      type
#> 1        4 2026-06-23T19:13:53.716289Z analysis         1.0 ndoh.penn SIGNATURE
#>      action    object           field before after
#> 1 signature ndoh.penn entries_covered   <NA>     3
#>                                      reason
#> 1 Analysis complete and accurate per SAP v2
#>                                                         entry_hash
#> 1 a371582780076dfbbdde5c1a3e8189ea0c5429ebad6b274b909f0b26eefe972f
#>                                                          prev_hash
#> 1 72922e313f78cc7e5846baf5180b93c51ff9bb43a5bd0dc4536b37ae27036e27

# Actions and notes by a specific user
filter_log(log, type = c("ACTION", "NOTE"), user = "ndoh.penn")
#>   entry_id                   timestamp      app app_version      user   type
#> 1        1 2026-06-23T19:13:53.713863Z analysis         1.0 ndoh.penn ACTION
#> 2        2 2026-06-23T19:13:53.714711Z analysis         1.0 ndoh.penn   NOTE
#> 3        3 2026-06-23T19:13:53.715478Z analysis         1.0 ndoh.penn ACTION
#>   action      object field before after                                  reason
#> 1    run   primary.R  <NA>   <NA>  <NA>                    Primary model fitted
#> 2   note        <NA>  <NA>   <NA>  <NA> Outlier in subject 042 retained per SAP
#> 3 export results.csv  <NA>   <NA>  <NA>                         Sent to sponsor
#>                                                         entry_hash
#> 1 c0fb00f293af35e8b4919d2e81e7c374d187440cef60de4273620dd0a7a0bdf5
#> 2 b6af2153f8912b179be2ad8919f288d1effca68d492b9b6410769222119d633c
#> 3 72922e313f78cc7e5846baf5180b93c51ff9bb43a5bd0dc4536b37ae27036e27
#>                                                          prev_hash
#> 1 5115faeeb60e1a45ac3854bf081f9a4555e2d1d40c3740da66fd6b40e06b3e0f
#> 2 c0fb00f293af35e8b4919d2e81e7c374d187440cef60de4273620dd0a7a0bdf5
#> 3 b6af2153f8912b179be2ad8919f288d1effca68d492b9b6410769222119d633c

# Entries within a date range
filter_log(log, from = "2026-06-01", to = "2026-12-31")
#>   entry_id                   timestamp      app app_version      user      type
#> 1        1 2026-06-23T19:13:53.713863Z analysis         1.0 ndoh.penn    ACTION
#> 2        2 2026-06-23T19:13:53.714711Z analysis         1.0 ndoh.penn      NOTE
#> 3        3 2026-06-23T19:13:53.715478Z analysis         1.0 ndoh.penn    ACTION
#> 4        4 2026-06-23T19:13:53.716289Z analysis         1.0 ndoh.penn SIGNATURE
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
#> 1 c0fb00f293af35e8b4919d2e81e7c374d187440cef60de4273620dd0a7a0bdf5
#> 2 b6af2153f8912b179be2ad8919f288d1effca68d492b9b6410769222119d633c
#> 3 72922e313f78cc7e5846baf5180b93c51ff9bb43a5bd0dc4536b37ae27036e27
#> 4 a371582780076dfbbdde5c1a3e8189ea0c5429ebad6b274b909f0b26eefe972f
#>                                                          prev_hash
#> 1 5115faeeb60e1a45ac3854bf081f9a4555e2d1d40c3740da66fd6b40e06b3e0f
#> 2 c0fb00f293af35e8b4919d2e81e7c374d187440cef60de4273620dd0a7a0bdf5
#> 3 b6af2153f8912b179be2ad8919f288d1effca68d492b9b6410769222119d633c
#> 4 72922e313f78cc7e5846baf5180b93c51ff9bb43a5bd0dc4536b37ae27036e27

# Works directly on a .rlog file — no live session needed
if (FALSE) { # \dontrun{
filter_log("logs/audit.rlog", type = "SIGNATURE")
} # }
```
