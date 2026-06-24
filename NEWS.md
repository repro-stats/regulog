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

* `log_hooks_enable()` / `log_hooks_disable()` — patch common read
  functions (`haven::read_sas`, `readr::read_csv`, `data.table::fread`,
  `utils::read.csv`, etc.) for automatic data I/O logging. Every read
  is captured as an ACTION entry without any code changes.

* `with_log()` — scoped automatic logging for a code block. Guarantees
  `log_hooks_disable()` is called on exit even if the block errors.

## Validation

* IQ/OQ/PQ qualification scripts updated to v0.2:
  * OQ-015 to OQ-024: tests for `log_note`, `log_signature`,
    `filter_log`, `as.data.frame.regulog`, and `with_log`
  * PQ-006: annotated clinical analysis workflow with notes and signature
  * PQ-007: regulatory inspector query workflow using `filter_log`

* Requirements Traceability Matrix extended with 5 new rows covering
  21 CFR Part 11 §11.100 (signer identity), §11.200 (signature
  components), annotation trail, automated I/O tracking, and audit
  trail query interface.

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