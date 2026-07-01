# regulog

**Tamper-Evident Audit Logging for R**

Every analytical action taken in a consequential R environment should be
documented — who did it, what they did, when, and why. In practice,
almost none of it is.

`regulog` fills that gap. It records every action, change, note, and
decision into a tamper-evident, hash-chained audit trail stored as
newline-delimited JSON. Every entry is attributed to a named user,
time-stamped in UTC, and linked to the previous entry via SHA-256 — so
any modification after the fact, however subtle, is detectable by
[`verify_log()`](https://reprostats.org/regulog/reference/verify_log.md).

Works for regulated pharmaceutical environments (21 CFR Part 11, EU
Annex 11), internal data pipelines, multi-user Shiny applications, and
any context where accountability and traceability matter.

## Installation

``` r

# Install from GitHub
pak::pak("repro-stats/regulog")
```

## Quick start

``` r

library(regulog)

# Initialise a session
log <- regulog_init(
  app     = "primary-analysis",
  version = "1.0.0",
  user    = "analyst",
  path    = "logs/audit.rlog"
)

# Log actions, changes, and decisions
log_action(log,
  action = "data_read",
  object = "adsl.sas7bdat",
  reason = "Reading ADSL for primary efficacy analysis"
)

log_change(log,
  object = "alpha",
  field  = "value",
  before = "0.05",
  after  = "0.025",
  reason = "Updated per protocol amendment 2"
)

log_note(log,
  "Outlier in subject 01-042 retained per SAP section 8.3 —
   discussed with medical monitor 2026-06-20"
)

# Log data reads, scoped to a block — read() is logged automatically
with_log(log, {
  adsl <- read(haven::read_sas, "data/adsl.sas7bdat")
  adae <- read(haven::read_sas, "data/adae.sas7bdat")
})

# Apply an electronic signature
log_signature(log,
  "I certify this analysis is accurate and complete per SAP version 2.0")

# Verify tamper integrity
verify_log(log)
#> regulog: Log intact: 5 entries, chain unbroken

# Query the log
filter_log(log, type = "SIGNATURE")
filter_log(log, action = "data_read", from = "2026-06-01")

# Export for submission
export_audit_trail(log, format = "csv", signed = TRUE,
                   path = "outputs/audit_trail.csv")
```

## Key functions

| Function | Purpose |
|----|----|
| [`regulog_init()`](https://reprostats.org/regulog/reference/regulog_init.md) | Initialise an audit logging session |
| [`log_action()`](https://reprostats.org/regulog/reference/log_action.md) | Log a discrete action |
| [`log_change()`](https://reprostats.org/regulog/reference/log_change.md) | Log a before/after field change |
| [`log_note()`](https://reprostats.org/regulog/reference/log_note.md) | Log a free-text annotation or analytical decision |
| [`log_signature()`](https://reprostats.org/regulog/reference/log_signature.md) | Apply an electronic signature |
| [`rl_read()`](https://reprostats.org/regulog/reference/rl_read.md) | Explicit, logged read of any data source |
| [`with_log()`](https://reprostats.org/regulog/reference/with_log.md) | Scoped convenience: `read()` calls inside the block log automatically |
| [`verify_log()`](https://reprostats.org/regulog/reference/verify_log.md) | Verify SHA-256 hash chain integrity |
| [`filter_log()`](https://reprostats.org/regulog/reference/filter_log.md) | Query entries by type, user, action, or date |
| [`export_audit_trail()`](https://reprostats.org/regulog/reference/export_audit_trail.md) | Export to CSV or JSON, with optional signing |
| [`regulog_shiny_init()`](https://reprostats.org/regulog/reference/regulog_shiny_init.md) | Initialise inside a Shiny server function |
| [`regulog_observer()`](https://reprostats.org/regulog/reference/regulog_observer.md) | Auto-log Shiny reactive input events |

## The hash chain

Each entry hash is SHA-256 of all entry fields plus the prior hash:

    h_0 = SHA256("GENESIS" | app | version | timestamp)
    h_n = SHA256(entry_id | timestamp | app | version | user | type |
                 <payload fields> | h_{n-1})

Any modification to any field in any entry breaks the chain from that
point forward.
[`verify_log()`](https://reprostats.org/regulog/reference/verify_log.md)
recomputes every hash and reports the first broken link — and works
offline from the `.rlog` file, without an active R session.

## Entry types

| Type | Created by | Purpose |
|----|----|----|
| `ACTION` | [`log_action()`](https://reprostats.org/regulog/reference/log_action.md) | Discrete events: reads, runs, approvals |
| `CHANGE` | [`log_change()`](https://reprostats.org/regulog/reference/log_change.md) | Before/after field modifications |
| `NOTE` | [`log_note()`](https://reprostats.org/regulog/reference/log_note.md) | Decisions and free-text rationale |
| `SIGNATURE` | [`log_signature()`](https://reprostats.org/regulog/reference/log_signature.md) | Named, dated, meaningful sign-off |

## Validation

IQ, OQ, and PQ qualification scripts are included for regulated use:

``` r

source(system.file("validation/IQ_regulog.R", package = "regulog"))
source(system.file("validation/OQ_regulog.R", package = "regulog"))
source(system.file("validation/PQ_regulog.R", package = "regulog"))
```

## Regulatory coverage

| Regulation | Clause | Coverage |
|----|----|----|
| 21 CFR Part 11 | §11.10(e) | Hash-chained, time-stamped, user-attributed entries |
| 21 CFR Part 11 | §11.10(b) | [`export_audit_trail()`](https://reprostats.org/regulog/reference/export_audit_trail.md) CSV and JSON |
| 21 CFR Part 11 | §11.100 | [`log_signature()`](https://reprostats.org/regulog/reference/log_signature.md) signer identity |
| 21 CFR Part 11 | §11.200 | Signature components: identity, timestamp, meaning |
| EU Annex 11 | Clause 9 | Date, time, user, action on every entry |
| EU Annex 11 | Clause 11 | [`verify_log()`](https://reprostats.org/regulog/reference/verify_log.md) periodic integrity evaluation |
