# Apply an electronic signature to the audit trail

Records a SIGNATURE entry capturing the signer identity (from the
session user), UTC timestamp, number of prior entries covered, and the
stated meaning of the signature. Addresses 21 CFR Part 11 §11.100 /
§11.200 requirements:

## Usage

``` r
log_signature(log, meaning)
```

## Arguments

- log:

  A `regulog` object returned by
  [`regulog_init()`](https://repro-stats.github.io/regulog/reference/regulog_init.md)
  or
  [`regulog_shiny_init()`](https://repro-stats.github.io/regulog/reference/regulog_shiny_init.md).

- meaning:

  The meaning of the signature — what you are certifying. Cannot be
  blank. Example:
  `"I certify that this analysis is accurate and complete per SAP version 2.0"`.

## Value

The `regulog` object, invisibly (pipe-friendly).

## Details

- **Identity** — resolved from the session user set in
  [`regulog_init()`](https://repro-stats.github.io/regulog/reference/regulog_init.md)

- **Date and time** — UTC timestamp generated automatically at call time

- **Meaning** — the `meaning` argument; mandatory, cannot be blank

- **Coverage** — number of prior entries in the session, recorded
  automatically

The SIGNATURE entry is part of the hash chain: any tampering with
entries preceding the signature, or with the signature entry itself, is
detectable by
[`verify_log()`](https://repro-stats.github.io/regulog/reference/verify_log.md).

## See also

[`log_action()`](https://repro-stats.github.io/regulog/reference/log_action.md),
[`log_note()`](https://repro-stats.github.io/regulog/reference/log_note.md),
[`verify_log()`](https://repro-stats.github.io/regulog/reference/verify_log.md)

## Examples

``` r
log <- regulog_init(app = "analysis", version = "1.0", user = "ndoh.penn")
log_action(log, "run", "primary_analysis.R",
           "Primary ANCOVA model executed per SAP section 6.1")
#> regulog: logged action 'run' on 'primary_analysis.R'

log_signature(log,
  "I certify that this analysis is accurate and complete per SAP version 2.0"
)
#> regulog: signature applied by 'ndoh.penn' covering 1 entry
```
