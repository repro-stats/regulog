# read.R
# Logging of data read operations via explicit call-site wrapping.
#
# rl_read(log, fn, ..., reader = NULL) -- explicit wrapper, any read function
# with_log(log, expr)                  -- scoped convenience: read() calls
#                                          inside `expr` resolve to `log`
#                                          automatically via a local binding
#
# The active `log` is threaded explicitly through lexical scope (a closure
# created per with_log() call), not through shared package state. This
# means concurrent with_log() calls -- e.g. across different Shiny sessions
# -- never interfere with each other.
#
# The file/path argument is resolved by name first (file, path, data_file,
# input), falling back to the first unnamed argument. This avoids recording
# the wrong value when arguments are supplied out of position.


# --------------------------------------------------------------------------- #
#  rl_read — explicit, safe wrapper for any read function                      #
# --------------------------------------------------------------------------- #

#' Log a data read operation
#'
#' Calls `reader` with `...`, then records the call as a `data_read` ACTION
#' entry. Unlike namespace patching, `rl_read()` wraps the call explicitly —
#' no package internals are modified, and behaviour is identical whether
#' called from a single script or concurrently across multiple Shiny
#' sessions.
#'
#' @param log A `regulog` object from [regulog_init()] or [regulog_shiny_init()].
#' @param reader A function that reads data, e.g. `haven::read_sas`,
#'   `readr::read_csv`, `data.table::fread`, `utils::read.csv`.
#' @param ... Arguments passed to `reader`.
#'
#' @return The result of calling `reader(...)`.
#'
#' @details
#' The path/file recorded in the audit entry is resolved as follows:
#' 1. A named argument in `...` called `file`, `path`, or `data_file`.
#' 2. The first unnamed argument in `...`, if any.
#' 3. `"unknown"`, if neither is found.
#'
#' This avoids the failure mode of positional-only extraction, where a
#' reordered named call (e.g. `read_csv(col_types = "ccd", file = "x.csv")`)
#' would otherwise record the wrong value.
#'
#' @examples
#' log <- regulog_init(app = "pipeline", version = "1.0", user = "jsmith")
#'
#' \dontrun{
#' adsl <- rl_read(log, haven::read_sas, "data/adsl.sas7bdat")
#' adae <- rl_read(log, readr::read_csv, file = "data/adae.csv")
#' }
#'
#' @seealso [with_log()]
#' @export
rl_read <- function(log, reader, ...) {
  .assert_regulog(log)
  if (!is.function(reader)) stop("`reader` must be a function.")

  # Capture the unevaluated expression at this call site -- e.g.
  # "utils::read.csv" or "haven::read_sas" -- before `reader` is reduced
  # to a plain function value. substitute() only recovers this from the
  # promise as originally passed; it cannot be reconstructed later from
  # the evaluated function object alone.
  reader_label <- .label_reader(substitute(reader))

  .rl_read_impl(log, reader, reader_label, ...)
}

#' Internal: shared read-and-log logic
#'
#' Both [rl_read()] and the `read()` closure inside [with_log()] capture
#' their own `substitute(reader)` label at their respective call sites
#' (the only place that expression is recoverable), then delegate the
#' actual read-and-log work here.
#' @noRd
.rl_read_impl <- function(log, reader, reader_label, ...) {
  args <- list(...)
  path <- .resolve_read_path(args)

  result <- reader(...)

  n_row <- if (is.data.frame(result)) nrow(result) else NA_integer_
  n_col <- if (is.data.frame(result)) ncol(result) else NA_integer_

  detail <- if (!is.na(n_row)) {
    sprintf("%s(\"%s\") \u2014 %d rows, %d cols", reader_label, path, n_row, n_col)
  } else {
    sprintf("%s(\"%s\")", reader_label, path)
  }

  entry <- .build_entry(
    log    = log,
    type   = "ACTION",
    user   = log$user,
    fields = list(action = "data_read", object = path, reason = detail)
  )
  .commit(log, entry)

  result
}


