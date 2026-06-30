# Requirements Traceability Matrix — regulog

This document accompanies `RTM_regulog.csv` and explains its structure,
column definitions, and how it is maintained.

## Purpose

The Requirements Traceability Matrix (RTM) maps each applicable regulatory
clause (21 CFR Part 11, EU Annex 11) to the `regulog` function or design
feature that satisfies it, and to the specific Installation Qualification
(IQ), Operational Qualification (OQ), and Performance Qualification (PQ)
test(s) that verify that requirement.

The RTM is the single source of truth connecting **regulation → feature →
test evidence**. It is the document a regulatory inspector or internal QA
reviewer consults first.

## File

`RTM_regulog.csv` — one row per requirement, plain CSV, UTF-8 encoded.

CSV was chosen deliberately over alternatives (Markdown table, YAML, Excel):
it is reliably diffable in version control, opens directly in Excel for
non-R reviewers, and can be parsed programmatically (e.g. to check that
every referenced `oq_ref` exists in `OQ_regulog.R`).

## Column definitions

| Column | Description |
|---|---|
| `req_id` | Unique identifier for this requirement row, used for cross-reference. Prefixed `CFR-` for 21 CFR Part 11 clauses, `AX11-` for EU Annex 11 clauses. |
| `regulation` | The governing regulation: `21 CFR Part 11` or `EU Annex 11`. |
| `clause` | The specific clause or section number within the regulation. |
| `requirement` | Plain-English statement of what the clause requires. |
| `regulog_function` | The `regulog` function(s) or design feature that satisfies this requirement. |
| `iq_ref` | Installation Qualification test ID(s) covering this requirement, from `IQ_regulog.R`. A range (e.g. `IQ-001:IQ-009`) means all tests in that inclusive range apply. Blank if not applicable at the IQ stage. |
| `oq_ref` | Operational Qualification test ID(s) from `OQ_regulog.R`, same range notation. |
| `pq_ref` | Performance Qualification test ID(s) from `PQ_regulog.R`, same range notation. |
| `status` | `Covered` if fully addressed by the package; `Partial — outside package scope` if the requirement depends on something the package cannot control (e.g. system-level access control). |

## Range notation

A reference like `OQ-018:OQ-021` means tests OQ-018, OQ-019, OQ-020, and
OQ-021 all contribute evidence for that requirement — not just the first
and last. This mirrors R's `:` sequence operator and is used purely as
shorthand to keep cells readable.

## Requirements outside package scope

One row (`CFR-11.10d`, limiting system access to authorised individuals) is
marked `Partial — outside package scope`. `regulog` records *who* performed
an action once they are in the system, but cannot itself control *who is
permitted* to access the system in the first place — that is necessarily
the responsibility of the surrounding authentication layer (e.g. Shiny
Server Pro, Posit Connect, OS-level access control). This is stated
explicitly rather than left implicit, since overclaiming coverage of a
requirement the package does not actually satisfy would misrepresent its
guarantees.

## Maintenance

The RTM is updated whenever:

- A new exported function is added that addresses a regulatory clause not
  previously covered, or
- An existing function's implementation changes in a way that affects
  *how* a requirement is satisfied (not just internal refactoring), or
- A new OQ/PQ test is added or an existing one is renumbered.

When a function is redesigned (for example, the `rl_read()` / `with_log()`
rewrite in v0.2.0 that replaced namespace-patching with explicit call-site
logging), the `regulog_function` and `*_ref` columns for any affected row
must be updated in the same change — the RTM should never reference a
function name, internal mechanism, or test ID that does not exist in the
current codebase.

## Verifying RTM accuracy

To confirm every test ID referenced in the RTM actually exists in the
corresponding script:

```r
rtm <- read.csv("inst/validation/RTM_regulog.csv", stringsAsFactors = FALSE)

# Extract all individual test IDs from a column, expanding ranges
expand_refs <- function(ref_col, prefix) {
  refs <- unlist(strsplit(ref_col[nzchar(ref_col)], ":"))
  refs[grepl(paste0("^", prefix), refs)]
}

oq_refs_cited <- expand_refs(rtm$oq_ref, "OQ-")

oq_script  <- readLines("inst/validation/OQ_regulog.R")
oq_defined <- regmatches(oq_script,
  regexpr('"OQ-[0-9]+[a-z]?"', oq_script))
oq_defined <- gsub('"', "", oq_defined)

setdiff(oq_refs_cited, oq_defined)
# Should return character(0) -- any output here is a stale RTM reference
```

## Related files

- `IQ_regulog.R` — Installation Qualification test script
- `OQ_regulog.R` — Operational Qualification test script
- `PQ_regulog.R` — Performance Qualification test script
- `RTM_regulog.csv` — this matrix, in machine-readable form