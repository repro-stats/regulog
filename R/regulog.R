# regulog.R
# Core: regulog_init(), log_action(), log_change()
#
# Design notes:
#   - Entry structure is flat (not nested payload) so .rlog files are
#     inspectable with a text editor without any specialist knowledge.
#   - Only digest + jsonlite are imported. No cli, no rlang. This keeps
#     the dependency footprint minimal.
#   - reason is mandatory with no default — callers must justify every entry.
#   - No silent failures: every log_* call succeeds or stops explicitly.


# --------------------------------------------------------------------------- #
#  regulog_init                                                                #
# --------------------------------------------------------------------------- #

#' Initialise a regulog audit log session
#'
#' Creates a new audit log session object. Subsequent calls to [log_action()],
#' [log_change()], [log_note()], and [log_signature()] append hash-chained
#' entries. If `path` is supplied, entries are written to a newline-delimited
#' JSON file (`.rlog`).
#'
#' @param app Character. Application or system name (e.g. `"data-pipeline"`,
#'   `"review-tool"`, `"ml-trainer"`).
#' @param version Character. Application version string.
#' @param user Character. Identity of the acting user. Defaults to
#'   `Sys.info()[["user"]]`. In Shiny, pass `session$user`.
#' @param path Character or `NULL`. Path for persistent storage. If `NULL`,
#'   the log is in-memory only (suitable for development / testing).
#' @param hash_algo Character. Algorithm passed to [digest::digest()].
#'   Defaults to `"sha256"`. Do not change once a log file is in use.
#'
#' @return An S3 object of class `"regulog"` (an environment).
#'
#' @details
#' ## Entry structure
#' Every entry written to disk is a JSON object on a single line:
#' ```json
#' {
#'   "entry_id":    1,
#'   "timestamp":   "2026-06-18T14:32:01.123456Z",
#'   "app":         "my-app",
#'   "app_version": "1.0.0",
#'   "user":        "jsmith",
#'   "type":        "ACTION",
#'   "action":      "approved",
#'   "object":      "model_v3",
#'   "reason":      "Validation metrics passed threshold",
#'   "prev_hash":   "e3b0c44298fc1c149afb...",
#'   "entry_hash":  "a87ff679a2f3e71d9181..."
#' }
#' ```
#' The flat structure is intentional: the log should be inspectable with a
#' text editor, without any specialist software.
#'
#' ## Hash chain
#' Each `entry_hash` is SHA-256 of a canonical string encoding all fields
#' plus `prev_hash`. Altering any field — including the timestamp or reason —
#' invalidates the hash and all subsequent chain links, detectable by
#' [verify_log()].
#'
#' ## What the chain captures
#' | Property | Implementation |
#' |---|---|
#' | Who acted | `user` field on every entry |
#' | What happened | `action` + `object` fields |
#' | When | ISO-8601 UTC timestamp, microsecond resolution |
#' | Why | Mandatory `reason` — no default |
#' | What changed | `before`/`after` in [log_change()] |
#' | Tamper evidence | SHA-256 hash chain; verified by [verify_log()] |
#' | Portable export | [export_audit_trail()] to CSV or JSON |
#'
#' @examples
#' log <- regulog_init(
#'   app     = "my-app",
#'   version = "1.0.0",
#'   user    = "jsmith"
#' )
#' log
#'
#' @export
regulog_init <- function(app,
                         version = "unknown",
                         user = Sys.info()[["user"]],
                         path = NULL,
                         hash_algo = "sha256") {
  if (!is.character(app) || !nzchar(app)) stop("`app` must be a non-empty string.")
  if (!is.character(user) || !nzchar(user)) stop("`user` must be a non-empty string.")

  # Call .utc_now() exactly once so the genesis hash and the stored genesis
  # record timestamp are computed from the same instant. Two separate calls
  # produce different microsecond values, making the genesis hash permanently
  # unverifiable from the stored record.
  now <- .utc_now()

  genesis_hash <- digest::digest(
    object    = paste0("GENESIS", "|", app, "|", version, "|", now),
    algo      = hash_algo,
    serialize = FALSE
  )

  log <- new.env(parent = emptyenv())
  log$app <- app
  log$version <- version
  log$user <- user
  log$path <- path
  log$hash_algo <- hash_algo
  log$entries <- list()
  log$last_hash <- genesis_hash
  log$genesis_hash <- genesis_hash
  log$entry_id <- 0L
  log$created_at <- now # same instant as genesis hash — not a second call

  if (!is.null(path)) {
    .ensure_log_dir(path)
    genesis_record <- list(
      entry_id    = 0L,
      timestamp   = now, # same instant used in hash computation
      app         = app,
      app_version = version,
      user        = user,
      type        = "GENESIS",
      hash_algo   = hash_algo, # persisted so verify_log.character() can read it
      prev_hash   = "0",
      entry_hash  = genesis_hash
    )
    .append_ndjson(genesis_record, path)
  }

  structure(log, class = "regulog")
}


