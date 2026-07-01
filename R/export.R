# export.R
# export_audit_trail(): structured export of log entries.
#
# Two formats:
#   "csv"  — flat data frame; one row per entry; easy to load into any tool
#   "json" — envelope with metadata + entries; suitable for archival or APIs
#
# signed = TRUE runs verify_log() and stamps chain_intact + verified_at
# on every row / in the envelope.


#' Export the audit trail
#'
#' Serialises log entries to CSV or JSON, with optional date filtering. Use
#' `signed = TRUE` to run chain verification and stamp the integrity result
#' into the export — useful for handoffs, audits, or archival.
#'
#' @param log A `regulog` object or a path to a `.rlog` file.
#' @param format Character. `"csv"` or `"json"`.
#' @param from Character or `NULL`. Include entries on or after this date
#'   (ISO-8601, e.g. `"2026-01-01"`).
#' @param to Character or `NULL`. Include entries on or before this date.
#' @param path Character or `NULL`. Output file path. If `NULL`, returns
#'   the data without writing to disk.
#' @param signed Logical. If `TRUE`, verify the chain and include
#'   `chain_intact` and `verified_at` fields in the export.
#' @param include_genesis Logical. Include the genesis record. Default `FALSE`.
#'
#' @return A data frame (CSV) or list (JSON), invisibly.
#'
#' @details
#' ## CSV column layout
#' | Column | Description |
#' |---|---|
#' | `entry_id` | Monotone sequence number |
#' | `timestamp` | ISO-8601 UTC |
#' | `app` | Application name |
#' | `app_version` | Application version |
#' | `user` | Acting user identity |
#' | `type` | `ACTION`, `CHANGE`, `NOTE`, or `SIGNATURE` |
#' | `action` | Action label (`ACTION` entries) |
#' | `object` | Target of the action or change |
#' | `field` | Field name (`CHANGE` entries) |
#' | `before` | Prior value (`CHANGE` entries) |
#' | `after` | New value (`CHANGE` and `SIGNATURE` entries) |
#' | `reason` | Justification (`ACTION`, `CHANGE`, `NOTE` entries) |
#' | `text` | Free-text annotation (`NOTE` entries) |
#' | `meaning` | Signature meaning (`SIGNATURE` entries) |
#' | `entry_hash` | SHA-256 of this entry |
#' | `prev_hash` | SHA-256 of prior entry |
#' | `chain_intact` | `TRUE`/`FALSE` (signed exports only) |
#' | `verified_at` | ISO-8601 UTC of export (signed exports only) |
#'
#' @examples
#' log <- regulog_init(app = "my-app", user = "jsmith")
#' log_action(log,
#'   action = "approved",
#'   object = "model_v3",
#'   reason = "Metrics passed threshold"
#' )
#' df <- export_audit_trail(log, format = "csv")
#'
#' \donttest{
#' export_audit_trail(log,
#'   format = "csv",
#'   from   = "2026-01-01",
#'   signed = TRUE,
#'   path   = tempfile(fileext = ".csv")
#' )
#' }
#'
#' @export
export_audit_trail <- function(log,
                               format          = c("csv", "json"),
                               from            = NULL,
                               to              = NULL,
                               path            = NULL,
                               signed          = FALSE,
                               include_genesis = FALSE) {
  format <- match.arg(format)

  # Resolve entries and metadata
  if (inherits(log, "regulog")) {
    entries <- log$entries
    app     <- log$app
    version <- log$version
  } else if (is.character(log) && length(log) == 1L) {
    all_rec <- .read_rlog(log)
    app     <- all_rec[[1L]]$app         %||% "unknown"
    version <- all_rec[[1L]]$app_version %||% "unknown"
    entries <- all_rec
  } else {
    stop("`log` must be a `regulog` object or a path to a `.rlog` file.")
  }

  # Filter genesis unless requested
  if (!include_genesis) {
    entries <- Filter(function(e) !identical(e$type, "GENESIS"), entries)
  }

  # Date filtering (shared helper — see filter_log.R)
  entries <- .filter_by_date(entries, from, to)

  export_ts    <- format(Sys.time(), "%Y-%m-%dT%H:%M:%OS6Z", tz = "UTC")
  chain_intact <- NA

  if (signed) {
    vr           <- verify_log(log, verbose = FALSE)
    chain_intact <- vr$intact
  }

  if (format == "csv") {
    result <- .to_csv(entries, signed, chain_intact, export_ts, path)
  } else {
    result <- .to_json(entries, app, version, signed, chain_intact, export_ts, path)
  }

  invisible(result)
}


