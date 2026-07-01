# filter_log.R
# as.data.frame.regulog() S3 method + filter_log() query interface.
#
# .read_rlog(), .entry_to_row(), .empty_csv_frame(), and .filter_by_date()
# are defined in verify.R and export.R — not redefined here.


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
#'   `after`, `reason`, `text`, `meaning`, `entry_hash`, `prev_hash`.
#'
#' @examples
#' log <- regulog_init(app = "analysis", version = "1.0", user = "jsmith")
#' log_action(log,
#'   action = "run",
#'   object = "primary.R",
#'   reason = "Primary model fitted"
#' )
#' log_note(log, "Outlier in subject 042 retained per SAP")
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
#'   `"approved"`, `"data_read"`). `NULL` returns all actions.
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
#' log_action(log,
#'   action = "run",
#'   object = "primary.R",
#'   reason = "Primary model fitted"
#' )
#' log_note(log, "Outlier in subject 042 retained per SAP")
#' log_action(log,
#'   action = "export",
#'   object = "results.csv",
#'   reason = "Sent to sponsor"
#' )
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
#' \donttest{
#' tmp <- tempfile(fileext = ".rlog")
#' log2 <- regulog_init(app = "analysis", version = "1.0", user = "jsmith",
#'   path = tmp)
#' log_action(log2,
#'   action = "run",
#'   object = "primary.R",
#'   reason = "Primary model fitted"
#' )
#' filter_log(tmp, type = "ACTION")
#' }
#'
#' @seealso [as.data.frame.regulog()], [export_audit_trail()], [verify_log()]
#' @export
filter_log <- function(log,
                       type   = NULL,
                       user   = NULL,
                       action = NULL,
                       from   = NULL,
                       to     = NULL) {

  # Accept file path — .read_rlog() is defined in verify.R
  if (is.character(log) && length(log) == 1L) {
    if (!file.exists(log)) stop("Log file not found: ", log)
    raw <- .read_rlog(log)
    log <- structure(
      list(entries = raw, user = NA_character_, path = log),
      class = "regulog"
    )
  }

  .assert_regulog(log)

  # Work on the raw entry list before conversion so we can reuse the
  # shared .filter_by_date() helper from export.R, eliminating the
  # duplicated timestamp-parsing logic that previously lived here.
  entries <- Filter(
    function(e) !identical(e$type %||% "", "GENESIS"),
    log$entries
  )

  # Date filter on raw entries (shared helper — defined in export.R)
  entries <- .filter_by_date(entries, from, to)

  if (length(entries) == 0L) {
    return(.empty_csv_frame(signed = FALSE))
  }

  df <- do.call(rbind, lapply(entries, .entry_to_row))

  # Apply discrete filters on the data frame
  if (!is.null(type))   df <- df[df$type   %in% type,   , drop = FALSE]
  if (!is.null(user))   df <- df[df$user   %in% user,   , drop = FALSE]
  if (!is.null(action)) df <- df[df$action %in% action, , drop = FALSE]

  rownames(df) <- NULL
  df
}