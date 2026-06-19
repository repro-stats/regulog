# Getting started with regulog

## Overview

`regulog` provides tamper-evident, hash-chained audit logging for R
applications. This vignette covers the core API. For Shiny integration,
see
[`vignette("shiny-integration")`](https://repro-stats.github.io/regulog/articles/shiny-integration.md).

## Initialise a session

Every audit log starts with
[`regulog_init()`](https://repro-stats.github.io/regulog/reference/regulog_init.md).
You must supply an application name and user identity. Optionally
provide a `path` to persist entries to disk as a newline-delimited JSON
file (`.rlog`).

``` r

log <- regulog_init(
  app     = "clinical-review-tool",
  version = "1.2.0",
  user    = "jsmith"
  # path  = "logs/audit.rlog"  # omit for in-memory only
)

log
#> <regulog>
#>   App:     clinical-review-tool v1.2.0
#>   User:    jsmith
#>   Entries: 0
#>   Path:    (in-memory only)
```

Without a `path`, the log is in-memory only — useful for development and
testing, but not appropriate for production regulated deployments.

## Logging actions

Use
[`log_action()`](https://repro-stats.github.io/regulog/reference/log_action.md)
for discrete user actions: approvals, rejections, exports, sign-offs.

``` r

log_action(log,
  action = "approved",
  object = "dataset_v3.csv",
  reason = "QC review complete — no anomalies found"
)
#> regulog: logged action 'approved' on 'dataset_v3.csv'

log_action(log,
  action = "exported",
  object = "dataset_v3.csv",
  reason = "Sent to statistical analysis team per SAP section 4.1"
)
#> regulog: logged action 'exported' on 'dataset_v3.csv'
```

`reason` is **mandatory with no default**. An empty or blank reason
raises an error immediately — every entry in the log must document why
it was made.

``` r

# This will error:
log_action(log, action = "approved", object = "file.csv", reason = "")
#> Error in `.assert_reason()`:
#> ! A `reason` is required for every logged action or change.
#>   Every entry in the audit trail must document why it was made.
#>   Provide a justification, e.g.: reason = "Validation metrics passed threshold".
```

## Logging data changes

Use
[`log_change()`](https://repro-stats.github.io/regulog/reference/log_change.md)
when a field value is modified. Both the prior and new value are
captured, so you have a complete history of what it was, what it became,
and why.

``` r

log_change(log,
  object = "patient_10472",
  field  = "dob",
  before = "1985-03-01",
  after  = "1985-03-11",
  reason = "Transcription error — corrected per source document CRF page 14"
)
#> regulog: logged change to patient_10472$dob
```

## Verifying chain integrity

[`verify_log()`](https://repro-stats.github.io/regulog/reference/verify_log.md)
recomputes every entry hash and checks that chain links are unbroken.
Run it at any time, on a schedule, or as part of a handoff.

``` r

verify_log(log)
#> regulog: Log intact: 3 entries, chain unbroken
```

It also works directly from a `.rlog` file path — no R object needed:

``` r

verify_log("logs/audit.rlog")
```

### What tampering looks like

``` r

# Simulate tampering — modifying an entry field after the fact
log$entries[[1L]]$action <- "ALTERED"
verify_log(log)
#> Warning: regulog: Log FAILED verification — 1 error(s). First broken entry: #1
#> Entry #1: entry_hash mismatch — content may have been modified
```

## Exporting for regulatory submission

[`export_audit_trail()`](https://repro-stats.github.io/regulog/reference/export_audit_trail.md)
serialises the log to CSV or JSON. Use `signed = TRUE` for regulatory
submissions — this runs
[`verify_log()`](https://repro-stats.github.io/regulog/reference/verify_log.md)
and stamps `chain_intact` and `verified_at` into every row.

``` r

# Reset to a clean log for the export example
log2 <- regulog_init(app = "clinical-review-tool", version = "1.2.0",
                      user = "jsmith")
log_action(log2, action = "approved", object = "report_final.pdf",
           reason = "All review comments resolved")
#> regulog: logged action 'approved' on 'report_final.pdf'
log_change(log2, object = "patient_99", field = "visit_date",
           before = "2026-04-01", after = "2026-04-11",
           reason = "Date transposition error per visit log")
#> regulog: logged change to patient_99$visit_date

df <- export_audit_trail(log2, format = "csv", signed = TRUE)
df
#>   entry_id                   timestamp                  app app_version   user
#> 1        1 2026-06-19T15:56:16.297110Z clinical-review-tool       1.2.0 jsmith
#> 2        2 2026-06-19T15:56:16.298116Z clinical-review-tool       1.2.0 jsmith
#>     type   action           object      field     before      after
#> 1 ACTION approved report_final.pdf       <NA>       <NA>       <NA>
#> 2 CHANGE     <NA>       patient_99 visit_date 2026-04-01 2026-04-11
#>                                   reason
#> 1           All review comments resolved
#> 2 Date transposition error per visit log
#>                                                         entry_hash
#> 1 e2326e9739f5240483e1621b86a6e476a9003878602ea13a11eaf698cd3ba89c
#> 2 5ce6c8cfc528a8bbf981e32df503f3e7e92fb470127c67afd130f3b2b2606d36
#>                                                          prev_hash chain_intact
#> 1 b833e0b49fd5ec229f6a3ec776fba800f0761fe0ebab0cf8ad466c0d886cfb32         TRUE
#> 2 e2326e9739f5240483e1621b86a6e476a9003878602ea13a11eaf698cd3ba89c         TRUE
#>                   verified_at
#> 1 2026-06-19T15:56:16.299422Z
#> 2 2026-06-19T15:56:16.299422Z
```

### Writing to disk

``` r

export_audit_trail(log2,
  format = "csv",
  from   = "2026-01-01",
  signed = TRUE,
  path   = "audit_export.csv"
)

# JSON format — useful for archival and system integration
export_audit_trail(log2,
  format = "json",
  signed = TRUE,
  path   = "audit_export.json"
)
```

## The .rlog file format

Entries are written as newline-delimited JSON (one JSON object per
line). The format is deliberately human-readable — a regulator can
inspect an audit log with any text editor:

    {"entry_id":1,"timestamp":"2026-06-18T14:32:01.123456Z","app":"clinical-review-tool","app_version":"1.2.0","user":"jsmith","type":"ACTION","action":"approved","object":"dataset_v3.csv","reason":"QC review complete","prev_hash":"e3b0c4...","entry_hash":"a87ff6..."}

## Validation

`regulog` ships with IQ/OQ/PQ qualification scripts in
`inst/validation/`. Run them in sequence to qualify the package for use
in a validated computerised system:

``` r

source(system.file("validation/IQ_regulog.R", package = "regulog"))
source(system.file("validation/OQ_regulog.R", package = "regulog"))
source(system.file("validation/PQ_regulog.R", package = "regulog"))
```

The Requirements Traceability Matrix (RTM) is at:

``` r

rtm_path <- system.file("validation/RTM_regulog.csv", package = "regulog")
read.csv(rtm_path)
```