# --------------------------------------------------------------------------- #
#  log_action                                                                  #
# --------------------------------------------------------------------------- #

#' Log a discrete action in the audit trail
#'
#' Records a user action (approval, rejection, sign-off, deployment, export,
#' etc.) as a tamper-evident, hash-chained entry in the audit log.
#'
#' @param log A `regulog` object from [regulog_init()].
#' @param action Character. What happened (e.g. `"approved"`, `"deployed"`,
#'   `"rejected"`, `"exported"`).
#' @param object Character. What it happened to (filename, model ID, record
#'   ID, pipeline step, etc.).
#' @param reason Character. **Mandatory.** Why it happened. No default.
#' @param user Character. Override the session user for this entry. Defaults
#'   to the user set at [regulog_init()].
#'
#' @return The `regulog` object, invisibly (pipe-friendly).
#'
#' @examples
#' log <- regulog_init(app = "my-app", user = "jsmith")
#' log_action(log,
#'   action = "approved",
#'   object = "model_v3",
#'   reason = "Validation metrics passed agreed threshold"
#' )
#'
#' @export
log_action <- function(log,
                       action,
                       object,
                       reason,
                       user = log$user) {
  .assert_regulog(log)
  .assert_reason(reason)

  entry <- .build_entry(
    log    = log,
    type   = "ACTION",
    user   = user,
    fields = list(action = action, object = object, reason = reason)
  )
  .commit(log, entry)

  message(sprintf("regulog: logged action '%s' on '%s'", action, object))
  invisible(log)
}


# --------------------------------------------------------------------------- #
#  log_change                                                                  #
# --------------------------------------------------------------------------- #

#' Log a before/after field change in the audit trail
#'
#' Records a data modification with both prior and new values. Use this
#' whenever a specific field on a record is changed and you need a full
#' history of what it was, what it became, and why.
#'
#' @param log A `regulog` object from [regulog_init()].
#' @param object Character. The record being modified (e.g. `"user_42"`,
#'   `"config.yaml"`, `"experiment_7"`).
#' @param field Character. The field that changed (e.g. `"status"`, `"threshold"`).
#' @param before The value before the change (coerced to character).
#' @param after The value after the change (coerced to character).
#' @param reason Character. **Mandatory.** Why the change was made. No default.
#' @param user Character. Override the session user. Defaults to session user.
#'
#' @return The `regulog` object, invisibly.
#'
#' @examples
#' log <- regulog_init(app = "my-app", user = "jsmith")
#' log_change(log,
#'   object = "experiment_7",
#'   field  = "learning_rate",
#'   before = "0.01",
#'   after  = "0.001",
#'   reason = "Loss diverging at 0.01 — reduced per tuning protocol"
#' )
#'
#' @export
log_change <- function(log,
                       object,
                       field,
                       before,
                       after,
                       reason,
                       user = log$user) {
  .assert_regulog(log)
  .assert_reason(reason)

  entry <- .build_entry(
    log = log,
    type = "CHANGE",
    user = user,
    fields = list(
      object = object,
      field  = field,
      before = as.character(before),
      after  = as.character(after),
      reason = reason
    )
  )
  .commit(log, entry)

  message(sprintf("regulog: logged change to %s$%s", object, field))
  invisible(log)
}