# --------------------------------------------------------------------------- #
#  with_log — scoped convenience wrapper                                       #
# --------------------------------------------------------------------------- #

#' Run an expression with automatic data read logging
#'
#' Evaluates `expr` with a local `read()` binding tied to `log`, so calls
#' inside the block don't need to repeat the `log` argument. Reads must use
#' `read()` explicitly inside the block; calling a reader function directly
#' (e.g. bare `haven::read_sas(...)`) is not logged. This keeps logging
#' coverage unambiguous: every logged read is visible at the call site, and
#' there are no implicit gaps.
#'
#' @param log A `regulog` object.
#' @param expr An expression, typically a `{}` block. Inside the block,
#'   `read(reader, ...)` is available and logs to `log` automatically.
#'
#' @return The value of `expr`, invisibly.
#'
#' @examples
#' log <- regulog_init(app = "pipeline", version = "1.0", user = "jsmith")
#'
#' \dontrun{
#' with_log(log, {
#'   adsl <- read(haven::read_sas, "data/adsl.sas7bdat")
#'   adae <- read(haven::read_sas, "data/adae.sas7bdat")
#' })
#'
#' filter_log(log, action = "data_read")
#' }
#'
#' @seealso [rl_read()]
#' @export
with_log <- function(log, expr) {
  .assert_regulog(log)

  # Local `read()` binding, visible only inside the evaluated expression.
  # Captures `log` by lexical scope -- no shared/global state involved,
  # so concurrent with_log() calls across sessions never interfere.
  # The reader label is captured via substitute() here, at this closure's
  # own call site -- the same fix applied in rl_read() -- so calls like
  # read(haven::read_sas, ...) inside the block log a real label instead
  # of the generic "<reader>" placeholder.
  read <- function(reader, ...) {
    reader_label <- .label_reader(substitute(reader))
    .rl_read_impl(log, reader, reader_label, ...)
  }

  parent_env <- parent.frame()
  eval_env <- new.env(parent = parent_env)
  eval_env$read <- read

  invisible(eval(substitute(expr), envir = eval_env))
}


# --------------------------------------------------------------------------- #
#  Internal helpers                                                            #
# --------------------------------------------------------------------------- #

#' @noRd
.resolve_read_path <- function(args) {
  nm <- names(args)

  if (!is.null(nm)) {
    for (candidate in c("file", "path", "data_file", "input")) {
      hit <- which(nm == candidate)
      if (length(hit) == 1L) return(as.character(args[[hit]]))
    }
  }

  # Fall back to the first unnamed argument
  if (is.null(nm)) {
    unnamed_idx <- seq_along(args)
  } else {
    unnamed_idx <- which(nm == "" | is.na(nm))
  }

  if (length(unnamed_idx) >= 1L) {
    return(as.character(args[[unnamed_idx[[1L]]]]))
  }

  "unknown"
}

#' Deparse a captured reader expression into a human-readable label
#'
#' Takes the unevaluated expression for the `reader` argument -- as captured
#' by `substitute(reader)` at the `rl_read()` call site -- and deparses it
#' to a label such as `"utils::read.csv"` or `"haven::read_sas"`. This must
#' be called with the substituted expression, not a plain function value:
#' by the time a function is just a value, R has no way to recover the
#' name or namespace it was originally referenced by.
#' @noRd
.label_reader <- function(reader_expr) {
  label <- tryCatch(deparse(reader_expr), error = function(e) NULL)

  if (is.null(label) || !nzchar(label) || length(label) != 1L) {
    return("<reader>")
  }

  # A bare symbol naming an anonymous/local function (e.g. a function
  # built with `function(...) ...` passed directly) deparses to something
  # spanning multiple lines or containing "function(" -- not a useful label
  if (grepl("^function", label) || grepl("\\(", label) == FALSE && label == "reader") {
    return("<reader>")
  }

  label
}