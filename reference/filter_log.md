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
#> 1        1 2026-06-24T10:22:47.759002Z analysis         1.0 ndoh.penn    ACTION
#> 2        2 2026-06-24T10:22:47.759625Z analysis         1.0 ndoh.penn      NOTE
#> 3        3 2026-06-24T10:22:47.760246Z analysis         1.0 ndoh.penn    ACTION
#> 4        4 2026-06-24T10:22:47.760893Z analysis         1.0 ndoh.penn SIGNATURE
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
#> 1 6751e95b51cfc5da88000956a9f037d0f1a555f2d348354ffd1924d1c6c2298c
#> 2 7acde28f9118768270d512d4fc6152068c2c6d84633d0d4d43def2d955f6767c
#> 3 996f93efd883f75b6777a1808281f7c6c72eb693d26dadf9be3c001c67362e80
#> 4 8a19856e905d72064a4f4eaf1e1ddfed6eb08e9b0ea07311415e089c85e15aa7
#>                                                          prev_hash
#> 1 08681994792b0058b01bb937001350508f1fa4e8b98aa7811099a73005474fe4
#> 2 6751e95b51cfc5da88000956a9f037d0f1a555f2d348354ffd1924d1c6c2298c
#> 3 7acde28f9118768270d512d4fc6152068c2c6d84633d0d4d43def2d955f6767c
#> 4 996f93efd883f75b6777a1808281f7c6c72eb693d26dadf9be3c001c67362e80

# Only signatures
filter_log(log, type = "SIGNATURE")
#>   entry_id                   timestamp      app app_version      user      type
#> 1        4 2026-06-24T10:22:47.760893Z analysis         1.0 ndoh.penn SIGNATURE
#>      action    object           field before after
#> 1 signature ndoh.penn entries_covered   <NA>     3
#>                                      reason
#> 1 Analysis complete and accurate per SAP v2
#>                                                         entry_hash
#> 1 8a19856e905d72064a4f4eaf1e1ddfed6eb08e9b0ea07311415e089c85e15aa7
#>                                                          prev_hash
#> 1 996f93efd883f75b6777a1808281f7c6c72eb693d26dadf9be3c001c67362e80

# Actions and notes by a specific user
filter_log(log, type = c("ACTION", "NOTE"), user = "ndoh.penn")
#>   entry_id                   timestamp      app app_version      user   type
#> 1        1 2026-06-24T10:22:47.759002Z analysis         1.0 ndoh.penn ACTION
#> 2        2 2026-06-24T10:22:47.759625Z analysis         1.0 ndoh.penn   NOTE
#> 3        3 2026-06-24T10:22:47.760246Z analysis         1.0 ndoh.penn ACTION
#>   action      object field before after                                  reason
#> 1    run   primary.R  <NA>   <NA>  <NA>                    Primary model fitted
#> 2   note        <NA>  <NA>   <NA>  <NA> Outlier in subject 042 retained per SAP
#> 3 export results.csv  <NA>   <NA>  <NA>                         Sent to sponsor
#>                                                         entry_hash
#> 1 6751e95b51cfc5da88000956a9f037d0f1a555f2d348354ffd1924d1c6c2298c
#> 2 7acde28f9118768270d512d4fc6152068c2c6d84633d0d4d43def2d955f6767c
#> 3 996f93efd883f75b6777a1808281f7c6c72eb693d26dadf9be3c001c67362e80
#>                                                          prev_hash
#> 1 08681994792b0058b01bb937001350508f1fa4e8b98aa7811099a73005474fe4
#> 2 6751e95b51cfc5da88000956a9f037d0f1a555f2d348354ffd1924d1c6c2298c
#> 3 7acde28f9118768270d512d4fc6152068c2c6d84633d0d4d43def2d955f6767c

# Entries within a date range
filter_log(log, from = "2026-06-01", to = "2026-12-31")
#>   entry_id                   timestamp      app app_version      user      type
#> 1        1 2026-06-24T10:22:47.759002Z analysis         1.0 ndoh.penn    ACTION
#> 2        2 2026-06-24T10:22:47.759625Z analysis         1.0 ndoh.penn      NOTE
#> 3        3 2026-06-24T10:22:47.760246Z analysis         1.0 ndoh.penn    ACTION
#> 4        4 2026-06-24T10:22:47.760893Z analysis         1.0 ndoh.penn SIGNATURE
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
#> 1 6751e95b51cfc5da88000956a9f037d0f1a555f2d348354ffd1924d1c6c2298c
#> 2 7acde28f9118768270d512d4fc6152068c2c6d84633d0d4d43def2d955f6767c
#> 3 996f93efd883f75b6777a1808281f7c6c72eb693d26dadf9be3c001c67362e80
#> 4 8a19856e905d72064a4f4eaf1e1ddfed6eb08e9b0ea07311415e089c85e15aa7
#>                                                          prev_hash
#> 1 08681994792b0058b01bb937001350508f1fa4e8b98aa7811099a73005474fe4
#> 2 6751e95b51cfc5da88000956a9f037d0f1a555f2d348354ffd1924d1c6c2298c
#> 3 7acde28f9118768270d512d4fc6152068c2c6d84633d0d4d43def2d955f6767c
#> 4 996f93efd883f75b6777a1808281f7c6c72eb693d26dadf9be3c001c67362e80

# Works directly on a .rlog file — no live session needed
if (FALSE) { # \dontrun{
filter_log("logs/audit.rlog", type = "SIGNATURE")
} # }
```
