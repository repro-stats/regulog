# Log a before/after field change in the audit trail

Records a data modification with both prior and new values. Use this
whenever a specific field on a record is changed and you need a full
history of what it was, what it became, and why.

## Usage

``` r
log_change(log, object, field, before, after, reason, user = log$user)
```

## Arguments

- log:

  A `regulog` object from
  [`regulog_init()`](https://repro-stats.github.io/regulog/reference/regulog_init.md).

- object:

  Character. The record being modified (e.g. `"user_42"`,
  `"config.yaml"`, `"experiment_7"`).

- field:

  Character. The field that changed (e.g. `"status"`, `"threshold"`).

- before:

  The value before the change (coerced to character).

- after:

  The value after the change (coerced to character).

- reason:

  Character. **Mandatory.** Why the change was made. No default.

- user:

  Character. Override the session user. Defaults to session user.

## Value

The `regulog` object, invisibly.

## Examples

``` r
log <- regulog_init(app = "my-app", user = "jsmith")
log_change(log,
  object = "experiment_7",
  field  = "learning_rate",
  before = "0.01",
  after  = "0.001",
  reason = "Loss diverging at 0.01 — reduced per tuning protocol"
)
#> regulog: logged change to experiment_7$learning_rate
```
