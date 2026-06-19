# regulog <img src="man/figures/logo.png" align="right" height="139" alt="" />

> Tamper-Evident Audit Logging for R

<!-- badges: start -->
[![R-CMD-check](https://github.com/repro-stats/regulog/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/repro-stats/regulog/actions/workflows/R-CMD-check.yaml)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

## Overview

`regulog` provides tamper-evident, hash-chained audit logging for R applications.
Every log entry is cryptographically linked to its predecessor — making
insertions, deletions, and modifications detectable. The log format is
plain newline-delimited JSON, readable with any text editor.

Use it anywhere you need to know **who did what, when, and why** — and be
confident the record hasn't been touched since it was written.

`regulog` is a sibling package to [`reproducr`](https://repro-stats.github.io/reproducr/)
in the [repro-stats](https://github.com/repro-stats) organisation, with no
dependency between the two.

---

## Where it fits

| Context | What regulog gives you |
|---|---|
| Multi-user Shiny apps | Per-action attribution tied to authenticated session user |
| Data pipelines | Immutable record of what ran, what changed, and why |
| ML experiment tracking | Who approved a model, what threshold, what changed |
| Internal tooling | Lightweight audit trail without a database |
| Regulated environments | 21 CFR Part 11 / EU Annex 11 coverage via `inst/validation/` |
| Any collaborative R work | A chain anyone can verify hasn't been altered |

---

## How the hash chain works

```
[GENESIS: h₀] ← [entry 1, h₁ = SHA256(fields|h₀)] ← [entry 2, h₂ = SHA256(fields|h₁)] ← …
```

Each entry stores a SHA-256 hash of the previous entry. Changing any field —
including the timestamp or reason — invalidates that hash and breaks all
subsequent links. `verify_log()` detects this in O(n).

## Log entry format

Entries are flat JSON, one per line. No specialist software needed to read them:

```json
{
  "entry_id":    1,
  "timestamp":   "2026-06-18T14:32:01.123456Z",
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

---

## Installation

```r
remotes::install_github("repro-stats/regulog")
```

---

## Core API

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

### Log a field change

```r
log_change(log,
  object = "experiment_7",
  field  = "learning_rate",
  before = "0.01",
  after  = "0.001",
  reason = "Loss diverging at 0.01 — reduced per tuning protocol"
)
```

`reason` is **mandatory with no default**. An empty reason raises an error
immediately — every entry in the log must explain why it was made.

### Verify chain integrity

```r
verify_log(log)
#> regulog: Log intact: 2 entries, chain unbroken

# Also works directly from the file path
verify_log("logs/audit.rlog")
```

### Export

```r
# Simple export
export_audit_trail(log, format = "csv", path = "audit.csv")

# Signed: runs verify_log() and stamps chain_intact + verified_at into every row
export_audit_trail(log,
  format = "csv",
  signed = TRUE,
  from   = "2026-01-01",
  path   = "audit_signed.csv"
)
```

---

## Shiny integration

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

shinyApp(ui = fluidPage(/* ... */), server = server)
```

`regulog_shiny_init()` resolves the user from `session$user` (the authenticated
identity from Shiny Server Pro / Posit Connect) and automatically logs
`session_start` and `session_end` events.

---

## Design principles

| Principle | Implementation |
|---|---|
| No silent failures | Every `log_*` call succeeds or `stop()`s explicitly |
| Reason is mandatory | No default; enforced at the R level, not by convention |
| Human-readable by default | Flat NDJSON; inspectable with a text editor |
| Minimal dependencies | `digest` + `jsonlite` only |
| Append-only on disk | `cat(..., append = TRUE)` — never overwrites |
| Verifiable offline | `verify_log()` works from a file path, no R object needed |

---

## Regulated environments

For use under **21 CFR Part 11** or **EU Annex 11**, `regulog` ships with
IQ/OQ/PQ qualification scripts and a Requirements Traceability Matrix in
`inst/validation/`:

```r
source(system.file("validation/IQ_regulog.R", package = "regulog"))
source(system.file("validation/OQ_regulog.R", package = "regulog"))
source(system.file("validation/PQ_regulog.R", package = "regulog"))
```

The RTM maps every regulatory clause to the corresponding function, test ID,
and qualification script:

```r
rtm <- read.csv(system.file("validation/RTM_regulog.csv", package = "regulog"))
```

---

## Roadmap

**v0.1** (current)
- [x] Hash-chained log infrastructure
- [x] `regulog_init()`, `log_action()`, `log_change()`
- [x] `verify_log()` — in-memory and from file path
- [x] `export_audit_trail()` — CSV and JSON, signed mode
- [x] `inst/validation/` — IQ/OQ/PQ scripts + RTM

**v0.2**
- [ ] Shiny integration (`regulog_shiny_init()`)
- [ ] SQLite backend option
- [ ] `pkgdown` site

**v0.3**
- [ ] Electronic signatures (name + password confirmation)
- [ ] `regulog.validation` as standalone companion package

---

## repro-stats ecosystem

| Package | Role |
|---|---|
| [`reproducr`](https://github.com/repro-stats/reproducr) | Behavioural reproducibility auditing for R projects |
| `regulog` | Tamper-evident audit logging |
| `lineager` *(planned)* | Row-level data provenance |
| `estimandr` *(planned)* | ICH E9(R1) estimand framework |
