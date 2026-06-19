# regulog (development version)

## regulog 0.0.0.9000

### New features

* `regulog_init()` — initialise a hash-chained audit log session. Writes a
  genesis record to disk if `path` is supplied.

* `log_action()` — log a discrete user action. `reason` is mandatory with
  no default — every entry must document why it was made.

* `log_change()` — log a before/after field change with mandatory `reason`.
  Captures what changed, who changed it, when, and why.

* `verify_log()` — recompute every entry hash and confirm chain links.
  Accepts both a live `regulog` object and a `.rlog` file path.

* `export_audit_trail()` — export entries as CSV or JSON, with optional date
  filtering. `signed = TRUE` runs verification and stamps `chain_intact` and
  `verified_at` into the export.

* `regulog_shiny_init()` — Shiny integration. Resolves `session$user` as the
  authenticated identity and instruments `session_start` / `session_end`
  events automatically.

* `regulog_observer()` — convenience wrapper around `shiny::observeEvent()`
  that logs an action on every trigger.

* `inst/validation/` — IQ/OQ/PQ qualification scripts and Requirements
  Traceability Matrix (RTM) for 21 CFR Part 11 and EU Annex 11. Available
  as an optional addon for regulated deployments.
