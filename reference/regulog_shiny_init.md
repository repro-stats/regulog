# Initialise a regulog session inside a Shiny server

A thin wrapper around
[`regulog_init()`](https://repro-stats.github.io/regulog/reference/regulog_init.md)
that resolves the authenticated user from `session$user` (set by Shiny
Server Pro / Posit Connect) and automatically logs `session_start` and
`session_end` events.

## Usage

``` r
regulog_shiny_init(
  session,
  app,
  version = "unknown",
  path = NULL,
  hash_algo = "sha256"
)
```

## Arguments

- session:

  The Shiny `session` object.

- app:

  Character. Application name.

- version:

  Character. Application version.

- path:

  Character or `NULL`. Persistent log file path. When `NULL`, a
  per-session temp file is created (suitable for development only; logs
  will be lost when the session ends).

- hash_algo:

  Character. Hashing algorithm. Defaults to `"sha256"`.

## Value

A `regulog` object with the log tied to the authenticated session user.

## Details

### User resolution

`session$user` is the authenticated identity set by Shiny Server Pro or
Posit Connect. In open deployments where authentication is not
configured, this will be `NULL` or `""`. `regulog_shiny_init()` falls
back to `Sys.info()[["user"]]` in that case, with a warning.

### Session instrumentation

Two entries are added automatically:

- `session_start` when `regulog_shiny_init()` is called

- `session_end` via
  [`shiny::onSessionEnded()`](https://rdrr.io/pkg/shiny/man/onFlush.html)

These bracket all user-driven entries, giving regulators a complete
picture of each session lifecycle.

### Recommended pattern

    server <- function(input, output, session) {

      log <- regulog_shiny_init(
        session = session,
        app     = "my-app",
        version = "1.2.0",
        path    = "/logs/audit.rlog"
      )

      observeEvent(input$approve, {
        log_action(log,
          action = "approved",
          object = input$dataset,
          reason = input$reason
        )
      })
    }

## Examples

``` r
if (FALSE) { # \dontrun{
library(shiny)
library(regulog)

server <- function(input, output, session) {
  log <- regulog_shiny_init(
    session = session,
    app     = "my-app",
    version = "1.0.0",
    path    = "logs/audit.rlog"
  )
  observeEvent(input$submit, {
    log_action(log,
      action = "submitted",
      object = input$form_id,
      reason = input$justification
    )
  })
}

shinyApp(ui = fluidPage(), server = server)
} # }
```
