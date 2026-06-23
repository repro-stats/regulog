# hooks.R
# Automatic logging of data read operations via function patching.
#
# log_hooks_enable(log) -- patches haven/readr/data.table/utils read functions
# log_hooks_disable()   -- restores all originals
# with_log(log, expr)   -- scoped version; guaranteed cleanup via on.exit()
#
# Patched functions: haven::read_sas, haven::read_xpt, readr::read_csv,
#                    data.table::fread, utils::read.csv, utils::read.table
#
# Only namespaces already loaded are patched; missing packages are skipped.
# The active log and originals are stored in .rl_hooks (package environment).

#' @importFrom utils assignInNamespace

# Package-level environment -- never exported
.rl_hooks <- new.env(parent = emptyenv())
.rl_hooks$log       <- NULL   # active regulog object while hooks are live
.rl_hooks$originals <- list() # original functions keyed by "ns::fn"


# --------------------------------------------------------------------------- #
#  log_hooks_enable                                                            #
# --------------------------------------------------------------------------- #

#' Enable automatic logging of data read operations
#'
#' Patches common data-reading functions so that every call is automatically
#' logged to `log` as an ACTION entry with `action = "data_read"`. No changes
#' to your analysis code are required.
#'
#' **Functions patched (when the package is loaded):**
#' `haven::read_sas`, `haven::read_xpt`, `readr::read_csv`,
#' `data.table::fread`, `utils::read.csv`, `utils::read.table`
#'
#' Call [log_hooks_disable()] to restore originals when done.
#' For a scoped, exception-safe alternative, prefer [with_log()].
#'
#' @param log A `regulog` object from [regulog_init()] or [regulog_shiny_init()].
#'
#' @return `log`, invisibly.
#'
#' @examples
#' \dontrun{
#' log <- regulog_init(app = "pipeline", version = "1.0", user = "ndoh.penn",
#'                     path = "logs/audit.rlog")
#'
#' log_hooks_enable(log)
#'
#' # All reads below are logged automatically -- no code change needed
#' adsl <- haven::read_sas("data/adsl.sas7bdat")
#' adae <- haven::read_sas("data/adae.sas7bdat")
#'
#' log_hooks_disable()
#' filter_log(log, action = "data_read")
#' }
#'
#' @seealso [log_hooks_disable()], [with_log()]
#' @export
log_hooks_enable <- function(log) {
  .assert_regulog(log)

  if (!is.null(.rl_hooks$log)) {
    message("regulog: hooks already active. Call log_hooks_disable() first to reset.")
    return(invisible(log))
  }

  .rl_hooks$log <- log

  # Each target: namespace, function name, position of the file/path argument
  targets <- list(
    list(ns = "haven",      fn = "read_sas",   file_pos = 1L),
    list(ns = "haven",      fn = "read_xpt",   file_pos = 1L),
    list(ns = "readr",      fn = "read_csv",   file_pos = 1L),
    list(ns = "data.table", fn = "fread",      file_pos = 1L),
    list(ns = "utils",      fn = "read.csv",   file_pos = 1L),
    list(ns = "utils",      fn = "read.table", file_pos = 1L)
  )

  for (t in targets) {
    if (!isNamespaceLoaded(t$ns)) next

    key      <- paste0(t$ns, "::", t$fn)
    original <- get(t$fn, envir = asNamespace(t$ns))
    .rl_hooks$originals[[key]] <- original

    local({
      orig     <- original
      ns_name  <- t$ns
      fn_name  <- t$fn
      file_pos <- t$file_pos

      wrapper <- function(...) {
        result <- orig(...)

        if (!is.null(.rl_hooks$log)) {
          args   <- list(...)
          path   <- if (length(args) >= file_pos) as.character(args[[file_pos]]) else "unknown"
          n_row  <- if (is.data.frame(result)) nrow(result) else NA_integer_
          n_col  <- if (is.data.frame(result)) ncol(result) else NA_integer_
          detail <- if (!is.na(n_row)) {
            sprintf("%s::%s(\"%s\") \u2014 %d rows, %d cols",
                    ns_name, fn_name, path, n_row, n_col)
          } else {
            sprintf("%s::%s(\"%s\")", ns_name, fn_name, path)
          }

          entry <- .build_entry(
            log    = .rl_hooks$log,
            type   = "ACTION",
            user   = .rl_hooks$log$user,
            fields = list(
              action = "data_read",
              object = path,
              reason = detail
            )
          )
          .commit(.rl_hooks$log, entry)
        }

        result
      }

      tryCatch(
        assignInNamespace(fn_name, wrapper, ns = ns_name),
        error = function(e) {
          message(sprintf("regulog: could not patch %s \u2014 %s",
                          key, conditionMessage(e)))
          .rl_hooks$originals[[key]] <- NULL
        }
      )
    })
  }

  n_patched <- sum(!vapply(.rl_hooks$originals, is.null, logical(1L)))
  message(sprintf("regulog: hooks enabled (%d function(s) patched)", n_patched))
  invisible(log)
}


# --------------------------------------------------------------------------- #
#  log_hooks_disable                                                           #
# --------------------------------------------------------------------------- #

#' Disable automatic data I/O logging hooks
#'
#' Restores all functions patched by [log_hooks_enable()] to their originals.
#' Safe to call even if hooks were never enabled.
#'
#' @return Invisibly `NULL`.
#'
#' @examples
#' \dontrun{
#' log_hooks_disable()
#' }
#'
#' @seealso [log_hooks_enable()], [with_log()]
#' @export
log_hooks_disable <- function() {
  for (key in names(.rl_hooks$originals)) {
    orig <- .rl_hooks$originals[[key]]
    if (is.null(orig)) next

    parts   <- strsplit(key, "::", fixed = TRUE)[[1L]]
    ns_name <- parts[[1L]]
    fn_name <- parts[[2L]]

    tryCatch(
      assignInNamespace(fn_name, orig, ns = ns_name),
      error = function(e) {
        message(sprintf("regulog: could not restore %s \u2014 %s",
                        key, conditionMessage(e)))
      }
    )
  }

  n_restored <- length(.rl_hooks$originals)
  .rl_hooks$log       <- NULL
  .rl_hooks$originals <- list()

  if (n_restored > 0L) {
    message(sprintf("regulog: hooks disabled (%d function(s) restored)", n_restored))
  }
  invisible(NULL)
}


# --------------------------------------------------------------------------- #
#  with_log                                                                    #
# --------------------------------------------------------------------------- #

#' Run an expression with automatic data I/O logging
#'
#' Enables hooks for the duration of `expr` and guarantees they are disabled
#' on exit -- whether the expression completes normally, errors, or is
#' interrupted. The recommended way to scope automatic logging to a block of
#' analysis code.
#'
#' @param log A `regulog` object.
#' @param expr An R expression. Curly-brace blocks work as expected.
#'
#' @return The value of `expr`, invisibly.
#'
#' @examples
#' \dontrun{
#' log <- regulog_init(app = "pipeline", version = "1.0", user = "ndoh.penn",
#'                     path = "logs/audit.rlog")
#'
#' with_log(log, {
#'   adsl <- haven::read_sas("data/adsl.sas7bdat")
#'   adae <- haven::read_sas("data/adae.sas7bdat")
#' })
#'
#' # Hooks are always restored, even on error
#' filter_log(log, action = "data_read")
#' }
#'
#' @seealso [log_hooks_enable()], [log_hooks_disable()]
#' @export
with_log <- function(log, expr) {
  log_hooks_enable(log)
  on.exit(log_hooks_disable(), add = TRUE)
  invisible(force(expr))
}