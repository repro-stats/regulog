# Filter audit log entries

Extracts a subset of entries from a `regulog` object or a `.rlog` file
as a plain `data.frame`. All filter arguments are optional — omitting
all returns every entry.

## Usage

``` r
filter_log(
  log,
  type = NULL,
  user = NULL,
  action = NULL,
  from = NULL,
  to = NULL
)
```

## Arguments

- log:

  A `regulog` object **or** a path to a `.rlog` file.

- type:

  Character vector of entry types to keep: `"ACTION"`, `"CHANGE"`,
  `"NOTE"`, `"SIGNATURE"`. `NULL` returns all types.

- user:

  Character vector of user identifiers to keep. `NULL` returns all
  users.

- action:

  Character vector of action values to keep (e.g. `"approved"`,
  `"data_read"`). `NULL` returns all actions.

- from:

  Start of the time window. ISO 8601 string (`"2026-06-01"`) or `Date`.
  `NULL` applies no lower bound.

- to:

  End of the time window. Same format as `from`. Inclusive. `NULL`
  applies no upper bound.

## Value

A `data.frame` of matching entries, sorted by `entry_id`. Returns a
zero-row data frame when nothing matches.

## See also

[`as.data.frame.regulog()`](https://reprostats.org/regulog/reference/as.data.frame.regulog.md),
[`export_audit_trail()`](https://reprostats.org/regulog/reference/export_audit_trail.md),
[`verify_log()`](https://reprostats.org/regulog/reference/verify_log.md)

## Examples

``` r
log <- regulog_init(app = "analysis", version = "1.0", user = "jsmith")
log_action(log,
  action = "run",
  object = "primary.R",
  reason = "Primary model fitted"
)
#> regulog: logged action 'run' on 'primary.R'
log_note(log, "Outlier in subject 042 retained per SAP")
#> regulog: note logged
log_action(log,
  action = "export",
  object = "results.csv",
  reason = "Sent to sponsor"
)
#> regulog: logged action 'export' on 'results.csv'
log_signature(log, "Analysis complete and accurate per SAP v2")
#> regulog: signature applied by 'jsmith' covering 3 entries

# All entries as a data frame
filter_log(log)
#>   entry_id                   timestamp      app app_version   user      type
#> 1        1 2026-07-01T08:44:06.298216Z analysis         1.0 jsmith    ACTION
#> 2        2 2026-07-01T08:44:06.299159Z analysis         1.0 jsmith      NOTE
#> 3        3 2026-07-01T08:44:06.299982Z analysis         1.0 jsmith    ACTION
#> 4        4 2026-07-01T08:44:06.300895Z analysis         1.0 jsmith SIGNATURE
#>      action      object           field before after
#> 1       run   primary.R            <NA>   <NA>  <NA>
#> 2      note        <NA>            <NA>   <NA>  <NA>
#> 3    export results.csv            <NA>   <NA>  <NA>
#> 4 signature      jsmith entries_covered   <NA>     3
#>                                      reason text meaning
#> 1                      Primary model fitted <NA>    <NA>
#> 2   Outlier in subject 042 retained per SAP <NA>    <NA>
#> 3                           Sent to sponsor <NA>    <NA>
#> 4 Analysis complete and accurate per SAP v2 <NA>    <NA>
#>                                                         entry_hash
#> 1 c8abfa8687c312c9d2b16cdd147901b2a9f4dd4a728d4a65823ccb5d39fc8b85
#> 2 d3b6430e40331186cebe4ec49f89c96afa65f863b24082039792d681e3bd07e9
#> 3 29e2a7b6d453d1ffa3ddda5b2cb7dde8e2bfcc3d80891a4d729254213342cda4
#> 4 62e62f9574b4247ab34f62049bcf60bde390b2c79868f19dd2aa5e66c6053eb1
#>                                                          prev_hash
#> 1 3d3386bdb06b6208c553c6e3de8d4bead88064e34f674b00312e788fb90026fa
#> 2 c8abfa8687c312c9d2b16cdd147901b2a9f4dd4a728d4a65823ccb5d39fc8b85
#> 3 d3b6430e40331186cebe4ec49f89c96afa65f863b24082039792d681e3bd07e9
#> 4 29e2a7b6d453d1ffa3ddda5b2cb7dde8e2bfcc3d80891a4d729254213342cda4

# Only signatures
filter_log(log, type = "SIGNATURE")
#>   entry_id                   timestamp      app app_version   user      type
#> 1        4 2026-07-01T08:44:06.300895Z analysis         1.0 jsmith SIGNATURE
#>      action object           field before after
#> 1 signature jsmith entries_covered   <NA>     3
#>                                      reason text meaning
#> 1 Analysis complete and accurate per SAP v2 <NA>    <NA>
#>                                                         entry_hash
#> 1 62e62f9574b4247ab34f62049bcf60bde390b2c79868f19dd2aa5e66c6053eb1
#>                                                          prev_hash
#> 1 29e2a7b6d453d1ffa3ddda5b2cb7dde8e2bfcc3d80891a4d729254213342cda4

# Actions and notes by a specific user
filter_log(log, type = c("ACTION", "NOTE"), user = "jsmith")
#>   entry_id                   timestamp      app app_version   user   type
#> 1        1 2026-07-01T08:44:06.298216Z analysis         1.0 jsmith ACTION
#> 2        2 2026-07-01T08:44:06.299159Z analysis         1.0 jsmith   NOTE
#> 3        3 2026-07-01T08:44:06.299982Z analysis         1.0 jsmith ACTION
#>   action      object field before after                                  reason
#> 1    run   primary.R  <NA>   <NA>  <NA>                    Primary model fitted
#> 2   note        <NA>  <NA>   <NA>  <NA> Outlier in subject 042 retained per SAP
#> 3 export results.csv  <NA>   <NA>  <NA>                         Sent to sponsor
#>   text meaning                                                       entry_hash
#> 1 <NA>    <NA> c8abfa8687c312c9d2b16cdd147901b2a9f4dd4a728d4a65823ccb5d39fc8b85
#> 2 <NA>    <NA> d3b6430e40331186cebe4ec49f89c96afa65f863b24082039792d681e3bd07e9
#> 3 <NA>    <NA> 29e2a7b6d453d1ffa3ddda5b2cb7dde8e2bfcc3d80891a4d729254213342cda4
#>                                                          prev_hash
#> 1 3d3386bdb06b6208c553c6e3de8d4bead88064e34f674b00312e788fb90026fa
#> 2 c8abfa8687c312c9d2b16cdd147901b2a9f4dd4a728d4a65823ccb5d39fc8b85
#> 3 d3b6430e40331186cebe4ec49f89c96afa65f863b24082039792d681e3bd07e9

# Entries within a date range
filter_log(log, from = "2026-06-01", to = "2026-12-31")
#>   entry_id                   timestamp      app app_version   user      type
#> 1        1 2026-07-01T08:44:06.298216Z analysis         1.0 jsmith    ACTION
#> 2        2 2026-07-01T08:44:06.299159Z analysis         1.0 jsmith      NOTE
#> 3        3 2026-07-01T08:44:06.299982Z analysis         1.0 jsmith    ACTION
#> 4        4 2026-07-01T08:44:06.300895Z analysis         1.0 jsmith SIGNATURE
#>      action      object           field before after
#> 1       run   primary.R            <NA>   <NA>  <NA>
#> 2      note        <NA>            <NA>   <NA>  <NA>
#> 3    export results.csv            <NA>   <NA>  <NA>
#> 4 signature      jsmith entries_covered   <NA>     3
#>                                      reason text meaning
#> 1                      Primary model fitted <NA>    <NA>
#> 2   Outlier in subject 042 retained per SAP <NA>    <NA>
#> 3                           Sent to sponsor <NA>    <NA>
#> 4 Analysis complete and accurate per SAP v2 <NA>    <NA>
#>                                                         entry_hash
#> 1 c8abfa8687c312c9d2b16cdd147901b2a9f4dd4a728d4a65823ccb5d39fc8b85
#> 2 d3b6430e40331186cebe4ec49f89c96afa65f863b24082039792d681e3bd07e9
#> 3 29e2a7b6d453d1ffa3ddda5b2cb7dde8e2bfcc3d80891a4d729254213342cda4
#> 4 62e62f9574b4247ab34f62049bcf60bde390b2c79868f19dd2aa5e66c6053eb1
#>                                                          prev_hash
#> 1 3d3386bdb06b6208c553c6e3de8d4bead88064e34f674b00312e788fb90026fa
#> 2 c8abfa8687c312c9d2b16cdd147901b2a9f4dd4a728d4a65823ccb5d39fc8b85
#> 3 d3b6430e40331186cebe4ec49f89c96afa65f863b24082039792d681e3bd07e9
#> 4 29e2a7b6d453d1ffa3ddda5b2cb7dde8e2bfcc3d80891a4d729254213342cda4

# Works directly on a .rlog file — no live session needed
if (FALSE) { # \dontrun{
filter_log("logs/audit.rlog", type = "SIGNATURE")
} # }
```
