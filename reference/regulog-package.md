# regulog: Tamper-Evident Audit Logging for R

Every analytical action taken in a consequential R environment should be
documented — who did it, what they did, when, and why. In practice,
almost none of it is.

`regulog` fills that gap. It records every action, change, note, and
decision into a tamper-evident, hash-chained audit trail stored as
newline-delimited JSON. Every entry is attributed to a named user,
time-stamped in UTC, and linked to the previous entry via SHA-256 — so
any modification after the fact, however subtle, is detectable by
[`verify_log()`](https://repro-stats.github.io/regulog/reference/verify_log.md).

The design is intentionally general. `regulog` works equally well in
regulated pharmaceutical environments (21 CFR Part 11, EU Annex 11),
internal data pipelines, multi-user Shiny applications, and any other
context where accountability and traceability matter. The IQ/OQ/PQ
qualification scripts are available for validated computerised systems
but are not a prerequisite for general use.

## Workflow

**Step 1 — Initialise the session**

    log <- regulog_init(
      app     = "primary-analysis",
      version = "1.0.0",
      user    = "ndoh.penn",
      path    = "logs/trial001_audit.rlog"
    )

**Step 2 — Log actions, changes, notes, and decisions**

    log_action(log, "data_read", "adsl.sas7bdat",
               "Reading ADSL for primary efficacy analysis")

    log_change(log, object = "param_alpha", field = "value",
               before = "0.05", after = "0.025",
               reason = "Updated per protocol amendment 2 (2026-05-01)")

    log_note(log, "Outlier in subject 042 at Week 16 retained per SAP
                  section 8.3 after discussion with medical monitor")

**Step 3 — Automate data I/O logging**

    # Scoped: hooks on for the block, guaranteed off on exit
    with_log(log, {
      adsl <- haven::read_sas("data/adsl.sas7bdat")   # auto-logged
      adae <- haven::read_sas("data/adae.sas7bdat")   # auto-logged
    })

    # Manual: enable then disable explicitly
    log_hooks_enable(log)
    adlb <- haven::read_sas("data/adlb.sas7bdat")
    log_hooks_disable()

**Step 4 — Apply an electronic signature**

    log_signature(log,
      "I certify that this analysis is accurate and complete, conducted
       in accordance with SAP version 2.0 dated 2026-05-01"
    )

**Step 5 — Verify, query, and export**

    # Verify tamper integrity
    verify_log(log)

    # Query entries
    filter_log(log, type = "SIGNATURE")
    filter_log(log, action = "data_read", from = "2026-06-01")

    # Export
    export_audit_trail(log, format = "csv", signed = TRUE,
                       path = "outputs/audit_trail_TRIAL001.csv")

## Key functions

|  |  |
|----|----|
| Function | Purpose |
| [`regulog_init()`](https://repro-stats.github.io/regulog/reference/regulog_init.md) | Initialise an audit logging session |
| [`log_action()`](https://repro-stats.github.io/regulog/reference/log_action.md) | Log a discrete action (approval, export, run, etc.) |
| [`log_change()`](https://repro-stats.github.io/regulog/reference/log_change.md) | Log a before/after field change |
| [`log_note()`](https://repro-stats.github.io/regulog/reference/log_note.md) | Log a free-text annotation or analytical decision |
| [`log_signature()`](https://repro-stats.github.io/regulog/reference/log_signature.md) | Apply an electronic signature |
| [`log_hooks_enable()`](https://repro-stats.github.io/regulog/reference/log_hooks_enable.md) | Patch read functions for automatic I/O logging |
| [`log_hooks_disable()`](https://repro-stats.github.io/regulog/reference/log_hooks_disable.md) | Restore original read functions |
| [`with_log()`](https://repro-stats.github.io/regulog/reference/with_log.md) | Scoped automatic logging for a code block |
| [`verify_log()`](https://repro-stats.github.io/regulog/reference/verify_log.md) | Verify the SHA-256 hash chain integrity |
| [`filter_log()`](https://repro-stats.github.io/regulog/reference/filter_log.md) | Query log entries by type, user, action, or date |
| [`export_audit_trail()`](https://repro-stats.github.io/regulog/reference/export_audit_trail.md) | Export to CSV or JSON, with optional signing |
| [`regulog_shiny_init()`](https://repro-stats.github.io/regulog/reference/regulog_shiny_init.md) | Initialise inside a Shiny server function |
| [`regulog_observer()`](https://repro-stats.github.io/regulog/reference/regulog_observer.md) | Auto-log Shiny reactive input events |

## The hash chain

Every entry stores the SHA-256 hash of all prior entries:

    h_0 = SHA256("GENESIS" | app | version | timestamp)
    h_n = SHA256(entry_id | timestamp | app | version | user | type |
                 <payload fields> | h_{n-1})

Altering any field in any entry — including the timestamp or reason —
breaks the chain from that entry forward.
[`verify_log()`](https://repro-stats.github.io/regulog/reference/verify_log.md)
recomputes every hash and reports the first broken link. This works
offline, from the raw `.rlog` file, without an active R session.

## Entry types

|  |  |  |
|----|----|----|
| Type | Created by | Purpose |
| `ACTION` | [`log_action()`](https://repro-stats.github.io/regulog/reference/log_action.md) | Discrete events: reads, runs, approvals |
| `CHANGE` | [`log_change()`](https://repro-stats.github.io/regulog/reference/log_change.md) | Before/after field modifications |
| `NOTE` | [`log_note()`](https://repro-stats.github.io/regulog/reference/log_note.md) | Free-text decisions and annotations |
| `SIGNATURE` | [`log_signature()`](https://repro-stats.github.io/regulog/reference/log_signature.md) | Named, dated, meaningful sign-off |

## Use in regulated environments

For regulated pharmaceutical and clinical contexts, `regulog` addresses
the following requirements. IQ/OQ/PQ qualification scripts are available
to generate a validation dossier for your specific environment.

|  |  |  |
|----|----|----|
| Regulation | Clause | Coverage |
| 21 CFR Part 11 | §11.10(e) | Hash-chained, time-stamped, user-attributed entries |
| 21 CFR Part 11 | §11.10(b) | [`export_audit_trail()`](https://repro-stats.github.io/regulog/reference/export_audit_trail.md) — CSV and JSON |
| 21 CFR Part 11 | §11.10(c) | Append-only `.rlog` format |
| 21 CFR Part 11 | §11.100 | [`log_signature()`](https://repro-stats.github.io/regulog/reference/log_signature.md) — named signer identity |
| 21 CFR Part 11 | §11.200 | Signature components: identity, timestamp, meaning |
| EU Annex 11 | Clause 9 | Date, time, user, and action on every entry |
| EU Annex 11 | Clause 11 | [`verify_log()`](https://repro-stats.github.io/regulog/reference/verify_log.md) — periodic integrity verification |

    source(system.file("validation/IQ_regulog.R", package = "regulog"))
    source(system.file("validation/OQ_regulog.R", package = "regulog"))
    source(system.file("validation/PQ_regulog.R", package = "regulog"))

## See also

Useful links:

- <https://repro-stats.github.io/regulog/>

- <https://github.com/repro-stats/regulog>

- Report bugs at <https://github.com/repro-stats/regulog/issues>

## Author

**Maintainer**: Ndoh Penn <ndohpenn9@gmail.com>
([ORCID](https://orcid.org/0009-0003-9054-465X))
