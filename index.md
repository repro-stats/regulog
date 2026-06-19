# regulog

> Tamper-Evident Audit Logging for R

`regulog` provides tamper-evident, hash-chained audit logging for R
applications. Every log entry is cryptographically linked to its
predecessor — making insertions, deletions, and modifications
detectable. The log format is plain newline-delimited JSON, readable
with any text editor.

Use it anywhere you need to know **who did what, when, and why** — and
be confident the record has not been altered since it was written.

## Installation

``` r

# Development version
remotes::install_github("repro-stats/regulog")
```

## How it works

Each entry stores a SHA-256 hash of the previous entry:

    [GENESIS: h₀] ← [entry 1, h₁ = SHA256(fields|h₀)] ← [entry 2, h₂ = SHA256(fields|h₁)] ← …

Changing any field — including the timestamp or reason — invalidates the
hash and all subsequent links.
[`verify_log()`](https://repro-stats.github.io/regulog/reference/verify_log.md)
checks this in O(n).

Entries are written as flat JSON, one per line:

``` json
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

``` r

library(regulog)

log <- regulog_init(
  app     = "my-app",
  version = "1.0.0",
  user    = "jsmith",
  path    = "logs/audit.rlog"   # omit for in-memory only
)
```

### Log an action

``` r

log_action(log,
  action = "approved",
  object = "model_v3",
  reason = "Validation metrics passed agreed threshold"
)
```

### Log a field change

``` r

log_change(log,
  object = "experiment_7",
  field  = "learning_rate",
  before = "0.01",
  after  = "0.001",
  reason = "Loss diverging — reduced per tuning protocol"
)
```

`reason` is mandatory with no default. Every entry must document why it
was made.

### Verify chain integrity

``` r

verify_log(log)
#> regulog: Log intact: 2 entries, chain unbroken

# Also works directly from the .rlog file
verify_log("logs/audit.rlog")
```

### Export

``` r

# Plain export
export_audit_trail(log, format = "csv", path = "audit.csv")

# Signed: runs verify_log() and stamps chain_intact + verified_at on every row
export_audit_trail(log,
  format = "csv",
  signed = TRUE,
  path   = "audit_signed.csv"
)
```

## Shiny integration

``` r

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

[`regulog_shiny_init()`](https://repro-stats.github.io/regulog/reference/regulog_shiny_init.md)
resolves the user from `session$user` (the authenticated identity from
Shiny Server Pro or Posit Connect) and automatically instruments
`session_start` and `session_end` events.

## Regulated environments

For use under 21 CFR Part 11 or EU Annex 11, `regulog` ships with
IQ/OQ/PQ qualification scripts and a Requirements Traceability Matrix in
`inst/validation/`:

``` r

source(system.file("validation/IQ_regulog.R", package = "regulog"))
source(system.file("validation/OQ_regulog.R", package = "regulog"))
source(system.file("validation/PQ_regulog.R", package = "regulog"))
```

## Design principles

- **No silent failures** — every `log_*` call succeeds or errors
  explicitly
- **Reason is mandatory** — no default; enforced at the R level
- **Human-readable** — flat NDJSON; inspectable with a text editor
- **Minimal dependencies** — `digest` and `jsonlite` only
- **Append-only** — log files are never overwritten, only extended
- **Verifiable offline** —
  [`verify_log()`](https://repro-stats.github.io/regulog/reference/verify_log.md)
  works from a file path with no R object needed