# --------------------------------------------------------------------------- #
#  print method                                                                #
# --------------------------------------------------------------------------- #

#' @export
print.regulog <- function(x, ...) {
  n <- length(x$entries)
  cat(sprintf(
    "<regulog>\n  App:     %s v%s\n  User:    %s\n  Entries: %d\n  Path:    %s\n",
    x$app, x$version, x$user, n,
    if (is.null(x$path)) "(in-memory only)" else x$path
  ))
  invisible(x)
}


# --------------------------------------------------------------------------- #
#  Internal helpers                                                             #
# --------------------------------------------------------------------------- #

#' @noRd
.utc_now <- function() {
  format(Sys.time(), "%Y-%m-%dT%H:%M:%OS6Z", tz = "UTC")
}

#' @noRd
.ensure_log_dir <- function(path) {
  d <- dirname(path)
  if (!dir.exists(d)) dir.create(d, recursive = TRUE)
}

#' @noRd
.append_ndjson <- function(record, path) {
  line <- jsonlite::toJSON(record, auto_unbox = TRUE)
  cat(line, "\n", file = path, append = TRUE, sep = "")
}

#' Build a single flat, hash-chained log entry
#' @noRd
.build_entry <- function(log, type, user, fields) {
  log$entry_id <- log$entry_id + 1L
  ts <- .utc_now()

  # Canonical hash input: pipe-delimited string of every value in a fixed order.
  # Using paste() on scalar values avoids any JSON serialisation ambiguity —
  # the same string must be reproducible in .run_verification().
  # Field order: entry_id | timestamp | app | app_version | user | type |
  #              <field-values in sorted key order> | prev_hash
  field_str <- paste(
    paste(
      sort(names(fields)),
      sapply(sort(names(fields)), function(k) fields[[k]]),
      sep = "=", collapse = ";"
    ),
    sep = ""
  )

  hash_input <- paste(
    log$entry_id, ts, log$app, log$version, user, type,
    field_str,
    log$last_hash,
    sep = "|"
  )

  entry_hash <- digest::digest(hash_input, algo = log$hash_algo, serialize = FALSE)

  # Flat entry — all fields at the top level, matching the spec JSON shape
  entry <- c(
    list(
      entry_id    = log$entry_id,
      timestamp   = ts,
      app         = log$app,
      app_version = log$version,
      user        = user,
      type        = type
    ),
    fields,
    list(
      prev_hash  = log$last_hash,
      entry_hash = entry_hash
    )
  )

  entry
}

#' Commit: update state and write to disk
#' @noRd
.commit <- function(log, entry) {
  log$entries <- c(log$entries, list(entry))
  log$last_hash <- entry$entry_hash
  if (!is.null(log$path)) {
    .append_ndjson(entry, log$path)
  }
}

#' @noRd
.assert_regulog <- function(log) {
  if (!inherits(log, "regulog")) {
    stop("`log` must be a `regulog` object created by regulog_init().")
  }
}

#' @noRd
.assert_reason <- function(reason) {
  if (missing(reason) || !is.character(reason) || !nzchar(trimws(reason))) {
    stop(
      "A `reason` is required for every logged action or change.\n",
      "  Every entry in the audit trail must document why it was made.\n",
      "  Provide a justification, e.g.: reason = \"Validation metrics passed threshold\"."
    )
  }
}

#' @noRd
`%||%` <- function(x, y) if (is.null(x)) y else x
