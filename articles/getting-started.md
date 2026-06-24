# Getting started with regulog

R analyses leave no audit trail by default. `regulog` adds one — a
tamper-evident, hash-chained record of every action, change, decision,
and signature. Every entry is attributed to a named user, time-stamped
in UTC, and cryptographically linked to the previous entry so that any
modification after the fact is detectable.

This vignette walks through the complete API from session initialisation
to regulatory export.

## 1. Initialise a session

[`regulog_init()`](https://repro-stats.github.io/regulog/reference/regulog_init.md)
creates the session object. Every subsequent log call is attached to
this object.

| Argument    | Required | Purpose                                       |
|-------------|----------|-----------------------------------------------|
| `app`       | Yes      | Application or system name                    |
| `version`   | No       | Application version (default: `"unknown"`)    |
| `user`      | No       | Acting user (default: `Sys.info()[["user"]]`) |
| `path`      | No       | File path for persistent `.rlog` storage      |
| `hash_algo` | No       | Hashing algorithm (default: `"sha256"`)       |

``` r

log <- regulog_init(
  app     = "primary-analysis",
  version = "1.0.0",
  user    = "ndoh.penn"
  # Provide path = "logs/audit.rlog" in production for persistent storage
)

log
#> <regulog>
#>   App:     primary-analysis v1.0.0
#>   User:    ndoh.penn
#>   Entries: 0
#>   Path:    (in-memory only)
```

When `path` is omitted, the log lives in memory only — suitable for
development and testing. In production, always supply a `path` so
entries survive the R session.

The genesis record is written immediately on
[`regulog_init()`](https://repro-stats.github.io/regulog/reference/regulog_init.md).
Its SHA-256 hash anchors the entire chain — see
[`vignette("hash-chain")`](https://repro-stats.github.io/regulog/articles/hash-chain.md)
for how the cryptographic linking works.

## 2. Log actions

[`log_action()`](https://repro-stats.github.io/regulog/reference/log_action.md)
records a discrete event. The `reason` argument is **mandatory with no
default** — undocumented entries are rejected.

``` r

log_action(log,
  action = "data_read",
  object = "adsl.sas7bdat",
  reason = "Reading subject-level dataset for primary efficacy analysis"
)
#> regulog: logged action 'data_read' on 'adsl.sas7bdat'
```

The `action` and `object` fields accept any strings — choose a
controlled vocabulary that suits your organisation. Common patterns:

``` r

# Analytical steps
log_action(log,
  action = "model_fit",
  object = "primary_ANCOVA",
  reason = "Fitting ANCOVA: CHG ~ TRT01P + BASE + SITEID per SAP section 6.1"
)
#> regulog: logged action 'model_fit' on 'primary_ANCOVA'

# Data exports
log_action(log,
  action = "export",
  object = "Table14_1.rtf",
  reason = "Primary efficacy table exported for clinical study report"
)
#> regulog: logged action 'export' on 'Table14_1.rtf'

# Review and approval events
log_action(log,
  action = "approved",
  object = "primary_results_v3",
  reason = "QC review complete — all outputs match SAP-specified formats"
)
#> regulog: logged action 'approved' on 'primary_results_v3'

# User can override the session user for a single entry
log_action(log,
  action = "co_reviewed",
  object = "primary_results_v3",
  reason = "Independent statistical review complete",
  user   = "second.reviewer"
)
#> regulog: logged action 'co_reviewed' on 'primary_results_v3'
```

## 3. Log field changes

[`log_change()`](https://repro-stats.github.io/regulog/reference/log_change.md)
captures a before/after modification — the primary mechanism for
satisfying 21 CFR Part 11 §11.10(e) change documentation.

``` r

log_change(log,
  object = "alpha",
  field  = "value",
  before = "0.05",
  after  = "0.025",
  reason = "Significance level updated per protocol amendment 2 (2026-05-01)"
)
#> regulog: logged change to alpha$value
```

The `before` and `after` arguments are coerced to character, so they
accept any R value:

``` r

# Data correction
log_change(log,
  object = "subject_01042",
  field  = "ae_onset_date",
  before = "2026-03-01",
  after  = "2026-03-11",
  reason = "Transcription error — corrected per source CRF page 47, query Q-0192"
)
#> regulog: logged change to subject_01042$ae_onset_date

# Configuration update
log_change(log,
  object = "model_config",
  field  = "covariance_structure",
  before = "compound_symmetry",
  after  = "unstructured",
  reason = "Unstructured covariance pre-specified in SAP section 6.1.2"
)
#> regulog: logged change to model_config$covariance_structure

# Population definition change
log_change(log,
  object = "analysis_population",
  field  = "SAFFL_definition",
  before = "RANDFL = 'Y'",
  after  = "RANDFL = 'Y' AND EXOCCUR = 'Y'",
  reason = "Protocol amendment 3: safety population requires confirmed dosing"
)
#> regulog: logged change to analysis_population$SAFFL_definition
```

## 4. Log notes and decisions

[`log_note()`](https://repro-stats.github.io/regulog/reference/log_note.md)
captures free-text annotations — any rationale, observation, or decision
that does not fit a discrete action verb or a before/after field change.
Common uses:

``` r

# Outlier decision
log_note(log,
  "Outlier identified for subject 01-042 at Week 16 (AVAL = 98.4,
   upper fence = 62.1). Discussed with medical monitor on 2026-06-20.
   Retained in primary analysis per SAP section 8.3 — no protocol
   deviation recorded. Sensitivity analysis without outlier pre-specified
   in SAP section 10.4."
)
#> regulog: note logged

# Protocol deviation
log_note(log,
  "Subject 01-007: visit window deviation at Week 8 (visited Day 61,
   window Day 50-58). Classified as minor deviation per deviation
   assessment log entry DEV-0031. Subject retained in ITT population."
)
#> regulog: note logged

# Query resolved
log_note(log,
  "Data query Q-0047 resolved 2026-06-15: lab value for subject 01-019
   at Screening confirmed as 4.2 mmol/L per site laboratory report.
   Original value 42.0 was a decimal error."
)
#> regulog: note logged

# Analysis assumption documented
log_note(log,
  "Missing baseline value for subject 01-033: LOCF imputation applied
   per SAP section 7.2 — previous non-missing value (Visit 1) used.
   Imputed value: 24.6."
)
#> regulog: note logged
```

## 5. Automatic data I/O logging

Manually calling
[`log_action()`](https://repro-stats.github.io/regulog/reference/log_action.md)
for every file read is error-prone.
[`with_log()`](https://repro-stats.github.io/regulog/reference/with_log.md)
patches common read functions automatically for the duration of a code
block, then restores them on exit — even if the block errors.

``` r

with_log(log, {
  adsl <- haven::read_sas("data/adsl.sas7bdat")   # logged automatically
  adae <- haven::read_sas("data/adae.sas7bdat")   # logged automatically
  adlb <- haven::read_sas("data/adlb.sas7bdat")   # logged automatically
  params <- readr::read_csv("config/parameters.csv") # logged automatically
})
```

Functions patched automatically when the package is loaded:
[`haven::read_sas`](https://haven.tidyverse.org/reference/read_sas.html),
[`haven::read_xpt`](https://haven.tidyverse.org/reference/read_xpt.html),
[`readr::read_csv`](https://readr.tidyverse.org/reference/read_delim.html),
`data.table::fread`,
[`utils::read.csv`](https://rdrr.io/r/utils/read.table.html),
[`utils::read.table`](https://rdrr.io/r/utils/read.table.html).

Each auto-logged entry captures the file path, row count, and column
count. For example:

    action: data_read
    object: data/adsl.sas7bdat
    reason: haven::read_sas("data/adsl.sas7bdat") — 298 rows, 47 cols

For persistent hooks across multiple steps, use
[`log_hooks_enable()`](https://repro-stats.github.io/regulog/reference/log_hooks_enable.md)
and
[`log_hooks_disable()`](https://repro-stats.github.io/regulog/reference/log_hooks_disable.md):

``` r

log_hooks_enable(log)

adsl <- haven::read_sas("data/adsl.sas7bdat")
adae <- haven::read_sas("data/adae.sas7bdat")
# ... more reads ...

log_hooks_disable()  # always call this; or use with_log() for safety
```

[`with_log()`](https://repro-stats.github.io/regulog/reference/with_log.md)
is preferred over the manual pair because it guarantees
[`log_hooks_disable()`](https://repro-stats.github.io/regulog/reference/log_hooks_disable.md)
is called via [`on.exit()`](https://rdrr.io/r/base/on.exit.html) even if
an error occurs.

## 6. Electronic signatures

[`log_signature()`](https://repro-stats.github.io/regulog/reference/log_signature.md)
records a named, dated, meaningful sign-off. Two things happen
automatically — no user input required:

- **Signer identity** is resolved from the session user set at
  [`regulog_init()`](https://repro-stats.github.io/regulog/reference/regulog_init.md)
  — it cannot be overridden at signing time
- **Entries covered** is captured as the count of prior entries in the
  session at the moment of signing

``` r

log_signature(log,
  "I certify that this primary analysis is accurate and complete,
   conducted in accordance with SAP version 2.0 dated 2026-05-01"
)
#> regulog: signature applied by 'ndoh.penn' covering 13 entries
```

Multiple signatures are supported — for example, a lead statistician and
an independent reviewer:

``` r

log_signature(log,
  "Statistical analysis complete and accurate per SAP v2.0.
   All deviations documented."
)

# Second reviewer — create a new log or log against the same path with
# a different session user
log2 <- regulog_init(app = "primary-analysis", version = "1.0.0",
                      user = "second.reviewer",
                      path = "logs/trial001_audit.rlog")

log_signature(log2,
  "Independent QC review complete. Results independently verified."
)
```

## 7. Verify chain integrity

[`verify_log()`](https://repro-stats.github.io/regulog/reference/verify_log.md)
recomputes every entry hash and confirms each `prev_hash` links
correctly to its predecessor. Works on both a live `regulog` object and
a `.rlog` file path.

``` r

verify_log(log)
#> regulog: Log intact: 14 entries, chain unbroken
```

The return value carries structured results:

``` r

result <- verify_log(log, verbose = FALSE)
cat("Intact:        ", result$intact,       "\n")
#> Intact:         TRUE
cat("Entries checked:", result$n_entries,    "\n")
#> Entries checked: 14
cat("First broken:  ", result$first_broken,  "\n")
#> First broken:   NA
```

Tampering is reliably detected:

``` r

saved <- log$entries[[2L]]$reason
log$entries[[2L]]$reason <- "ALTERED REASON"

tamper_result <- suppressWarnings(verify_log(log, verbose = FALSE))
cat("Intact after tamper:", tamper_result$intact,        "\n")
#> Intact after tamper: FALSE
cat("First broken entry: ", tamper_result$first_broken,  "\n")
#> First broken entry:  2

log$entries[[2L]]$reason <- saved  # restore
```

Verification from a file path requires no live session:

``` r

verify_log("logs/trial001_audit.rlog")
```

## 8. Query the log

[`filter_log()`](https://repro-stats.github.io/regulog/reference/filter_log.md)
returns log entries as a `data.frame`. All arguments are optional —
omitting all returns every entry.

``` r

all_entries <- filter_log(log)
all_entries[, c("entry_id", "type", "action", "user", "reason")]
#>    entry_id      type      action            user
#> 1         1    ACTION   data_read       ndoh.penn
#> 2         2    ACTION   model_fit       ndoh.penn
#> 3         3    ACTION      export       ndoh.penn
#> 4         4    ACTION    approved       ndoh.penn
#> 5         5    ACTION co_reviewed second.reviewer
#> 6         6    CHANGE        <NA>       ndoh.penn
#> 7         7    CHANGE        <NA>       ndoh.penn
#> 8         8    CHANGE        <NA>       ndoh.penn
#> 9         9    CHANGE        <NA>       ndoh.penn
#> 10       10      NOTE        note       ndoh.penn
#> 11       11      NOTE        note       ndoh.penn
#> 12       12      NOTE        note       ndoh.penn
#> 13       13      NOTE        note       ndoh.penn
#> 14       14 SIGNATURE   signature       ndoh.penn
#>                                                                                                                                                                                                                                                                                                          reason
#> 1                                                                                                                                                                                                                                                   Reading subject-level dataset for primary efficacy analysis
#> 2                                                                                                                                                                                                                                              Fitting ANCOVA: CHG ~ TRT01P + BASE + SITEID per SAP section 6.1
#> 3                                                                                                                                                                                                                                                     Primary efficacy table exported for clinical study report
#> 4                                                                                                                                                                                                                                                  QC review complete — all outputs match SAP-specified formats
#> 5                                                                                                                                                                                                                                                                       Independent statistical review complete
#> 6                                                                                                                                                                                                                                              Significance level updated per protocol amendment 2 (2026-05-01)
#> 7                                                                                                                                                                                                                                          Transcription error — corrected per source CRF page 47, query Q-0192
#> 8                                                                                                                                                                                                                                                    Unstructured covariance pre-specified in SAP section 6.1.2
#> 9                                                                                                                                                                                                                                             Protocol amendment 3: safety population requires confirmed dosing
#> 10 Outlier identified for subject 01-042 at Week 16 (AVAL = 98.4,\n   upper fence = 62.1). Discussed with medical monitor on 2026-06-20.\n   Retained in primary analysis per SAP section 8.3 — no protocol\n   deviation recorded. Sensitivity analysis without outlier pre-specified\n   in SAP section 10.4.
#> 11                                                                                                  Subject 01-007: visit window deviation at Week 8 (visited Day 61,\n   window Day 50-58). Classified as minor deviation per deviation\n   assessment log entry DEV-0031. Subject retained in ITT population.
#> 12                                                                                                                        Data query Q-0047 resolved 2026-06-15: lab value for subject 01-019\n   at Screening confirmed as 4.2 mmol/L per site laboratory report.\n   Original value 42.0 was a decimal error.
#> 13                                                                                                                                             Missing baseline value for subject 01-033: LOCF imputation applied\n   per SAP section 7.2 — previous non-missing value (Visit 1) used.\n   Imputed value: 24.6.
#> 14                                                                                                                                                                             I certify that this primary analysis is accurate and complete,\n   conducted in accordance with SAP version 2.0 dated 2026-05-01
```

Filter by entry type:

``` r

filter_log(log, type = "SIGNATURE")[, c("type", "user", "reason", "after")]
#>        type      user
#> 1 SIGNATURE ndoh.penn
#>                                                                                                                             reason
#> 1 I certify that this primary analysis is accurate and complete,\n   conducted in accordance with SAP version 2.0 dated 2026-05-01
#>   after
#> 1    13
```

Filter by action value:

``` r

filter_log(log, action = "approved")[, c("action", "object", "reason")]
#>     action             object
#> 1 approved primary_results_v3
#>                                                         reason
#> 1 QC review complete — all outputs match SAP-specified formats
```

Filter by user:

``` r

filter_log(log, user = "ndoh.penn")[, c("type", "action", "object")]
#>         type    action              object
#> 1     ACTION data_read       adsl.sas7bdat
#> 2     ACTION model_fit      primary_ANCOVA
#> 3     ACTION    export       Table14_1.rtf
#> 4     ACTION  approved  primary_results_v3
#> 5     CHANGE      <NA>               alpha
#> 6     CHANGE      <NA>       subject_01042
#> 7     CHANGE      <NA>        model_config
#> 8     CHANGE      <NA> analysis_population
#> 9       NOTE      note                <NA>
#> 10      NOTE      note                <NA>
#> 11      NOTE      note                <NA>
#> 12      NOTE      note                <NA>
#> 13 SIGNATURE signature           ndoh.penn
```

Filter by date range — useful when querying a long-running shared log:

``` r

# Entries from today onwards
filter_log(log, from = format(Sys.Date(), "%Y-%m-%d"))[, c("type", "action")]
#>         type      action
#> 1     ACTION   data_read
#> 2     ACTION   model_fit
#> 3     ACTION      export
#> 4     ACTION    approved
#> 5     ACTION co_reviewed
#> 6     CHANGE        <NA>
#> 7     CHANGE        <NA>
#> 8     CHANGE        <NA>
#> 9     CHANGE        <NA>
#> 10      NOTE        note
#> 11      NOTE        note
#> 12      NOTE        note
#> 13      NOTE        note
#> 14 SIGNATURE   signature

# Entries before a cutoff (empty for new log)
filter_log(log, to = "2025-12-31")
#>  [1] entry_id    timestamp   app         app_version user        type       
#>  [7] action      object      field       before      after       reason     
#> [13] entry_hash  prev_hash  
#> <0 rows> (or 0-length row.names)
```

Combine filters:

``` r

filter_log(log,
  type   = c("ACTION", "NOTE"),
  user   = "ndoh.penn",
  from   = "2026-01-01"
)[, c("type", "action", "reason")]
#>     type    action
#> 1 ACTION data_read
#> 2 ACTION model_fit
#> 3 ACTION    export
#> 4 ACTION  approved
#> 5   NOTE      note
#> 6   NOTE      note
#> 7   NOTE      note
#> 8   NOTE      note
#>                                                                                                                                                                                                                                                                                                         reason
#> 1                                                                                                                                                                                                                                                  Reading subject-level dataset for primary efficacy analysis
#> 2                                                                                                                                                                                                                                             Fitting ANCOVA: CHG ~ TRT01P + BASE + SITEID per SAP section 6.1
#> 3                                                                                                                                                                                                                                                    Primary efficacy table exported for clinical study report
#> 4                                                                                                                                                                                                                                                 QC review complete — all outputs match SAP-specified formats
#> 5 Outlier identified for subject 01-042 at Week 16 (AVAL = 98.4,\n   upper fence = 62.1). Discussed with medical monitor on 2026-06-20.\n   Retained in primary analysis per SAP section 8.3 — no protocol\n   deviation recorded. Sensitivity analysis without outlier pre-specified\n   in SAP section 10.4.
#> 6                                                                                                  Subject 01-007: visit window deviation at Week 8 (visited Day 61,\n   window Day 50-58). Classified as minor deviation per deviation\n   assessment log entry DEV-0031. Subject retained in ITT population.
#> 7                                                                                                                        Data query Q-0047 resolved 2026-06-15: lab value for subject 01-019\n   at Screening confirmed as 4.2 mmol/L per site laboratory report.\n   Original value 42.0 was a decimal error.
#> 8                                                                                                                                             Missing baseline value for subject 01-033: LOCF imputation applied\n   per SAP section 7.2 — previous non-missing value (Visit 1) used.\n   Imputed value: 24.6.
```

[`filter_log()`](https://repro-stats.github.io/regulog/reference/filter_log.md)
also accepts a `.rlog` file path directly — no live session or `regulog`
object required:

``` r

filter_log("logs/trial001_audit.rlog",
  type = "SIGNATURE",
  user = "ndoh.penn"
)
```

## 9. Convert to data frame

[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) converts
all non-genesis entries to a flat data frame — same column layout as
`export_audit_trail(format = "csv")`:

``` r

df <- as.data.frame(log)
names(df)
#>  [1] "entry_id"    "timestamp"   "app"         "app_version" "user"       
#>  [6] "type"        "action"      "object"      "field"       "before"     
#> [11] "after"       "reason"      "entry_hash"  "prev_hash"
nrow(df)
#> [1] 14
```

## 10. Export the audit trail

[`export_audit_trail()`](https://repro-stats.github.io/regulog/reference/export_audit_trail.md)
serialises the log to CSV or JSON. Use `signed = TRUE` to run
verification and stamp `chain_intact` and `verified_at` on every row.

``` r

df_export <- export_audit_trail(log, format = "csv", signed = TRUE)
df_export[, c("entry_id", "type", "action", "user", "chain_intact", "verified_at")]
#>    entry_id      type      action            user chain_intact
#> 1         1    ACTION   data_read       ndoh.penn         TRUE
#> 2         2    ACTION   model_fit       ndoh.penn         TRUE
#> 3         3    ACTION      export       ndoh.penn         TRUE
#> 4         4    ACTION    approved       ndoh.penn         TRUE
#> 5         5    ACTION co_reviewed second.reviewer         TRUE
#> 6         6    CHANGE        <NA>       ndoh.penn         TRUE
#> 7         7    CHANGE        <NA>       ndoh.penn         TRUE
#> 8         8    CHANGE        <NA>       ndoh.penn         TRUE
#> 9         9    CHANGE        <NA>       ndoh.penn         TRUE
#> 10       10      NOTE        note       ndoh.penn         TRUE
#> 11       11      NOTE        note       ndoh.penn         TRUE
#> 12       12      NOTE        note       ndoh.penn         TRUE
#> 13       13      NOTE        note       ndoh.penn         TRUE
#> 14       14 SIGNATURE   signature       ndoh.penn         TRUE
#>                    verified_at
#> 1  2026-06-24T10:22:52.526015Z
#> 2  2026-06-24T10:22:52.526015Z
#> 3  2026-06-24T10:22:52.526015Z
#> 4  2026-06-24T10:22:52.526015Z
#> 5  2026-06-24T10:22:52.526015Z
#> 6  2026-06-24T10:22:52.526015Z
#> 7  2026-06-24T10:22:52.526015Z
#> 8  2026-06-24T10:22:52.526015Z
#> 9  2026-06-24T10:22:52.526015Z
#> 10 2026-06-24T10:22:52.526015Z
#> 11 2026-06-24T10:22:52.526015Z
#> 12 2026-06-24T10:22:52.526015Z
#> 13 2026-06-24T10:22:52.526015Z
#> 14 2026-06-24T10:22:52.526015Z
```

``` r

# JSON envelope with metadata header
export_audit_trail(log,
  format = "json",
  signed = TRUE,
  path   = "outputs/audit_trail.json"
)

# CSV for regulatory submission or spreadsheet review
export_audit_trail(log,
  format = "csv",
  signed = TRUE,
  path   = "outputs/audit_trail_TRIAL001_PRIMARY.csv"
)
```

Date filtering is available on export too:

``` r

# Only entries from a specific analysis phase
export_audit_trail(log,
  format = "csv",
  from   = "2026-06-01",
  to     = "2026-06-30",
  signed = TRUE,
  path   = "outputs/audit_june2026.csv"
)
```

## 11. Entry type reference

| Type | Created by | Mandatory fields | Regulatory purpose |
|----|----|----|----|
| `ACTION` | [`log_action()`](https://repro-stats.github.io/regulog/reference/log_action.md) | `action`, `object`, `reason` | Discrete events |
| `CHANGE` | [`log_change()`](https://repro-stats.github.io/regulog/reference/log_change.md) | `object`, `field`, `before`, `after`, `reason` | Field modifications |
| `NOTE` | [`log_note()`](https://repro-stats.github.io/regulog/reference/log_note.md) | `text` | Decisions and rationale |
| `SIGNATURE` | [`log_signature()`](https://repro-stats.github.io/regulog/reference/log_signature.md) | `meaning` | Sign-off |

## 12. Validation (regulated environments)

IQ, OQ, and PQ qualification scripts are included with the package:

``` r

source(system.file("validation/IQ_regulog.R", package = "regulog"))
source(system.file("validation/OQ_regulog.R", package = "regulog"))
source(system.file("validation/PQ_regulog.R", package = "regulog"))
```

See also
[`vignette("hash-chain")`](https://repro-stats.github.io/regulog/articles/hash-chain.md)
for a detailed explanation of the tamper detection mechanism.
