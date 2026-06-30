# regulog (development version)

# regulog 0.2.0

## New functions

* `log_note()` — log a free-text annotation or analytical decision as a
  tamper-evident NOTE entry. Every entry is mandatory-reason enforced and
  included in the hash chain.
* `log_signature()` — apply an electronic signature per 21 CFR Part 11
  §11.100/§11.200. Signer identity is resolved from the session user;
  entries covered is captured automatically.
* `filter_log()` — query log entries as a `data.frame` by type, user,
  action, or date range. Also works directly on `.rlog` file paths without
  an active session.
* `as.data.frame.regulog()` — S3 method to convert a `regulog` object to
  a flat data frame, one row per entry (genesis record excluded).
* `rl_read()` — explicit, logged read of any data source. Calls the
  supplied reader function and records the result as a `data_read` ACTION
  entry, capturing the resolved file path, row count, and column count.
  The path is resolved by argument name (`file`, `path`, `data_file`,
  `input`) where possible, falling back to the first unnamed argument —
  correct even when arguments are supplied out of position.
* `with_log()` — scoped logging for a code block. Provides a local `read()`
  binding tied to the supplied log, so reads inside the block don't need
  to repeat the `log` argument. Each `with_log()` call is isolated via
  lexical scope: concurrent calls (e.g. across Shiny sessions) never
  interfere with one another, and an error inside the block propagates
  normally without losing or corrupting entries logged before it.

## Validation

* IQ/OQ/PQ qualification scripts updated to v0.2:
  * OQ-015 to OQ-024c: tests for `log_note`, `log_signature`,
    `filter_log`, `as.data.frame.regulog`, `rl_read`, and `with_log`,
    including concurrent-session isolation
  * PQ-006: annotated clinical analysis workflow with notes and signature
  * PQ-007: regulatory inspector query workflow using `filter_log`
* Requirements Traceability Matrix extended with rows covering
  21 CFR Part 11 §11.100 (signer identity), §11.200 (signature
  components), annotation trail, data read logging, and audit trail
  query interface. See `inst/validation/RTM_regulog.md` for column
  definitions and a script to verify the RTM stays in sync with the
  validation scripts and exported API.

## Documentation

* `regulog-package.R` — package-level documentation with complete
  workflow, entry type reference, and regulatory coverage table.
* Three vignettes: `getting-started`, `hash-chain`, `shiny-integration`.

# regulog 0.1.0

* Initial release.
* `regulog_init()`, `log_action()`, `log_change()` — core audit logging.
* `verify_log()` — SHA-256 hash chain verification.
* `export_audit_trail()` — CSV and JSON export, with optional signing.
* `regulog_shiny_init()`, `regulog_observer()` — Shiny integration.
* IQ/OQ/PQ validation suite (IQ-001–009, OQ-001–014, PQ-001–005).