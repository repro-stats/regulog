## regulog 0.2.0

### New features

* `log_note()`: free-text annotation entries
* `log_signature()`: electronic signatures per 21 CFR Part 11 §11.100/§11.200
* `filter_log()`: query log entries by type, user, action, or date
* `as.data.frame.regulog()`: convert log to data frame
* `log_hooks_enable()` / `log_hooks_disable()` / `with_log()`: automatic data I/O logging
* Updated IQ/OQ/PQ validation suite (OQ-015–024, PQ-006–007)  
* Updated RTM with §11.100, §11.200, and automated tracking coverage

## regulog 0.1.0

### Initial features

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
