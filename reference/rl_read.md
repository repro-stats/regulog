# Log a data read operation

Calls `reader` with `...`, then records the call as a `data_read` ACTION
entry. Unlike namespace patching, `rl_read()` wraps the call explicitly
— no package internals are modified, and behaviour is identical whether
called from a single script or concurrently across multiple Shiny
sessions.

## Usage

``` r
rl_read(log, reader, ...)
```

## Arguments

- log:

  A `regulog` object from
  [`regulog_init()`](https://reprostats.org/regulog/reference/regulog_init.md)
  or
  [`regulog_shiny_init()`](https://reprostats.org/regulog/reference/regulog_shiny_init.md).

- reader:

  A function that reads data, e.g.
  [`haven::read_sas`](https://haven.tidyverse.org/reference/read_sas.html),
  [`readr::read_csv`](https://readr.tidyverse.org/reference/read_delim.html),
  `data.table::fread`,
  [`utils::read.csv`](https://rdrr.io/r/utils/read.table.html).

- ...:

  Arguments passed to `reader`.

## Value

The result of calling `reader(...)`.

## Details

The path/file recorded in the audit entry is resolved as follows:

1.  A named argument in `...` called `file`, `path`, or `data_file`.

2.  The first unnamed argument in `...`, if any.

3.  `"unknown"`, if neither is found.

This avoids the failure mode of positional-only extraction, where a
reordered named call (e.g.
`read_csv(col_types = "ccd", file = "x.csv")`) would otherwise record
the wrong value.

## See also

[`with_log()`](https://reprostats.org/regulog/reference/with_log.md)

## Examples

``` r
log <- regulog_init(app = "pipeline", version = "1.0", user = "jsmith")

if (FALSE) { # \dontrun{
adsl <- rl_read(log, haven::read_sas, "data/adsl.sas7bdat")
adae <- rl_read(log, readr::read_csv, file = "data/adae.csv")
} # }
```
