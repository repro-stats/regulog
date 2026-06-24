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
#> 1        1 2026-06-24T22:24:03.847330Z analysis         1.0 ndoh.penn    ACTION
#> 2        2 2026-06-24T22:24:03.848152Z analysis         1.0 ndoh.penn      NOTE
#> 3        3 2026-06-24T22:24:03.848875Z analysis         1.0 ndoh.penn    ACTION
#> 4        4 2026-06-24T22:24:03.849667Z analysis         1.0 ndoh.penn SIGNATURE
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
#> 1 f528c0349a3154a4b2caf32ad9bc32330bff00e5d9dc756293ded49a650d41b3
#> 2 4706dfd080fb69374f220f4cac68385380bebbe2edec479014af795429455c0f
#> 3 302fea6c63f2fd38d4cd339285391c81b221bddf87d44d163a9abc7cc24895e9
#> 4 256aa9f8975e1f099a6e6286f2a1af26c6eb9eecab346398246310aec2502d86
#>                                                          prev_hash
#> 1 f831cfe06cab2cd853d945eaffc06b183801b1a77bc0843be34d941d0cf81f36
#> 2 f528c0349a3154a4b2caf32ad9bc32330bff00e5d9dc756293ded49a650d41b3
#> 3 4706dfd080fb69374f220f4cac68385380bebbe2edec479014af795429455c0f
#> 4 302fea6c63f2fd38d4cd339285391c81b221bddf87d44d163a9abc7cc24895e9

# Only signatures
filter_log(log, type = "SIGNATURE")
#>   entry_id                   timestamp      app app_version      user      type
#> 1        4 2026-06-24T22:24:03.849667Z analysis         1.0 ndoh.penn SIGNATURE
#>      action    object           field before after
#> 1 signature ndoh.penn entries_covered   <NA>     3
#>                                      reason
#> 1 Analysis complete and accurate per SAP v2
#>                                                         entry_hash
#> 1 256aa9f8975e1f099a6e6286f2a1af26c6eb9eecab346398246310aec2502d86
#>                                                          prev_hash
#> 1 302fea6c63f2fd38d4cd339285391c81b221bddf87d44d163a9abc7cc24895e9

# Actions and notes by a specific user
filter_log(log, type = c("ACTION", "NOTE"), user = "ndoh.penn")
#>   entry_id                   timestamp      app app_version      user   type
#> 1        1 2026-06-24T22:24:03.847330Z analysis         1.0 ndoh.penn ACTION
#> 2        2 2026-06-24T22:24:03.848152Z analysis         1.0 ndoh.penn   NOTE
#> 3        3 2026-06-24T22:24:03.848875Z analysis         1.0 ndoh.penn ACTION
#>   action      object field before after                                  reason
#> 1    run   primary.R  <NA>   <NA>  <NA>                    Primary model fitted
#> 2   note        <NA>  <NA>   <NA>  <NA> Outlier in subject 042 retained per SAP
#> 3 export results.csv  <NA>   <NA>  <NA>                         Sent to sponsor
#>                                                         entry_hash
#> 1 f528c0349a3154a4b2caf32ad9bc32330bff00e5d9dc756293ded49a650d41b3
#> 2 4706dfd080fb69374f220f4cac68385380bebbe2edec479014af795429455c0f
#> 3 302fea6c63f2fd38d4cd339285391c81b221bddf87d44d163a9abc7cc24895e9
#>                                                          prev_hash
#> 1 f831cfe06cab2cd853d945eaffc06b183801b1a77bc0843be34d941d0cf81f36
#> 2 f528c0349a3154a4b2caf32ad9bc32330bff00e5d9dc756293ded49a650d41b3
#> 3 4706dfd080fb69374f220f4cac68385380bebbe2edec479014af795429455c0f

# Entries within a date range
filter_log(log, from = "2026-06-01", to = "2026-12-31")
#>   entry_id                   timestamp      app app_version      user      type
#> 1        1 2026-06-24T22:24:03.847330Z analysis         1.0 ndoh.penn    ACTION
#> 2        2 2026-06-24T22:24:03.848152Z analysis         1.0 ndoh.penn      NOTE
#> 3        3 2026-06-24T22:24:03.848875Z analysis         1.0 ndoh.penn    ACTION
#> 4        4 2026-06-24T22:24:03.849667Z analysis         1.0 ndoh.penn SIGNATURE
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
#> 1 f528c0349a3154a4b2caf32ad9bc32330bff00e5d9dc756293ded49a650d41b3
#> 2 4706dfd080fb69374f220f4cac68385380bebbe2edec479014af795429455c0f
#> 3 302fea6c63f2fd38d4cd339285391c81b221bddf87d44d163a9abc7cc24895e9
#> 4 256aa9f8975e1f099a6e6286f2a1af26c6eb9eecab346398246310aec2502d86
#>                                                          prev_hash
#> 1 f831cfe06cab2cd853d945eaffc06b183801b1a77bc0843be34d941d0cf81f36
#> 2 f528c0349a3154a4b2caf32ad9bc32330bff00e5d9dc756293ded49a650d41b3
#> 3 4706dfd080fb69374f220f4cac68385380bebbe2edec479014af795429455c0f
#> 4 302fea6c63f2fd38d4cd339285391c81b221bddf87d44d163a9abc7cc24895e9

# Works directly on a .rlog file — no live session needed
if (FALSE) { # \dontrun{
filter_log("logs/audit.rlog", type = "SIGNATURE")
} # }
```
