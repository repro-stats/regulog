# Export the audit trail

Serialises log entries to CSV or JSON, with optional date filtering. Use
`signed = TRUE` to run chain verification and stamp the integrity result
into the export — useful for handoffs, audits, or archival.

## Usage

``` r
export_audit_trail(
  log,
  format = c("csv", "json"),
  from = NULL,
  to = NULL,
  path = NULL,
  signed = FALSE,
  include_genesis = FALSE
)
```

## Arguments

- log:

  A `regulog` object or a path to a `.rlog` file.

- format:

  Character. `"csv"` or `"json"`.

- from:

  Character or `NULL`. Include entries on or after this date (ISO-8601,
  e.g. `"2026-01-01"`).

- to:

  Character or `NULL`. Include entries on or before this date.

- path:

  Character or `NULL`. Output file path. If `NULL`, returns the data
  without writing to disk.

- signed:

  Logical. If `TRUE`, verify the chain and include `chain_intact` and
  `verified_at` fields in the export.

- include_genesis:

  Logical. Include the genesis record. Default `FALSE`.

## Value

A data frame (CSV) or list (JSON), invisibly.

## Details

### CSV column layout

|                |                                              |
|----------------|----------------------------------------------|
| Column         | Description                                  |
| `entry_id`     | Monotone sequence number                     |
| `timestamp`    | ISO-8601 UTC                                 |
| `app`          | Application name                             |
| `app_version`  | Application version                          |
| `user`         | Acting user identity                         |
| `type`         | `ACTION` or `CHANGE`                         |
| `action`       | Action label (ACTION entries)                |
| `object`       | Target of the action or change               |
| `field`        | Field name (CHANGE entries)                  |
| `before`       | Prior value (CHANGE entries)                 |
| `after`        | New value (CHANGE entries)                   |
| `reason`       | Justification                                |
| `entry_hash`   | SHA-256 of this entry                        |
| `prev_hash`    | SHA-256 of prior entry                       |
| `chain_intact` | `TRUE/FALSE` (signed exports only)           |
| `verified_at`  | ISO-8601 UTC of export (signed exports only) |

## Examples

``` r
log <- regulog_init(app = "my-app", user = "jsmith")
log_action(log,
  action = "approved", object = "model_v3",
  reason = "Metrics passed threshold"
)
#> regulog: logged action 'approved' on 'model_v3'
df <- export_audit_trail(log, format = "csv")

if (FALSE) { # \dontrun{
export_audit_trail(log,
  format = "csv",
  from   = "2026-01-01",
  signed = TRUE,
  path   = "audit_export.csv"
)
} # }
```
