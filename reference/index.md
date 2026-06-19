# Package index

## Initialise

Start an audit log session

- [`regulog_init()`](https://repro-stats.github.io/regulog/reference/regulog_init.md)
  : Initialise a regulog audit log session

## Log entries

Record actions and changes

- [`log_action()`](https://repro-stats.github.io/regulog/reference/log_action.md)
  : Log a discrete action in the audit trail
- [`log_change()`](https://repro-stats.github.io/regulog/reference/log_change.md)
  : Log a before/after field change in the audit trail

## Verify

Check chain integrity

- [`verify_log()`](https://repro-stats.github.io/regulog/reference/verify_log.md)
  : Verify the integrity of an audit log chain

## Export

Export the audit trail

- [`export_audit_trail()`](https://repro-stats.github.io/regulog/reference/export_audit_trail.md)
  : Export the audit trail

## Shiny

Shiny session integration

- [`regulog_shiny_init()`](https://repro-stats.github.io/regulog/reference/regulog_shiny_init.md)
  : Initialise a regulog session inside a Shiny server
- [`regulog_observer()`](https://repro-stats.github.io/regulog/reference/regulog_observer.md)
  : Create a logging observer for a reactive Shiny input
