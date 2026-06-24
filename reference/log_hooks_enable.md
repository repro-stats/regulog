# Enable automatic logging of data read operations

Patches common data-reading functions so that every call is
automatically logged to `log` as an ACTION entry with
`action = "data_read"`. No changes to your analysis code are required.

## Usage

``` r
log_hooks_enable(log)
```

## Arguments

- log:

  A `regulog` object from
  [`regulog_init()`](https://reprostats.org/regulog/reference/regulog_init.md)
  or
  [`regulog_shiny_init()`](https://reprostats.org/regulog/reference/regulog_shiny_init.md).

## Value

`log`, invisibly.

## Details

**Functions patched (when the package is loaded):**
[`haven::read_sas`](https://haven.tidyverse.org/reference/read_sas.html),
[`haven::read_xpt`](https://haven.tidyverse.org/reference/read_xpt.html),
[`readr::read_csv`](https://readr.tidyverse.org/reference/read_delim.html),
`data.table::fread`,
[`utils::read.csv`](https://rdrr.io/r/utils/read.table.html),
[`utils::read.table`](https://rdrr.io/r/utils/read.table.html)

Call
[`log_hooks_disable()`](https://reprostats.org/regulog/reference/log_hooks_disable.md)
to restore originals when done. For a scoped, exception-safe
alternative, prefer
[`with_log()`](https://reprostats.org/regulog/reference/with_log.md).

## See also

[`log_hooks_disable()`](https://reprostats.org/regulog/reference/log_hooks_disable.md),
[`with_log()`](https://reprostats.org/regulog/reference/with_log.md)

## Examples

``` r
if (FALSE) { # \dontrun{
log <- regulog_init(app = "pipeline", version = "1.0", user = "ndoh.penn",
                    path = "logs/audit.rlog")

log_hooks_enable(log)

# All reads below are logged automatically -- no code change needed
adsl <- haven::read_sas("data/adsl.sas7bdat")
adae <- haven::read_sas("data/adae.sas7bdat")

log_hooks_disable()
filter_log(log, action = "data_read")
} # }
```
