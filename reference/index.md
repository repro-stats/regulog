# Package index

## Session lifecycle

- [`regulog_init()`](https://reprostats.org/regulog/reference/regulog_init.md)
  : Initialise a regulog audit log session
- [`regulog`](https://reprostats.org/regulog/reference/regulog-package.md)
  [`regulog-package`](https://reprostats.org/regulog/reference/regulog-package.md)
  : regulog: Tamper-Evident Audit Logging for R

## Logging

- [`log_action()`](https://reprostats.org/regulog/reference/log_action.md)
  : Log a discrete action in the audit trail
- [`log_change()`](https://reprostats.org/regulog/reference/log_change.md)
  : Log a before/after field change in the audit trail
- [`log_note()`](https://reprostats.org/regulog/reference/log_note.md) :
  Log a free-text note in the audit trail
- [`log_signature()`](https://reprostats.org/regulog/reference/log_signature.md)
  : Apply an electronic signature to the audit trail

## Data reads

- [`rl_read()`](https://reprostats.org/regulog/reference/rl_read.md) :
  Log a data read operation
- [`with_log()`](https://reprostats.org/regulog/reference/with_log.md) :
  Run an expression with automatic data read logging

## Verification and query

- [`verify_log()`](https://reprostats.org/regulog/reference/verify_log.md)
  : Verify the integrity of an audit log chain
- [`filter_log()`](https://reprostats.org/regulog/reference/filter_log.md)
  : Filter audit log entries
- [`as.data.frame(`*`<regulog>`*`)`](https://reprostats.org/regulog/reference/as.data.frame.regulog.md)
  : Convert a regulog object to a data frame

## Export

- [`export_audit_trail()`](https://reprostats.org/regulog/reference/export_audit_trail.md)
  : Export the audit trail

## Shiny integration

- [`regulog_shiny_init()`](https://reprostats.org/regulog/reference/regulog_shiny_init.md)
  : Initialise a regulog session inside a Shiny server
- [`regulog_observer()`](https://reprostats.org/regulog/reference/regulog_observer.md)
  : Create a logging observer for a reactive Shiny input
