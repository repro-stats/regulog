# regulog <a href="https://repro-stats.github.io/regulog/"><img src="man/figures/logo.svg" align="right" height="130" alt="regulog website" /></a>

> Tamper-Evident Audit Logging for R

<!-- badges: start -->
[![R-CMD-check](https://github.com/repro-stats/regulog/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/repro-stats/regulog/actions/workflows/R-CMD-check.yaml)
[![CRAN status](https://www.r-pkg.org/badges/version/regulog)](https://CRAN.R-project.org/package=regulog)
[![Codecov test coverage](https://codecov.io/gh/repro-stats/regulog/graph/badge.svg)](https://app.codecov.io/gh/repro-stats/regulog)

<!-- badges: end -->

`regulog` provides tamper-evident, hash-chained audit logging for R applications. Every log entry is cryptographically linked to its predecessor, making insertions, deletions, and modifications detectable. Logs are written as plain newline-delimited JSON — readable with any text editor, no special tooling required.

Use it anywhere you need a reliable record of **who did what, when, and why**.

## Installation

```r
# Development version
remotes::install_github("repro-stats/regulog")
```

## How it works

Each entry stores a SHA-256 hash of the previous entry:

```
[GENESIS: h₀] ← [entry 1, h₁ = SHA256(fields|h₀)] ← [entry 2, h₂ = SHA256(fields|h₁)] ← …
```

Altering any field — including the timestamp or reason — breaks the hash chain. `verify_log()` detects this across all entries in O(n). Entries are written flat, one JSON object per line:

```json
{
  "entry_id":    1,
  "timestamp":   "2026-06-19T09:00:21.398739Z",
  "app":         "my-app",
  "app_version": "1.0.0",
  "user":        "jsmith",
  "type":        "ACTION",
  "action":      "approved",
  "object":      "model_v3",
  "reason":      "Validation metrics passed agreed threshold",
  "prev_hash":   "e3b0c44298fc1c149afb...",
  "entry_hash":  "a87ff679a2f3e71d9181..."
}
```

## Usage

### Initialise a session

```r
library(regulog)

log <- regulog_init(
  app     = "my-app",
  version = "1.0.0",
  user    = "jsmith",
  path    = "logs/audit.rlog"   # omit for in-memory only
)
```

### Log an action

```r
log_action(log,
  action = "approved",
  object = "model_v3",
  reason = "Validation metrics passed agreed threshold"
)
```

### Log a data change

```r
log_change(log,
  object = "experiment_7",
  field  = "learning_rate",
  before = "0.01",
  after  = "0.001",
  reason = "Loss diverging at 0.01 — reduced per tuning protocol"
)
```

`reason` is mandatory with no default. Every entry must document why it was made.

### Verify chain integrity

```r
verify_log(log)
#> regulog: Log intact: 2 entries, chain unbroken

# Verify directly from the log file — no R object required
verify_log("logs/audit.rlog")
```

### Export

```r
# Export to CSV
export_audit_trail(log, format = "csv", path = "audit.csv")

# Signed export: verifies the chain and stamps the result on every row
export_audit_trail(log,
  format = "csv",
  signed = TRUE,
  path   = "audit_signed.csv"
)
```

## Shiny integration

`regulog` integrates directly with Shiny. `regulog_shiny_init()` resolves the authenticated user from `session$user` and automatically records session start and end events.

```r
library(shiny)
library(regulog)

server <- function(input, output, session) {

  log <- regulog_shiny_init(
    session = session,
    app     = "my-app",
    version = "1.0.0",
    path    = "logs/audit.rlog"
  )

  observeEvent(input$approve, {
    log_action(log,
      action = "approved",
      object = input$item_id,
      reason = input$reason
    )
  })
}
```

## Regulated environments

`regulog` includes built-in support for validated computerised systems operating
under 21 CFR Part 11 or EU Annex 11. Installation, Operational, and Performance
Qualification (IQ/OQ/PQ) scripts and a Requirements Traceability Matrix are
included and can be run to formally qualify `regulog` for use in a regulated
environment:

```r
source(system.file("validation/IQ_regulog.R", package = "regulog"))
source(system.file("validation/OQ_regulog.R", package = "regulog"))
source(system.file("validation/PQ_regulog.R", package = "regulog"))

# Requirements Traceability Matrix
read.csv(system.file("validation/RTM_regulog.csv", package = "regulog"))
```

## Design principles

- **No silent failures** — every `log_*` call succeeds or errors explicitly
- **Reason is mandatory** — no default; enforced at the R level, not by convention
- **Human-readable** — flat NDJSON; inspectable with a text editor
- **Minimal dependencies** — `digest` and `jsonlite` only
- **Append-only** — log files are never overwritten, only extended
- **Verifiable offline** — `verify_log()` works from a file path with no R object needed
