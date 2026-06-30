# log_signature.R
# Electronic signature entry per 21 CFR Part 11 §11.100 / §11.200.


#' Apply an electronic signature to the audit trail
#'
#' Records a SIGNATURE entry capturing the signer identity (from the session
#' user), UTC timestamp, number of prior entries covered, and the stated
#' meaning of the signature. Addresses 21 CFR Part 11 §11.100 / §11.200
#' requirements:
#'
#' - **Identity** — resolved from the session user set in [regulog_init()]
#' - **Date and time** — UTC timestamp generated automatically at call time
#' - **Meaning** — the `meaning` argument; mandatory, cannot be blank
#' - **Coverage** — number of prior entries in the session, recorded automatically
#'
#' The SIGNATURE entry is part of the hash chain: any tampering with entries
#' preceding the signature, or with the signature entry itself, is detectable
#' by [verify_log()].
#'
#' @param log A `regulog` object returned by [regulog_init()] or
#'   [regulog_shiny_init()].
#' @param meaning The meaning of the signature — what you are certifying.
#'   Cannot be blank. Example: `"I certify that this analysis is accurate
#'   and complete per SAP version 2.0"`.
#'
#' @return The `regulog` object, invisibly (pipe-friendly).
#'
#' @examples
#' log <- regulog_init(app = "analysis", version = "1.0", user = "jsmith")
#' log_action(
#'   log, "run", "primary_analysis.R",
#'   "Primary ANCOVA model executed per SAP section 6.1"
#' )
#'
#' log_signature(
#'   log,
#'   "I certify that this analysis is accurate and complete per SAP version 2.0"
#' )
#'
#' @seealso [log_action()], [log_note()], [verify_log()]
#' @export
log_signature <- function(log, meaning) {
  .assert_regulog(log)
  .assert_reason(meaning)

  # Capture entry count at signature time — automatic, no user input needed
  n_covered <- length(log$entries)

  entry <- .build_entry(
    log = log,
    type = "SIGNATURE",
    user = log$user,
    fields = list(
      action = "signature",
      object = log$user,
      field  = "entries_covered",
      after  = as.character(n_covered),
      reason = meaning
    )
  )
  .commit(log, entry)

  message(sprintf(
    "regulog: signature applied by '%s' covering %d %s",
    log$user, n_covered, if (n_covered == 1L) "entry" else "entries"
  ))
  invisible(log)
}
