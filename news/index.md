# Changelog

## regulog (development version)

## regulog 0.2.1

### CRAN resubmission fixes

- Removed “for R” from the package description
- Package names now in single quotes in DESCRIPTION (`'shiny'`,
  `'SHA-256'`)
- Shiny examples wrapped in `if(interactive()){}` per CRAN policy

## regulog 0.2.0

### New functions

- [`log_note()`](https://reprostats.org/regulog/reference/log_note.md) —
  log a free-text annotation or analytical decision as a tamper-evident
  NOTE entry. Mandatory-reason enforced and included in the hash chain.
- [`log_signature()`](https://reprostats.org/regulog/reference/log_signature.md)
  — apply an electronic signature per 21 CFR Part 11 §11.100/§11.200.
  Signer identity is resolved from the session user; entries covered is
  captured automatically.
- [`filter_log()`](https://reprostats.org/regulog/reference/filter_log.md)
  — query log entries as a `data.frame` by type, user, action, or date
  range. Works directly on `.rlog` file paths without an active session.
- [`as.data.frame.regulog()`](https://reprostats.org/regulog/reference/as.data.frame.regulog.md)
  — S3 method to convert a `regulog` object to a flat data frame, one
  row per entry (genesis record excluded).
- [`rl_read()`](https://reprostats.org/regulog/reference/rl_read.md) —
  explicit, logged read of any data source. Records the reader function,
  resolved file path, row count, and column count as a `data_read`
  ACTION entry. Path is resolved by argument name (`file`, `path`,
  `data_file`, `input`), falling back to the first unnamed argument —
  correct even when arguments are supplied out of position.
- [`with_log()`](https://reprostats.org/regulog/reference/with_log.md) —
  scoped logging for a code block. Provides a local `read()` binding
  tied to the supplied log. Each call is isolated via lexical scope —
  concurrent calls across Shiny sessions never interfere, and errors
  inside the block propagate normally without corrupting previously
  logged entries.

### Validation

- IQ/OQ/PQ qualification scripts updated to v0.2:
  - OQ-015 to OQ-024c: tests for
    [`log_note()`](https://reprostats.org/regulog/reference/log_note.md),
    [`log_signature()`](https://reprostats.org/regulog/reference/log_signature.md),
    [`filter_log()`](https://reprostats.org/regulog/reference/filter_log.md),
    [`as.data.frame.regulog()`](https://reprostats.org/regulog/reference/as.data.frame.regulog.md),
    [`rl_read()`](https://reprostats.org/regulog/reference/rl_read.md),
    and
    [`with_log()`](https://reprostats.org/regulog/reference/with_log.md),
    including concurrent-session isolation
  - PQ-006: annotated clinical analysis workflow with notes and
    signature
  - PQ-007: regulatory inspector query workflow using
    [`filter_log()`](https://reprostats.org/regulog/reference/filter_log.md)
- RTM extended with rows covering 21 CFR Part 11 §11.100/§11.200,
  annotation trail, data read logging, and audit trail query interface.

### Documentation

- Package-level documentation with complete workflow, entry type
  reference, and regulatory coverage table.
- Three vignettes: `getting-started`, `hash-chain`, `shiny-integration`.

## regulog 0.1.0

- Initial release.
- [`regulog_init()`](https://reprostats.org/regulog/reference/regulog_init.md),
  [`log_action()`](https://reprostats.org/regulog/reference/log_action.md),
  [`log_change()`](https://reprostats.org/regulog/reference/log_change.md)
  — core audit logging.
- [`verify_log()`](https://reprostats.org/regulog/reference/verify_log.md)
  — SHA-256 hash chain verification.
- [`export_audit_trail()`](https://reprostats.org/regulog/reference/export_audit_trail.md)
  — CSV and JSON export with optional signing.
- [`regulog_shiny_init()`](https://reprostats.org/regulog/reference/regulog_shiny_init.md),
  [`regulog_observer()`](https://reprostats.org/regulog/reference/regulog_observer.md)
  — Shiny integration.
- IQ/OQ/PQ validation suite (IQ-001–009, OQ-001–014, PQ-001–005).
