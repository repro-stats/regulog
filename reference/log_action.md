# Log a discrete action in the audit trail

Records a user action (approval, rejection, sign-off, deployment,
export, etc.) as a tamper-evident, hash-chained entry in the audit log.

## Usage

``` r
log_action(log, action, object, reason, user = log$user)
```

## Arguments

- log:

  A `regulog` object from
  [`regulog_init()`](https://repro-stats.github.io/regulog/reference/regulog_init.md).

- action:

  Character. What happened (e.g. `"approved"`, `"deployed"`,
  `"rejected"`, `"exported"`).

- object:

  Character. What it happened to (filename, model ID, record ID,
  pipeline step, etc.).

- reason:

  Character. **Mandatory.** Why it happened. No default.

- user:

  Character. Override the session user for this entry. Defaults to the
  user set at
  [`regulog_init()`](https://repro-stats.github.io/regulog/reference/regulog_init.md).

## Value

The `regulog` object, invisibly (pipe-friendly).

## Examples

``` r
log <- regulog_init(app = "my-app", user = "jsmith")
log_action(log,
  action = "approved",
  object = "model_v3",
  reason = "Validation metrics passed agreed threshold"
)
#> regulog: logged action 'approved' on 'model_v3'
```
