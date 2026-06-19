# Shiny integration

## Overview

`regulog` integrates with Shiny via
[`regulog_shiny_init()`](https://repro-stats.github.io/regulog/reference/regulog_shiny_init.md),
which:

- Resolves the **authenticated user** from `session$user` (set by Shiny
  Server Pro or Posit Connect) — not a self-reported name
- Automatically logs `session_start` and `session_end` events
- Returns a standard `regulog` object you use with the usual
  [`log_action()`](https://repro-stats.github.io/regulog/reference/log_action.md)
  /
  [`log_change()`](https://repro-stats.github.io/regulog/reference/log_change.md)
  API

## Basic pattern

``` r
library(shiny)
library(regulog)

server <- function(input, output, session) {

  log <- regulog_shiny_init(
    session = session,
    app     = "clinical-review-tool",
    version = "1.2.0",
    path    = "logs/audit.rlog"   # shared log file; consider per-session paths
  )

  observeEvent(input$approve, {
    log_action(log,
      action = "approved",
      object = input$selected_dataset,
      reason = input$approval_reason
    )
  })

  observeEvent(input$reject, {
    log_action(log,
      action = "rejected",
      object = input$selected_dataset,
      reason = input$rejection_reason
    )
  })
}

shinyApp(ui = fluidPage(/* ... */), server = server)
```

## User resolution

`session$user` is the authenticated identity provided by:

- **Shiny Server Pro** — the OS or PAM-authenticated user
- **Posit Connect** — the Connect account username

In development (plain
[`shiny::runApp()`](https://rdrr.io/pkg/shiny/man/runApp.html)),
`session$user` is typically `NULL`.
[`regulog_shiny_init()`](https://repro-stats.github.io/regulog/reference/regulog_shiny_init.md)
warns and falls back to `Sys.info()[["user"]]`.

    Warning: regulog_shiny_init(): session$user is NULL or empty.
      Falling back to system user 'jsmith'.
      In production, ensure Shiny Server Pro or Posit Connect authentication is configured.

Do not deploy to a regulated context without authentication configured.

## Per-session vs shared log files

### Shared log file (simpler, suitable for low-volume apps)

``` r

log <- regulog_shiny_init(
  session = session,
  app     = "my-app",
  version = "1.0.0",
  path    = "/opt/logs/my_app_audit.rlog"  # all sessions write to one file
)
```

All sessions append to the same `.rlog` file. The NDJSON append-only
format makes this safe for concurrent writes on most file systems, but
for high-concurrency apps consider per-session files.

### Per-session log files (recommended for multi-user production)

``` r

log <- regulog_shiny_init(
  session = session,
  app     = "my-app",
  version = "1.0.0",
  path    = sprintf("/opt/logs/my_app_%s_%s.rlog",
                    format(Sys.time(), "%Y%m%d_%H%M%S"),
                    session$token)
)
```

Each session gets its own file, eliminating any concurrency concern.

## Session lifecycle entries

[`regulog_shiny_init()`](https://repro-stats.github.io/regulog/reference/regulog_shiny_init.md)
automatically adds two entries:

    {"entry_id":1, ..., "type":"ACTION", "action":"session_start", "object":"<token>", "reason":"Shiny session opened", ...}
    {"entry_id":N, ..., "type":"ACTION", "action":"session_end",   "object":"<token>", "reason":"Shiny session closed", ...}

These bracket all user-driven entries, giving auditors a complete view
of each session.

## Using regulog_observer()

For apps with many loggable inputs,
[`regulog_observer()`](https://repro-stats.github.io/regulog/reference/regulog_observer.md)
reduces boilerplate:

``` r

server <- function(input, output, session) {

  log <- regulog_shiny_init(session = session, app = "my-app", version = "1.0")

  # Instead of writing observeEvent + log_action manually for each input:
  regulog_observer(log, session,
    eventExpr = input$approve,
    action    = "approved",
    object    = reactive(input$dataset_name),
    reason    = reactive(input$justification)
  )

  regulog_observer(log, session,
    eventExpr = input$lock_db,
    action    = "database_locked",
    object    = reactive(input$study_id),
    reason    = reactive(input$lock_reason)
  )
}
```

`object` and `reason` accept either a fixed string or a
[`reactive()`](https://rdrr.io/pkg/shiny/man/reactive.html).

## Logging data changes from Shiny

When the user edits a value through the UI, capture before and after:

``` r

# Store the pre-edit value reactively
original_dob <- reactiveVal(NULL)

observeEvent(input$patient_selected, {
  # Fetch current value from database
  original_dob(get_patient_dob(input$patient_id))
})

observeEvent(input$save_edit, {
  log_change(log,
    object = paste0("patient_", input$patient_id),
    field  = "dob",
    before = original_dob(),
    after  = input$new_dob,
    reason = input$edit_reason
  )
  # Then write to database...
})
```

## Exporting from a Shiny app

Add a download handler to allow authorised users to export the audit
trail:

``` r

output$download_audit <- downloadHandler(
  filename = function() {
    sprintf("audit_%s_%s.csv", app_name, format(Sys.time(), "%Y%m%d"))
  },
  content = function(file) {
    export_audit_trail(log,
      format = "csv",
      signed = TRUE,
      path   = file
    )
  }
)
```

## Checking integrity on demand

``` r

observeEvent(input$verify_log, {
  result <- verify_log(log, verbose = FALSE)
  if (result$intact) {
    showNotification("Audit log intact.", type = "message")
  } else {
    showNotification(
      paste("Log integrity FAILED. First broken entry:", result$first_broken),
      type = "error"
    )
  }
})
```
