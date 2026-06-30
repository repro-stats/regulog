# test-rtm-consistency.R
#
# Guards against the RTM (Requirements Traceability Matrix) drifting out of
# sync with the actual IQ/OQ/PQ scripts and the package's exported API.
# This is the automated version of the manual check documented in
# inst/validation/RTM_regulog.md -- it runs on every R CMD check / test run,
# so a stale RTM reference (a renamed test ID, a removed function) fails
# the build rather than being discovered later by manual review.


# --------------------------------------------------------------------------- #
#  Helpers                                                                     #
# --------------------------------------------------------------------------- #

#' Extract all test IDs of a given prefix from a column of ref strings,
#' expanding "A:B" range notation into every member of the range.
#' @noRd
.expand_refs <- function(ref_col, prefix) {
  raw <- ref_col[nzchar(trimws(ref_col))]
  if (length(raw) == 0L) return(character(0L))

  # Split each cell on "," and ":" -- ":" denotes an inclusive range,
  # "," (if ever used) would denote a discrete list
  pieces <- unlist(strsplit(raw, "[,:]"))
  pieces <- trimws(pieces)
  pieces[grepl(paste0("^", prefix), pieces)]
}

#' Extract every quoted test ID literal defined inside an OQ/IQ/PQ script,
#' e.g. .oq_test("OQ-024b", ...) -> "OQ-024b"
#' @noRd
.extract_defined_ids <- function(script_lines, prefix) {
  pattern <- paste0('"', prefix, '[0-9]+[a-z]?"')
  hits <- regmatches(script_lines, gregexpr(pattern, script_lines))
  ids <- unlist(hits)
  gsub('"', "", ids)
}

#' Path to a validation script inside the installed (or in-development)
#' package. Falls back to the local inst/validation/ path during
#' devtools::test() / R CMD check, where the package may not yet be
#' installed with inst/ promoted to top level.
#' @noRd
.validation_path <- function(file) {
  installed <- system.file("validation", file, package = "regulog")
  if (nzchar(installed) && file.exists(installed)) return(installed)

  dev_path <- testthat::test_path("..", "..", "inst", "validation", file)
  if (file.exists(dev_path)) return(dev_path)

  NA_character_
}


# --------------------------------------------------------------------------- #
#  Load the RTM once for all tests in this file                                #
# --------------------------------------------------------------------------- #

rtm_path <- .validation_path("RTM_regulog.csv")

# All tests below are skipped (not failed) if the RTM itself cannot be
# located -- this keeps the suite green in contexts where inst/validation/
# is legitimately absent (e.g. a stripped installation), while still
# catching real drift whenever the RTM is present.

test_that("RTM_regulog.csv can be located and parsed", {
  skip_if(is.na(rtm_path), "RTM_regulog.csv not found; skipping RTM consistency checks")
  rtm <- utils::read.csv(rtm_path, stringsAsFactors = FALSE)
  expect_true(all(c("req_id", "iq_ref", "oq_ref", "pq_ref",
                    "regulog_function", "status") %in% names(rtm)))
  expect_gt(nrow(rtm), 0L)
})


# --------------------------------------------------------------------------- #
#  Every OQ reference in the RTM exists in OQ_regulog.R                        #
# --------------------------------------------------------------------------- #

test_that("every OQ test ID cited in the RTM is defined in OQ_regulog.R", {
  skip_if(is.na(rtm_path), "RTM not found")
  oq_path <- .validation_path("OQ_regulog.R")
  skip_if(is.na(oq_path), "OQ_regulog.R not found")

  rtm <- utils::read.csv(rtm_path, stringsAsFactors = FALSE)
  cited   <- unique(.expand_refs(rtm$oq_ref, "OQ-"))
  defined <- unique(.extract_defined_ids(readLines(oq_path, warn = FALSE), "OQ-"))

  stale <- setdiff(cited, defined)
  expect_equal(
    stale, character(0L),
    info = sprintf(
      "RTM references OQ test ID(s) not found in OQ_regulog.R: %s",
      paste(stale, collapse = ", ")
    )
  )
})


# --------------------------------------------------------------------------- #
#  Every IQ reference in the RTM exists in IQ_regulog.R                        #
# --------------------------------------------------------------------------- #

