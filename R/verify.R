# verify.R
# verify_log(): recompute every hash and confirm chain links are unbroken.
#
# Works on both a live regulog object and a .rlog file path, so verification
# can be run post-hoc from archived files without loading R objects.


#' Verify the integrity of an audit log chain
#'
#' Recomputes every entry hash and confirms each matches the stored value,
#' and that each `prev_hash` matches its predecessor's `entry_hash`. Any
#' discrepancy indicates tampering or corruption.
#'
#' @param log A `regulog` object **or** a character path to a `.rlog` file.
#' @param verbose Logical. Print a summary. Defaults to `TRUE`.
#'
#' @return A list (invisibly) with components:
#' \describe{
#'   \item{`intact`}{Logical. `TRUE` if the chain is unbroken.}
#'   \item{`n_entries`}{Integer. Number of data entries verified (genesis excluded).}
#'   \item{`first_broken`}{Integer or `NA`. `entry_id` of the first invalid entry.}
#'   \item{`errors`}{Character vector of error descriptions.}
#' }
#'
#' @details
#' ## Verification algorithm
#' For each entry *i* (excluding the genesis record):
#' 1. Reconstruct `hash_input` from the stored fields in canonical order.
#' 2. Recompute `digest(hash_input, algo = hash_algo)`.
#' 3. Assert `computed == entry$entry_hash` (content integrity).
#' 4. Assert `entry$prev_hash == entry[i-1]$entry_hash` (chain continuity).
#'
#' Step 3 failure: the entry's content was modified after writing.
#' Step 4 failure: entries were inserted, deleted, or reordered.
#'
#' @examples
#' log <- regulog_init(app = "my-app", user = "jsmith")
#' log_action(log, action = "approved", object = "file.csv",
#'            reason = "Review complete")
#' verify_log(log)
#' #> v Log intact: 1 entry, chain unbroken
#'
#' @export
verify_log <- function(log, verbose = TRUE) {
  UseMethod("verify_log")
}

#' @export
verify_log.regulog <- function(log, verbose = TRUE) {
  .run_verification(
    entries    = log$entries,
    hash_algo  = log$hash_algo,
    first_prev = log$genesis_hash,
    verbose    = verbose
  )
}

#' @export
verify_log.character <- function(log, verbose = TRUE) {
  if (!file.exists(log)) stop("Log file not found: ", log)

  all_records <- .read_rlog(log)

  if (length(all_records) == 0L) {
    stop("Log file is empty: ", log)
  }

  # Split genesis from data entries
  types       <- vapply(all_records, function(r) r$type %||% "", character(1L))
  genesis_idx <- which(types == "GENESIS")

  if (length(genesis_idx) == 0L) {
    warning("No GENESIS record found in ", log, ". Verification may be incomplete.")
    genesis_hash <- "0"
    data_entries <- all_records
  } else {
    genesis_hash <- all_records[[genesis_idx[[1L]]]]$entry_hash
    data_entries <- all_records[-genesis_idx]
  }

  .run_verification(
    entries    = data_entries,
    hash_algo  = "sha256",   # stored in genesis in future; defaulting for v0.1
    first_prev = genesis_hash,
    verbose    = verbose
  )
}


# --------------------------------------------------------------------------- #
#  Internal engine                                                              #
# --------------------------------------------------------------------------- #

.run_verification <- function(entries, hash_algo, first_prev, verbose) {
  errors       <- character(0L)
  first_broken <- NA_integer_
  prev_hash    <- first_prev

  for (i in seq_along(entries)) {
    e <- entries[[i]]
    id <- e$entry_id %||% i

    # Reconstruct hash input using the same canonical format as .build_entry():
    # entry_id | timestamp | app | app_version | user | type |
    # <key=value pairs in sorted key order, semicolon-separated> | prev_hash
    structural <- c("entry_id", "timestamp", "app", "app_version",
                    "user", "type", "prev_hash", "entry_hash")
    payload_keys <- sort(setdiff(names(e), structural))
    field_str <- paste(
      paste(payload_keys, sapply(payload_keys, function(k) e[[k]]),
            sep = "=", collapse = ";"),
      sep = ""
    )

    hash_input <- paste(
      e$entry_id, e$timestamp, e$app, e$app_version, e$user, e$type,
      field_str,
      e$prev_hash,
      sep = "|"
    )

    computed <- digest::digest(hash_input, algo = hash_algo, serialize = FALSE)

    ok_content <- identical(computed, e$entry_hash)
    ok_chain   <- identical(e$prev_hash, prev_hash)

    if (!ok_content) {
      msg <- sprintf("Entry #%d: entry_hash mismatch \u2014 content may have been modified", id)
      errors <- c(errors, msg)
      if (is.na(first_broken)) first_broken <- as.integer(id)
    }

    if (!ok_chain) {
      msg <- sprintf(
        "Entry #%d: prev_hash mismatch \u2014 entries may have been inserted, deleted, or reordered",
        id
      )
      errors <- c(errors, msg)
      if (is.na(first_broken)) first_broken <- as.integer(id)
    }

    prev_hash <- e$entry_hash
  }

  intact <- length(errors) == 0L
  n      <- length(entries)

  if (verbose) {
    if (intact) {
      message(sprintf(
        "regulog: Log intact: %d %s, chain unbroken",
        n, if (n == 1L) "entry" else "entries"
      ))
    } else {
      warning(sprintf(
        "regulog: Log FAILED verification \u2014 %d error(s). First broken entry: #%d\n%s",
        length(errors), first_broken, paste(errors, collapse = "\n")
      ), call. = FALSE)
    }
  }

  invisible(list(
    intact       = intact,
    n_entries    = n,
    first_broken = first_broken,
    errors       = errors
  ))
}

#' Read an .rlog (NDJSON) file into a list of records
#' @noRd
.read_rlog <- function(path) {
  lines <- readLines(path, warn = FALSE)
  lines <- lines[nzchar(trimws(lines))]
  lapply(lines, function(l) jsonlite::fromJSON(l, simplifyVector = FALSE))
}

#' @noRd
`%||%` <- function(x, y) if (is.null(x)) y else x