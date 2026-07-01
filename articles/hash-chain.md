# The hash chain: how tamper detection works

Every `regulog` entry is cryptographically linked to the entry before
it. This means that any modification to any part of any entry — however
subtle — breaks the chain at that point and is detectable by
[`verify_log()`](https://reprostats.org/regulog/reference/verify_log.md).

This vignette explains how the chain is constructed, what it detects,
what it does not detect, and how to verify logs in a production setting.

## 1. The genesis record

When
[`regulog_init()`](https://reprostats.org/regulog/reference/regulog_init.md)
is called, a genesis record is created immediately. It is not a log
entry in the usual sense — it carries no user action — but its SHA-256
hash becomes the anchor for the entire chain.

``` r

log <- regulog_init(app = "demo", version = "1.0", user = "analyst")

cat("Genesis hash:", log$genesis_hash, "\n")
#> Genesis hash: 3b49a3a9bda0bcab6d7d43c07ad1820c1246b62cc4c6d0962a8b305afb362124
cat("Last hash:   ", log$last_hash, "\n")
#> Last hash:    3b49a3a9bda0bcab6d7d43c07ad1820c1246b62cc4c6d0962a8b305afb362124
```

The genesis hash incorporates the app name, version, and creation
timestamp. Two sessions with the same app and version but different
creation times will have different genesis hashes.

## 2. How entries are hashed

Each entry hash is computed over a canonical string that includes every
field of that entry plus the hash of the previous entry:

    h_n = SHA256(
      entry_id | timestamp | app | app_version | user | type |
      <payload fields in sorted key order> | h_{n-1}
    )

The pipe character `|` is the delimiter. Field values are concatenated
in a fixed, deterministic order — this is what makes the hash
reproducible during verification.

Let us look at what this looks like in practice:

``` r

log_action(
  log, "approved", "dataset_v1",
  "All quality checks passed — dataset approved for analysis"
)
#> regulog: logged action 'approved' on 'dataset_v1'

entry <- log$entries[[1L]]
cat("Entry ID:   ", entry$entry_id, "\n")
#> Entry ID:    1
cat("Prev hash:  ", entry$prev_hash, "\n") # = genesis hash
#> Prev hash:   3b49a3a9bda0bcab6d7d43c07ad1820c1246b62cc4c6d0962a8b305afb362124
cat("Entry hash: ", entry$entry_hash, "\n")
#> Entry hash:  2458ae078f0e53208cbab83f15a73336a881d1fcf1fbc9ac9f6624d5ee1b21ed
```

The `prev_hash` of the first entry matches the `genesis_hash`. The chain
has begun.

``` r

log_action(log, "model_fit", "ANCOVA_v1", "Primary ANCOVA fitted per SAP")
#> regulog: logged action 'model_fit' on 'ANCOVA_v1'
log_note(log, "Outlier in subject 042 retained per SAP section 8.3")
#> regulog: note logged

cat("Entry 1 hash:", log$entries[[1L]]$entry_hash, "\n")
#> Entry 1 hash: 2458ae078f0e53208cbab83f15a73336a881d1fcf1fbc9ac9f6624d5ee1b21ed
cat("Entry 2 prev:", log$entries[[2L]]$prev_hash, "\n")
#> Entry 2 prev: 2458ae078f0e53208cbab83f15a73336a881d1fcf1fbc9ac9f6624d5ee1b21ed
cat("Match:       ", log$entries[[1L]]$entry_hash ==
  log$entries[[2L]]$prev_hash, "\n")
#> Match:        TRUE
```

Each entry’s hash is the `prev_hash` of the next. The chain is intact.

## 3. Verification

[`verify_log()`](https://reprostats.org/regulog/reference/verify_log.md)
recomputes every entry hash from scratch and checks that:

1.  The recomputed hash matches the stored `entry_hash` — confirms the
    entry content has not been modified
2.  The stored `prev_hash` matches the preceding entry’s `entry_hash` —
    confirms no entries have been inserted, deleted, or reordered

``` r

verify_log(log)
#> regulog: Log intact: 3 entries, chain unbroken
```

The return value is always a list with structured fields:

``` r

result <- verify_log(log, verbose = FALSE)
str(result)
#> List of 4
#>  $ intact      : logi TRUE
#>  $ n_entries   : int 3
#>  $ first_broken: int NA
#>  $ errors      : chr(0)
```

## 4. What tampering looks like

### 4a. Modifying an entry’s content

If any field — reason, action, timestamp, user — is changed after
writing, the recomputed hash will not match the stored `entry_hash`. The
entry fails step 1 of verification.

``` r

# Simulate a reason being altered
original_reason <- log$entries[[1L]]$reason
log$entries[[1L]]$reason <- "ALTERED"

result <- suppressWarnings(verify_log(log, verbose = FALSE))
cat("Intact:       ", result$intact, "\n")
#> Intact:        FALSE
cat("First broken: ", result$first_broken, "\n")
#> First broken:  1
cat("Error:        ", result$errors[[1L]], "\n")
#> Error:         Entry #1: entry_hash mismatch — content may have been modified

log$entries[[1L]]$reason <- original_reason # restore
```

### 4b. Deleting an entry

If entry 2 is deleted, entry 3’s `prev_hash` will no longer match entry
1’s `entry_hash`. The chain fails step 2 at entry 3.

``` r

saved <- log$entries
log$entries <- log$entries[-2L] # remove entry 2

result <- suppressWarnings(verify_log(log, verbose = FALSE))
cat("Intact:       ", result$intact, "\n")
#> Intact:        FALSE
cat("First broken: ", result$first_broken, "\n")
#> First broken:  3

log$entries <- saved # restore
```

### 4c. Breaking the prev_hash directly

``` r

saved_prev <- log$entries[[2L]]$prev_hash
log$entries[[2L]]$prev_hash <- paste(rep("0", 64L), collapse = "")

result <- suppressWarnings(verify_log(log, verbose = FALSE))
cat("Intact:       ", result$intact, "\n")
#> Intact:        FALSE
cat("First broken: ", result$first_broken, "\n")
#> First broken:  2

log$entries[[2L]]$prev_hash <- saved_prev # restore
verify_log(log, verbose = FALSE)$intact # confirm restored
#> [1] TRUE
```

## 5. What the chain does NOT protect against

The hash chain proves that entries have not been modified after writing.
It does not:

- **Authenticate the user** — `user` is a string; `regulog` does not
  verify that the person who set `user = "jsmith"` is actually that
  person. Authentication is the responsibility of the calling system (OS
  login, Shiny Server Pro, Posit Connect).
- **Prevent future entries** — anyone with write access to the `.rlog`
  file can append new entries. The chain only covers what is written; it
  does not prevent additions.
- **Encrypt the content** — `.rlog` files are plain JSON. Do not store
  sensitive data in log entries; store references (file names, IDs)
  instead.
- **Protect from file deletion** — if the `.rlog` file is deleted, the
  audit trail is gone. Use standard file system controls and backups.

## 6. Verifying a file without a live session

The `.rlog` file is self-contained. Verification does not require the
original `regulog` object — it works directly from the file path:

``` r

# Can be run by a QC reviewer with no knowledge of the original session
result <- verify_log("logs/trial001_audit.rlog")

# Structured result for programmatic use
if (!result$intact) {
  warning(sprintf(
    "Log integrity failure: %d error(s). First broken entry: #%d",
    length(result$errors), result$first_broken
  ))
}
```

This is the intended QC workflow in regulated environments: the analyst
runs the analysis and produces the `.rlog`, a reviewer verifies the file
independently.

## 7. Working with persistent .rlog files

When `path` is supplied to
[`regulog_init()`](https://reprostats.org/regulog/reference/regulog_init.md),
entries are written to disk immediately — each
[`log_action()`](https://reprostats.org/regulog/reference/log_action.md),
[`log_change()`](https://reprostats.org/regulog/reference/log_change.md),
etc. appends one JSON line. The file is append-only from `regulog`’s
perspective.

``` r

log <- regulog_init(
  app     = "trial-analysis",
  version = "1.0.0",
  user    = "jsmith",
  path    = "logs/trial001_audit.rlog"
)

log_action(log, "data_read", "adsl.sas7bdat", "Reading ADSL")
# ↑ This line is written to disk immediately

# The .rlog file at this point:
# Line 1: {"entry_id":0,"type":"GENESIS",...}
# Line 2: {"entry_id":1,"type":"ACTION","action":"data_read",...}
```

The genesis record is always line 1. Subsequent entries follow in order.
Each line is a complete, self-contained JSON object.

## 8. The NDJSON format

`.rlog` files are newline-delimited JSON (NDJSON). Each line is one
entry:

``` json
{"entry_id":0,"timestamp":"2026-06-23T10:00:00.000Z","app":"trial-analysis","app_version":"1.0.0","user":"jsmith","type":"GENESIS","prev_hash":"0","entry_hash":"a3f8c2..."}
{"entry_id":1,"timestamp":"2026-06-23T10:01:22.841Z","app":"trial-analysis","app_version":"1.0.0","user":"jsmith","type":"ACTION","action":"data_read","object":"adsl.sas7bdat","reason":"Reading ADSL","prev_hash":"a3f8c2...","entry_hash":"b7d94e..."}
```

This format was chosen deliberately:

- **Human-readable** without specialist software
- **Streamable** — tools like `jq` can filter entries without loading
  the whole file
- **Append-safe** — no file rewriting needed; each entry is one line
- **Portable** — plain text, no binary encoding

## 9. Archival and long-term storage

For regulatory archival, export a signed CSV or JSON before storing:

``` r

# Signed CSV — chain_intact and verified_at stamped on every row
export_audit_trail(log,
  format = "csv",
  signed = TRUE,
  path   = "archive/trial001_audit_2026-06-23.csv"
)

# Original .rlog — keep this too; it allows re-verification later
file.copy(
  "logs/trial001_audit.rlog",
  "archive/trial001_audit_2026-06-23.rlog"
)
```

The signed CSV is human-readable and importable into any audit
management system. The `.rlog` file allows the original hash chain to be
verified at any future point using
[`verify_log()`](https://reprostats.org/regulog/reference/verify_log.md).

## 10. Hash algorithm

The default algorithm is SHA-256 (`hash_algo = "sha256"`). This is set
at
[`regulog_init()`](https://reprostats.org/regulog/reference/regulog_init.md)
and stored with the session — do not change it after a `.rlog` file is
in use, as verification would fail for any entries written with a
different algorithm.

SHA-256 is the standard for regulated environments. If your organisation
requires a different algorithm, pass `hash_algo` to
[`regulog_init()`](https://reprostats.org/regulog/reference/regulog_init.md)
— any algorithm supported by
[`digest::digest()`](https://eddelbuettel.github.io/digest/man/digest.html)
is accepted.
