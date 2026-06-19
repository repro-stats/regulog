# Create a logging observer for a reactive Shiny input

Wraps
[`shiny::observeEvent()`](https://rdrr.io/pkg/shiny/man/observeEvent.html)
to log an action whenever `eventExpr` fires. Reduces boilerplate when
many UI events need to be audited.

## Usage

``` r
regulog_observer(log, session, eventExpr, action, object, reason, ...)
```

## Arguments

- log:

  A `regulog` object.

- session:

  The Shiny session object.

- eventExpr:

  Reactive expression to observe.

- action:

  Character. Action label.

- object:

  Character or reactive. The object acted upon.

- reason:

  Character or reactive. Business justification.

- ...:

  Additional arguments passed to
  [`log_action()`](https://repro-stats.github.io/regulog/reference/log_action.md).

## Value

A Shiny observer (invisibly).

## Examples

``` r
if (FALSE) { # \dontrun{
regulog_observer(log, session,
  eventExpr = input$approve,
  action    = "approved",
  object    = reactive(input$selected_dataset),
  reason    = reactive(input$reason_text)
)
} # }
```