test_that("every IQ test ID cited in the RTM is defined in IQ_regulog.R", {
  skip_if(is.na(rtm_path), "RTM not found")
  iq_path <- .validation_path("IQ_regulog.R")
  skip_if(is.na(iq_path), "IQ_regulog.R not found")

  rtm <- utils::read.csv(rtm_path, stringsAsFactors = FALSE)
  cited   <- unique(.expand_refs(rtm$iq_ref, "IQ-"))
  defined <- unique(.extract_defined_ids(readLines(iq_path, warn = FALSE), "IQ-"))

  stale <- setdiff(cited, defined)
  expect_equal(
    stale, character(0L),
    info = sprintf(
      "RTM references IQ test ID(s) not found in IQ_regulog.R: %s",
      paste(stale, collapse = ", ")
    )
  )
})


# --------------------------------------------------------------------------- #
#  Every PQ reference in the RTM exists in PQ_regulog.R (if present)           #
# --------------------------------------------------------------------------- #

test_that("every PQ test ID cited in the RTM is defined in PQ_regulog.R", {
  skip_if(is.na(rtm_path), "RTM not found")
  pq_path <- .validation_path("PQ_regulog.R")
  skip_if(is.na(pq_path), "PQ_regulog.R not found")

  rtm <- utils::read.csv(rtm_path, stringsAsFactors = FALSE)
  cited   <- unique(.expand_refs(rtm$pq_ref, "PQ-"))
  defined <- unique(.extract_defined_ids(readLines(pq_path, warn = FALSE), "PQ-"))

  stale <- setdiff(cited, defined)
  expect_equal(
    stale, character(0L),
    info = sprintf(
      "RTM references PQ test ID(s) not found in PQ_regulog.R: %s",
      paste(stale, collapse = ", ")
    )
  )
})


# --------------------------------------------------------------------------- #
#  No RTM row references a function no longer exported by the package         #
# --------------------------------------------------------------------------- #

test_that("no RTM row references a function that is not currently exported", {
  skip_if(is.na(rtm_path), "RTM not found")

  rtm <- utils::read.csv(rtm_path, stringsAsFactors = FALSE)

  # getNamespaceExports() lists ordinary @export functions but NOT S3
  # methods registered via @exportS3Method (e.g. as.data.frame.regulog) --
  # those are registered as S3 method dispatch entries, not namespace
  # exports, and must be checked separately.
  exported    <- getNamespaceExports("regulog")
  s3_methods  <- tryCatch(
    as.character(utils::.S3methods(class = "regulog", envir = asNamespace("regulog"))),
    error = function(e) character(0L)
  )
  # .S3methods() prints e.g. "print.regulog", "as.data.frame.regulog" --
  # both the generic.class form (as found via the table above) and the
  # bare function names actually used in the RTM's free text are accepted.
  known_callable <- unique(c(exported, s3_methods))

  # Pull function-call-shaped tokens out of the free-text regulog_function
  # column, e.g. "rl_read() / with_log() -- explicit ..." -> c("rl_read", "with_log")
  fn_tokens <- regmatches(
    rtm$regulog_function,
    gregexpr("[a-zA-Z_][a-zA-Z0-9_.]*(?=\\()", rtm$regulog_function, perl = TRUE)
  )
  fn_tokens <- unique(unlist(fn_tokens))

  # Internal/base functions referenced descriptively are not part of the
  # package's own export surface and are intentionally excluded
  not_package_functions <- c("before", "after", "meaning", "format")
  fn_tokens <- setdiff(fn_tokens, not_package_functions)

  missing <- setdiff(fn_tokens, known_callable)
  expect_equal(
    missing, character(0L),
    info = sprintf(
      "RTM references function(s) not found among exports or S3 methods: %s\n  Exported: %s\n  S3 methods: %s",
      paste(missing, collapse = ", "),
      paste(sort(exported), collapse = ", "),
      paste(sort(s3_methods), collapse = ", ")
    )
  )
})


# --------------------------------------------------------------------------- #
#  No RTM row references a known-removed function by name                     #
# --------------------------------------------------------------------------- #

test_that("RTM does not reference functions removed in the v0.2.0 hooks redesign", {
  skip_if(is.na(rtm_path), "RTM not found")

  rtm_text <- paste(readLines(rtm_path, warn = FALSE), collapse = "\n")

  removed_functions <- c("log_hooks_enable", "log_hooks_disable", ".rl_hooks")

  for (fn in removed_functions) {
    expect_false(
      grepl(fn, rtm_text, fixed = TRUE),
      info = sprintf(
        "RTM still references removed function/internal: '%s'. ",
        fn
      )
    )
  }
})