# --------------------------------------------------------------------------- #
#  CSV serialisation                                                            #
# --------------------------------------------------------------------------- #

.to_csv <- function(entries, signed, chain_intact, export_ts, path) {
  if (length(entries) == 0L) {
    df <- .empty_csv_frame(signed)
  } else {
    rows <- lapply(entries, .entry_to_row)
    df   <- do.call(rbind, rows)
    if (signed) {
      df$chain_intact <- chain_intact
      df$verified_at  <- export_ts
    }
  }

  if (!is.null(path)) {
    utils::write.csv(df, file = path, row.names = FALSE)
    message(sprintf("regulog: exported %d row(s) to %s", nrow(df), path))
  }

  invisible(df)
}

.entry_to_row <- function(e) {
  data.frame(
    entry_id    = e$entry_id    %||% NA_integer_,
    timestamp   = e$timestamp   %||% NA_character_,
    app         = e$app         %||% NA_character_,
    app_version = e$app_version %||% NA_character_,
    user        = e$user        %||% NA_character_,
    type        = e$type        %||% NA_character_,
    action      = e$action      %||% NA_character_,
    object      = e$object      %||% NA_character_,
    field       = e$field       %||% NA_character_,
    before      = e$before      %||% NA_character_,
    after       = e$after       %||% NA_character_,
    reason      = e$reason      %||% NA_character_,
    text        = e$text        %||% NA_character_,
    meaning     = e$meaning     %||% NA_character_,
    entry_hash  = e$entry_hash  %||% NA_character_,
    prev_hash   = e$prev_hash   %||% NA_character_,
    stringsAsFactors = FALSE
  )
}

.empty_csv_frame <- function(signed) {
  df <- data.frame(
    entry_id    = integer(0),   timestamp   = character(0),
    app         = character(0), app_version = character(0),
    user        = character(0), type        = character(0),
    action      = character(0), object      = character(0),
    field       = character(0), before      = character(0),
    after       = character(0), reason      = character(0),
    text        = character(0), meaning     = character(0),
    entry_hash  = character(0), prev_hash   = character(0),
    stringsAsFactors = FALSE
  )
  if (signed) {
    df$chain_intact <- logical(0)
    df$verified_at  <- character(0)
  }
  df
}


# --------------------------------------------------------------------------- #
#  JSON serialisation                                                           #
# --------------------------------------------------------------------------- #

.to_json <- function(entries, app, version, signed, chain_intact,
                     export_ts, path) {
  envelope <- list(
    export_metadata = list(
      exported_at  = export_ts,
      app          = app,
      app_version  = version,
      entry_count  = length(entries),
      chain_intact = if (signed) chain_intact else NULL,
      verified_at  = if (signed) export_ts    else NULL
    ),
    entries = entries
  )

  json_str <- jsonlite::toJSON(
    envelope,
    auto_unbox = TRUE,
    pretty     = TRUE,
    null       = "null"
  )

  if (!is.null(path)) {
    writeLines(json_str, con = path)
    message(sprintf(
      "regulog: exported %d entr%s to %s",
      length(entries),
      if (length(entries) == 1L) "y" else "ies",
      path
    ))
  }

  invisible(envelope)
}


# --------------------------------------------------------------------------- #
#  Date filtering  (shared with filter_log.R via .filter_by_date)              #
# --------------------------------------------------------------------------- #

.filter_by_date <- function(entries, from, to) {
  if (is.null(from) && is.null(to)) return(entries)

  .ts <- function(e) {
    as.POSIXct(e$timestamp, tz = "UTC", format = "%Y-%m-%dT%H:%M:%OSZ")
  }

  if (!is.null(from)) {
    from_dt <- as.POSIXct(
      paste0(from, "T00:00:00Z"), tz = "UTC", format = "%Y-%m-%dT%H:%M:%SZ"
    )
    entries <- Filter(function(e) .ts(e) >= from_dt, entries)
  }

  if (!is.null(to)) {
    to_dt <- as.POSIXct(
      paste0(to, "T23:59:59Z"), tz = "UTC", format = "%Y-%m-%dT%H:%M:%SZ"
    )
    entries <- Filter(function(e) .ts(e) <= to_dt, entries)
  }

  entries
}