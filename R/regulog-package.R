#' regulog: Tamper-Evident Audit Logging for R
#'
#' @description
#' Every analytical action taken in a consequential R environment should be
#' documented — who did it, what they did, when, and why. In practice, almost
#' none of it is.
#'
#' `regulog` fills that gap. It records every action, change, note, and
#' decision into a tamper-evident, hash-chained audit trail stored as
#' newline-delimited JSON. Every entry is attributed to a named user,
#' time-stamped in UTC, and linked to the previous entry via SHA-256 — so
#' any modification after the fact, however subtle, is detectable by
#' [verify_log()].
#'
#' The design is intentionally general. `regulog` works equally well in
#' regulated pharmaceutical environments (21 CFR Part 11, EU Annex 11),
#' internal data pipelines, multi-user Shiny applications, and any other
#' context where accountability and traceability matter. The IQ/OQ/PQ
#' qualification scripts are available for validated computerised systems
#' but are not a prerequisite for general use.
#'
#' @section Workflow:
#'
#' **Step 1 — Initialise the session**
#'
#' ```r
#' log <- regulog_init(
#'   app     = "primary-analysis",
#'   version = "1.0.0",
#'   user    = "jsmith",
#'   path    = "logs/trial001_audit.rlog"
#' )
#' ```
#'
#' **Step 2 — Log actions, changes, notes, and decisions**
#'
#' ```r
#' log_action(log, "data_read", "adsl.sas7bdat",
#'            "Reading ADSL for primary efficacy analysis")
#'
#' log_change(log, object = "param_alpha", field = "value",
#'            before = "0.05", after = "0.025",
#'            reason = "Updated per protocol amendment 2 (2026-05-01)")
#'
#' log_note(log, "Outlier in subject 042 at Week 16 retained per SAP
#'               section 8.3 after discussion with medical monitor")
#' ```
#'
#' **Step 3 — Log data reads, explicitly or scoped to a block**
#'
#' ```r
#' # Single read
#' adsl <- rl_read(log, haven::read_sas, "data/adsl.sas7bdat")
#'
#' # Scoped block — read() calls inside resolve to `log` automatically
#' with_log(log, {
#'   adae <- read(haven::read_sas, "data/adae.sas7bdat")
#'   adlb <- read(haven::read_sas, "data/adlb.sas7bdat")
#' })
#' ```
#'
#' **Step 4 — Apply an electronic signature**
#'
#' ```r
#' log_signature(log,
#'   "I certify that this analysis is accurate and complete, conducted
#'    in accordance with SAP version 2.0 dated 2026-05-01"
#' )
#' ```
#'
#' **Step 5 — Verify, query, and export**
#'
#' ```r
#' # Verify tamper integrity
#' verify_log(log)
#'
#' # Query entries
#' filter_log(log, type = "SIGNATURE")
#' filter_log(log, action = "data_read", from = "2026-06-01")
#'
#' # Export
#' export_audit_trail(log, format = "csv", signed = TRUE,
#'                    path = "outputs/audit_trail_TRIAL001.csv")
#' ```
#'
#' @section Key functions:
#'
#' | Function | Purpose |
#' |---|---|
#' | [regulog::regulog_init()] | Initialise an audit logging session |
#' | [regulog::log_action()] | Log a discrete action (approval, export, run, etc.) |
#' | [regulog::log_change()] | Log a before/after field change |
#' | [regulog::log_note()] | Log a free-text annotation or analytical decision |
#' | [regulog::log_signature()] | Apply an electronic signature |
#' | [regulog::rl_read()] | Explicit, logged read of any data source |
#' | [regulog::with_log()] | Scoped logging: `read()` calls inside the block log automatically |
#' | [regulog::verify_log()] | Verify the SHA-256 hash chain integrity |
#' | [regulog::filter_log()] | Query log entries by type, user, action, or date |
#' | [regulog::export_audit_trail()] | Export to CSV or JSON, with optional signing |
#' | [regulog::regulog_shiny_init()] | Initialise inside a Shiny server function |
#' | [regulog::regulog_observer()] | Auto-log Shiny reactive input events |
#'
#' @section The hash chain:
#'
#' Every entry stores the SHA-256 hash of all prior entries:
#'
#' ```
#' h_0 = SHA256("GENESIS" | app | version | timestamp)
#' h_n = SHA256(entry_id | timestamp | app | version | user | type |
#'              <payload fields> | h_{n-1})
#' ```
#'
#' Altering any field in any entry — including the timestamp or reason — breaks
#' the chain from that entry forward. [verify_log()] recomputes every hash and
#' reports the first broken link. This works offline, from the raw `.rlog`
#' file, without an active R session.
#'
#' @section Entry types:
#'
#' | Type | Created by | Purpose |
#' |---|---|---|
#' | `ACTION` | `log_action()` | Discrete events: reads, runs, approvals |
#' | `CHANGE` | `log_change()` | Before/after field modifications |
#' | `NOTE` | `log_note()` | Free-text decisions and annotations |
#' | `SIGNATURE` | `log_signature()` | Named, dated, meaningful sign-off |
#'
#' @section Use in regulated environments:
#'
#' For regulated pharmaceutical and clinical contexts, `regulog` addresses
#' the following requirements. IQ/OQ/PQ qualification scripts are available
#' to generate a validation dossier for your specific environment.
#'
#' | Regulation | Clause | Coverage |
#' |---|---|---|
#' | 21 CFR Part 11 | §11.10(e) | Hash-chained, time-stamped, user-attributed entries |
#' | 21 CFR Part 11 | §11.10(b) | `export_audit_trail()` — CSV and JSON |
#' | 21 CFR Part 11 | §11.10(c) | Append-only `.rlog` format |
#' | 21 CFR Part 11 | §11.100 | `log_signature()` — named signer identity |
#' | 21 CFR Part 11 | §11.200 | Signature components: identity, timestamp, meaning |
#' | EU Annex 11 | Clause 9 | Date, time, user, and action on every entry |
#' | EU Annex 11 | Clause 11 | `verify_log()` — periodic integrity verification |
#'
#' ```r
#' source(system.file("validation/IQ_regulog.R", package = "regulog"))
#' source(system.file("validation/OQ_regulog.R", package = "regulog"))
#' source(system.file("validation/PQ_regulog.R", package = "regulog"))
#' ```
#'
#' @aliases regulog-package
"_PACKAGE"
