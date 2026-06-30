# log_note.R
# Free-text annotation entry type.


#' Log a free-text note in the audit trail
#'
#' Records a NOTE entry — a free-text annotation that adds context, intent, or
#' an observation without requiring a discrete action verb or a before/after
#' value. Use it to document analytical decisions, assumptions, or rationale
#' that do not fit [log_action()] or [log_change()].
#'
#' Like all `regulog` entries, `text` is mandatory with no default and is
#' included in the hash chain, making it tamper-evident.
#'
#' @param log A `regulog` object returned by [regulog_init()] or
#'   [regulog_shiny_init()].
#' @param text The note text. Cannot be blank or whitespace-only.
#'
#' @return The `regulog` object, invisibly (pipe-friendly).
#'
#' @examples
#' log <- regulog_init(app = "analysis", version = "1.0", user = "jsmith")
#'
#' log_note(log, "Baseline window defined as Day -1 to Day 1 per protocol v3 §5.2")
#' log_note(log, "Outlier in subject 042 discussed with medical monitor — retained per SAP")
#'
#' @seealso [log_action()], [log_change()], [log_signature()]
#' @export
log_note <- function(log, text) {
  .assert_regulog(log)
  .assert_reason(text)

  entry <- .build_entry(
    log    = log,
    type   = "NOTE",
    user   = log$user,
    fields = list(action = "note", reason = text)
  )
  .commit(log, entry)

  message("regulog: note logged")
  invisible(log)
}
