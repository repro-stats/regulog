# Initialise a regulog audit log session

Creates a new audit log session object. Subsequent calls to
[`log_action()`](https://repro-stats.github.io/regulog/reference/log_action.md)
and
[`log_change()`](https://repro-stats.github.io/regulog/reference/log_change.md)
append hash-chained entries. If `path` is supplied, entries are written
to a newline-delimited JSON file (`.rlog`).

## Usage

``` r
regulog_init(
  app,
  version = "unknown",
  user = Sys.info()[["user"]],
  path = NULL,
  hash_algo = "sha256"
)
```

## Arguments

- app:

  Character. Application or system name (e.g. `"data-pipeline"`,
  `"review-tool"`, `"ml-trainer"`).

- version:

  Character. Application version string.

- user:

  Character. Identity of the acting user. Defaults to
  `Sys.info()[["user"]]`. In Shiny, pass `session$user`.

- path:

  Character or `NULL`. Path for persistent storage. If `NULL`, the log
  is in-memory only (suitable for development / testing).

- hash_algo:

  Character. Algorithm passed to
  [`digest::digest()`](https://eddelbuettel.github.io/digest/man/digest.html).
  Defaults to `"sha256"`. Do not change once a log file is in use.

## Value

An S3 object of class `"regulog"` (an environment).

## Details

### Entry structure

Every entry written to disk is a JSON object on a single line:

    {
      "entry_id":    1,
      "timestamp":   "2026-06-18T14:32:01.123456Z",
      "app":         "my-app",
      "app_version": "1.0.0",
      "user":        "jsmith",
      "action":      "approved",
      "object":      "model_v3",
      "reason":      "Validation metrics passed threshold",
      "prev_hash":   "e3b0c44298fc1c149afb...",
      "entry_hash":  "a87ff679a2f3e71d9181..."
    }

The flat structure is intentional: the log should be inspectable with a
text editor, without any specialist software.

### Hash chain

Each `entry_hash` is SHA-256 of a canonical string encoding all fields
plus `prev_hash`. Altering any field — including the timestamp or reason
— invalidates the hash and all subsequent chain links, detectable by
[`verify_log()`](https://repro-stats.github.io/regulog/reference/verify_log.md).

### What the chain captures

|  |  |
|----|----|
| Property | Implementation |
| Who acted | `user` field on every entry |
| What happened | `action` + `object` fields |
| When | ISO-8601 UTC timestamp, microsecond resolution |
| Why | Mandatory `reason` — no default |
| What changed | `before`/`after` in [`log_change()`](https://repro-stats.github.io/regulog/reference/log_change.md) |
| Tamper evidence | SHA-256 hash chain; verified by [`verify_log()`](https://repro-stats.github.io/regulog/reference/verify_log.md) |
| Portable export | [`export_audit_trail()`](https://repro-stats.github.io/regulog/reference/export_audit_trail.md) to CSV or JSON |

## Examples

``` r
log <- regulog_init(
  app     = "my-app",
  version = "1.0.0",
  user    = "jsmith"
)
log
#> <regulog>
#>   App:     my-app v1.0.0
#>   User:    jsmith
#>   Entries: 0
#>   Path:    (in-memory only)
```
