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
#> 1        1 2026-06-30T09:48:31.485613Z analysis         1.0 ndoh.penn    ACTION
#> 2        2 2026-06-30T09:48:31.486460Z analysis         1.0 ndoh.penn      NOTE
#> 3        3 2026-06-30T09:48:31.487282Z analysis         1.0 ndoh.penn    ACTION
#> 4        4 2026-06-30T09:48:31.488155Z analysis         1.0 ndoh.penn SIGNATURE
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
#> 1 f9dfc9666f006bc571d4a0407501dcbb5481f38383a3c3506676442ce82b00b3
#> 2 d84423639515ba00c5dcd408144d82118f7e9b28bcc1b3494d63f51732e1d4c0
#> 3 11079cb15122ffec9cda7846c6ac8c372f281d7b34a4d4c1b4d0ad4ad8589e44
#> 4 0485d39d9dad4673ba082a497c6aaa70a0300d53fbd0202231d292122bcad151
#>                                                          prev_hash
#> 1 da32c080067368fd80b5f3a5e6803652b801a481abd79b5347924e18a4df87af
#> 2 f9dfc9666f006bc571d4a0407501dcbb5481f38383a3c3506676442ce82b00b3
#> 3 d84423639515ba00c5dcd408144d82118f7e9b28bcc1b3494d63f51732e1d4c0
#> 4 11079cb15122ffec9cda7846c6ac8c372f281d7b34a4d4c1b4d0ad4ad8589e44

# Only signatures
filter_log(log, type = "SIGNATURE")
#>   entry_id                   timestamp      app app_version      user      type
#> 1        4 2026-06-30T09:48:31.488155Z analysis         1.0 ndoh.penn SIGNATURE
#>      action    object           field before after
#> 1 signature ndoh.penn entries_covered   <NA>     3
#>                                      reason
#> 1 Analysis complete and accurate per SAP v2
#>                                                         entry_hash
#> 1 0485d39d9dad4673ba082a497c6aaa70a0300d53fbd0202231d292122bcad151
#>                                                          prev_hash
#> 1 11079cb15122ffec9cda7846c6ac8c372f281d7b34a4d4c1b4d0ad4ad8589e44

# Actions and notes by a specific user
filter_log(log, type = c("ACTION", "NOTE"), user = "ndoh.penn")
#>   entry_id                   timestamp      app app_version      user   type
#> 1        1 2026-06-30T09:48:31.485613Z analysis         1.0 ndoh.penn ACTION
#> 2        2 2026-06-30T09:48:31.486460Z analysis         1.0 ndoh.penn   NOTE
#> 3        3 2026-06-30T09:48:31.487282Z analysis         1.0 ndoh.penn ACTION
#>   action      object field before after                                  reason
#> 1    run   primary.R  <NA>   <NA>  <NA>                    Primary model fitted
#> 2   note        <NA>  <NA>   <NA>  <NA> Outlier in subject 042 retained per SAP
#> 3 export results.csv  <NA>   <NA>  <NA>                         Sent to sponsor
#>                                                         entry_hash
#> 1 f9dfc9666f006bc571d4a0407501dcbb5481f38383a3c3506676442ce82b00b3
#> 2 d84423639515ba00c5dcd408144d82118f7e9b28bcc1b3494d63f51732e1d4c0
#> 3 11079cb15122ffec9cda7846c6ac8c372f281d7b34a4d4c1b4d0ad4ad8589e44
#>                                                          prev_hash
#> 1 da32c080067368fd80b5f3a5e6803652b801a481abd79b5347924e18a4df87af
#> 2 f9dfc9666f006bc571d4a0407501dcbb5481f38383a3c3506676442ce82b00b3
#> 3 d84423639515ba00c5dcd408144d82118f7e9b28bcc1b3494d63f51732e1d4c0

# Entries within a date range
filter_log(log, from = "2026-06-01", to = "2026-12-31")
#>   entry_id                   timestamp      app app_version      user      type
#> 1        1 2026-06-30T09:48:31.485613Z analysis         1.0 ndoh.penn    ACTION
#> 2        2 2026-06-30T09:48:31.486460Z analysis         1.0 ndoh.penn      NOTE
#> 3        3 2026-06-30T09:48:31.487282Z analysis         1.0 ndoh.penn    ACTION
#> 4        4 2026-06-30T09:48:31.488155Z analysis         1.0 ndoh.penn SIGNATURE
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
#> 1 f9dfc9666f006bc571d4a0407501dcbb5481f38383a3c3506676442ce82b00b3
#> 2 d84423639515ba00c5dcd408144d82118f7e9b28bcc1b3494d63f51732e1d4c0
#> 3 11079cb15122ffec9cda7846c6ac8c372f281d7b34a4d4c1b4d0ad4ad8589e44
#> 4 0485d39d9dad4673ba082a497c6aaa70a0300d53fbd0202231d292122bcad151
#>                                                          prev_hash
#> 1 da32c080067368fd80b5f3a5e6803652b801a481abd79b5347924e18a4df87af
#> 2 f9dfc9666f006bc571d4a0407501dcbb5481f38383a3c3506676442ce82b00b3
#> 3 d84423639515ba00c5dcd408144d82118f7e9b28bcc1b3494d63f51732e1d4c0
#> 4 11079cb15122ffec9cda7846c6ac8c372f281d7b34a4d4c1b4d0ad4ad8589e44

# Works directly on a .rlog file — no live session needed
if (FALSE) { # \dontrun{
filter_log("logs/audit.rlog", type = "SIGNATURE")
} # }
```
