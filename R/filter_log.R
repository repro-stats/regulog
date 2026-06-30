# filter_log.R
# as.data.frame.regulog() S3 method + filter_log() query interface.
#
# .read_rlog() and .entry_to_row() / .empty_csv_frame() are already defined
# in verify.R and export.R respectively — no need to redefine them here.


# --------------------------------------------------------------------------- #
#  as.data.frame.regulog                                                       #
# --------------------------------------------------------------------------- #

#' Convert a regulog object to a data frame
#'
#' Coerces the entries list of a `regulog` object into a flat `data.frame`,
#' one row per entry (genesis record excluded). Columns match those produced
#' by [export_audit_trail()] with `format = "csv"`.
#'
#' Called implicitly by [filter_log()] and useful for direct inspection.
#'
#' @param x A `regulog` object.
#' @param ... Unused; for S3 compatibility.
#'
#' @return A `data.frame` with columns `entry_id`, `timestamp`, `app`,
#'   `app_version`, `user`, `type`, `action`, `object`, `field`, `before`,
#'   `after`, `reason`, `entry_hash`, `prev_hash`.
#'
#' @examples
#' log <- regulog_init(app = "analysis", version = "1.0", user = "jsmith")
#' log_action(log, "run", "primary.R", "Primary model fitted")
#' log_note(log, "Outlier retained per SAP")
#'
#' as.data.frame(log)
#'
#' @exportS3Method as.data.frame regulog
as.data.frame.regulog <- function(x, ...) {
  # Exclude the genesis record — it is infrastructure, not a user action
  entries <- Filter(function(e) !identical(e$type %||% "", "GENESIS"), x$entries)

  if (length(entries) == 0L) {
    return(.empty_csv_frame(signed = FALSE))
  }

  do.call(rbind, lapply(entries, .entry_to_row))
}


# --------------------------------------------------------------------------- #
#  filter_log                                                                  #
# --------------------------------------------------------------------------- #

#' Filter audit log entries
#'
#' Extracts a subset of entries from a `regulog` object or a `.rlog` file
#' as a plain `data.frame`. All filter arguments are optional — omitting all
#' returns every entry.
#'
#' @param log A `regulog` object **or** a path to a `.rlog` file.
#' @param type Character vector of entry types to keep: `"ACTION"`,
#'   `"CHANGE"`, `"NOTE"`, `"SIGNATURE"`. `NULL` returns all types.
#' @param user Character vector of user identifiers to keep. `NULL` returns
#'   all users.
#' @param action Character vector of action values to keep (e.g.
#'   `"approved"`, `"signature"`, `"note"`, `"data_read"`). `NULL` returns
#'   all actions.
#' @param from Start of the time window. ISO 8601 string (`"2026-06-01"`)
#'   or `Date`. `NULL` applies no lower bound.
#' @param to End of the time window. Same format as `from`. Inclusive.
#'   `NULL` applies no upper bound.
#'
#' @return A `data.frame` of matching entries, sorted by `entry_id`.
#'   Returns a zero-row data frame when nothing matches.
#'
#' @examples
#' log <- regulog_init(app = "analysis", version = "1.0", user = "jsmith")
#' log_action(log, "run", "primary.R", "Primary model fitted")
#' log_note(log, "Outlier in subject 042 retained per SAP")
#' log_action(log, "export", "results.csv", "Sent to sponsor")
#' log_signature(log, "Analysis complete and accurate per SAP v2")
#'
#' # All entries as a data frame
#' filter_log(log)
#'
#' # Only signatures
#' filter_log(log, type = "SIGNATURE")
#'
#' # Actions and notes by a specific user
#' filter_log(log, type = c("ACTION", "NOTE"), user = "jsmith")
#'
#' # Entries within a date range
#' filter_log(log, from = "2026-06-01", to = "2026-12-31")
#'
#' # Works directly on a .rlog file — no live session needed
#' \dontrun{
#' filter_log("logs/audit.rlog", type = "SIGNATURE")
#' }
#'
#' @seealso [as.data.frame.regulog()], [export_audit_trail()], [verify_log()]
#' @export
filter_log <- function(log, type = NULL, user = NULL, action = NULL,
                       from = NULL, to = NULL) {
  # Accept file path — .read_rlog() is defined in verify.R
  if (is.character(log) && length(log) == 1L) {
    if (!file.exists(log)) stop("Log file not found: ", log)
    raw <- .read_rlog(log)
    # Build a minimal regulog-compatible list so as.data.frame.regulog() works
    log <- structure(
      list(entries = raw, user = NA_character_, path = log),
      class = "regulog"
    )
  }

  .assert_regulog(log)

  df <- as.data.frame(log)

  if (nrow(df) == 0L) {
    return(df)
  }

  if (!is.null(type)) df <- df[df$type %in% type, , drop = FALSE]
  if (!is.null(user)) df <- df[df$user %in% user, , drop = FALSE]
  if (!is.null(action)) df <- df[df$action %in% action, , drop = FALSE]

  if (!is.null(from)) {
    from_ts <- as.POSIXct(paste0(from, "T00:00:00Z"),
      tz = "UTC",
      format = "%Y-%m-%dT%H:%M:%SZ"
    )
    entry_ts <- as.POSIXct(df$timestamp,
      tz = "UTC",
      format = "%Y-%m-%dT%H:%M:%OSZ"
    )
    df <- df[entry_ts >= from_ts, , drop = FALSE]
  }

  if (!is.null(to)) {
    to_ts <- as.POSIXct(paste0(to, "T23:59:59Z"),
      tz = "UTC",
      format = "%Y-%m-%dT%H:%M:%SZ"
    )
    entry_ts <- as.POSIXct(df$timestamp,
      tz = "UTC",
      format = "%Y-%m-%dT%H:%M:%OSZ"
    )
    df <- df[entry_ts <= to_ts, , drop = FALSE]
  }

  rownames(df) <- NULL
  df
}
