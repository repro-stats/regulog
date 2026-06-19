# shiny.R
# Shiny integration for regulog.
#
# API follows the project spec: regulog_shiny_init() is called *inside* the
# server function, not as a wrapper around it. This is more idiomatic Shiny
# and avoids hiding the server signature from tools like shinytest2.
#
# The log is returned as a regular R object; callers store it as they see fit
# (reactive value, local variable, or session$userData).


#' Initialise a regulog session inside a Shiny server
#'
#' A thin wrapper around [regulog_init()] that resolves the authenticated user
#' from `session$user` (set by Shiny Server Pro / Posit Connect) and
#' automatically logs `session_start` and `session_end` events.
#'
#' @param session The Shiny `session` object.
#' @param app Character. Application name.
#' @param version Character. Application version.
#' @param path Character or `NULL`. Persistent log file path. When `NULL`,
#'   a per-session temp file is created (suitable for development only —
#'   logs will be lost when the session ends).
#' @param hash_algo Character. Hashing algorithm. Defaults to `"sha256"`.
#'
#' @return A `regulog` object with the log tied to the authenticated session
#'   user.
#'
#' @details
#' ## User resolution
#' `session$user` is the authenticated identity set by Shiny Server Pro or
#' Posit Connect. In open deployments where authentication is not configured,
#' this will be `NULL` or `""`. `regulog_shiny_init()` falls back to
#' `Sys.info()[["user"]]` in that case, with a warning.
#'
#' ## Session instrumentation
#' Two entries are added automatically:
#' - `session_start` when `regulog_shiny_init()` is called
#' - `session_end` via `shiny::onSessionEnded()`
#'
#' These bracket all user-driven entries, giving regulators a complete
#' picture of each session lifecycle.
#'
#' ## Recommended pattern
#' ```r
#' server <- function(input, output, session) {
#'
#'   log <- regulog_shiny_init(
#'     session = session,
#'     app     = "my-app",
#'     version = "1.2.0",
#'     path    = "/logs/audit.rlog"
#'   )
#'
#'   observeEvent(input$approve, {
#'     log_action(log,
#'       action = "approved",
#'       object = input$dataset,
#'       reason = input$reason
#'     )
#'   })
#' }
#' ```
#'
#' @examples
#' \dontrun{
#' library(shiny)
#' library(regulog)
#'
#' server <- function(input, output, session) {
#'   log <- regulog_shiny_init(
#'     session = session,
#'     app     = "my-app",
#'     version = "1.0.0",
#'     path    = "logs/audit.rlog"
#'   )
#'   observeEvent(input$submit, {
#'     log_action(log,
#'       action = "submitted",
#'       object = input$form_id,
#'       reason = input$justification
#'     )
#'   })
#' }
#'
#' shinyApp(ui = fluidPage(), server = server)
#' }
#'
#' @export
regulog_shiny_init <- function(session,
                                app,
                                version   = "unknown",
                                path      = NULL,
                                hash_algo = "sha256") {

  .require_shiny()

  # Resolve authenticated user
  user <- .resolve_shiny_user(session)

  # Default to a per-session temp file if no path given
  resolved_path <- path %||% tempfile(
    pattern = paste0("regulog_", gsub("[^a-zA-Z0-9]", "_", app), "_"),
    fileext = ".rlog"
  )

  if (is.null(path)) {
    warning(
      "regulog_shiny_init(): no `path` supplied. ",
      "Using a temporary file — log will not persist after session ends.\n",
      "  Temp path: ", resolved_path,
      call. = FALSE
    )
  }

  log <- regulog_init(
    app       = app,
    version   = version,
    user      = user,
    path      = resolved_path,
    hash_algo = hash_algo
  )

  # Log session lifecycle events
  log_action(log,
    action = "session_start",
    object = session$token,
    reason = "Shiny session opened"
  )

  shiny::onSessionEnded(function() {
    log_action(log,
      action = "session_end",
      object = session$token,
      reason = "Shiny session closed"
    )
  })

  log
}


#' Create a logging observer for a reactive Shiny input
#'
#' Wraps `shiny::observeEvent()` to log an action whenever `eventExpr` fires.
#' Reduces boilerplate when many UI events need to be audited.
#'
#' @param log A `regulog` object.
#' @param session The Shiny session object.
#' @param eventExpr Reactive expression to observe.
#' @param action Character. Action label.
#' @param object Character or reactive. The object acted upon.
#' @param reason Character or reactive. Business justification.
#' @param ... Additional arguments passed to [log_action()].
#'
#' @return A Shiny observer (invisibly).
#'
#' @examples
#' \dontrun{
#' regulog_observer(log, session,
#'   eventExpr = input$approve,
#'   action    = "approved",
#'   object    = reactive(input$selected_dataset),
#'   reason    = reactive(input$reason_text)
#' )
#' }
#'
#' @export
regulog_observer <- function(log, session, eventExpr, action, object, reason, ...) {
  .require_shiny()

  shiny::observeEvent(eventExpr, {
    obj <- if (shiny::is.reactive(object)) object() else object
    rsn <- if (shiny::is.reactive(reason)) reason() else reason
    log_action(log, action = action, object = obj, reason = rsn, ...)
  })
}


# --------------------------------------------------------------------------- #
#  Internal                                                                     #
# --------------------------------------------------------------------------- #

.require_shiny <- function() {
  if (!requireNamespace("shiny", quietly = TRUE)) {
    stop(
      "Package 'shiny' is required for Shiny integration.\n",
      "  Install it with: install.packages(\"shiny\")"
    )
  }
}

.resolve_shiny_user <- function(session) {
  user <- tryCatch(session$user, error = function(e) NULL)

  if (is.null(user) || !nzchar(user)) {
    user <- Sys.info()[["user"]]
    warning(
      "regulog_shiny_init(): session$user is NULL or empty. ",
      "Falling back to system user '", user, "'.\n",
      "  In production, ensure Shiny Server Pro or Posit Connect authentication is configured.",
      call. = FALSE
    )
  }

  user
}

`%||%` <- function(x, y) if (is.null(x)) y else x
