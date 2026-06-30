# Verify the integrity of an audit log chain

Recomputes every entry hash and confirms each matches the stored value,
and that each `prev_hash` matches its predecessor's `entry_hash`. Any
discrepancy indicates tampering or corruption.

## Usage

``` r
verify_log(log, verbose = TRUE)
```

## Arguments

- log:

  A `regulog` object **or** a character path to a `.rlog` file.

- verbose:

  Logical. Print a summary. Defaults to `TRUE`.

## Value

A list (invisibly) with components:

- `intact`:

  Logical. `TRUE` if the chain is unbroken.

- `n_entries`:

  Integer. Number of data entries verified (genesis excluded).

- `first_broken`:

  Integer or `NA`. `entry_id` of the first invalid entry.

- `errors`:

  Character vector of error descriptions.

## Details

### Verification algorithm

For each entry *i* (excluding the genesis record):

1.  Reconstruct `hash_input` from the stored fields in canonical order.

2.  Recompute `digest(hash_input, algo = hash_algo)`.

3.  Assert `computed == entry$entry_hash` (content integrity).

4.  Assert `entry$prev_hash == entry[i-1]$entry_hash` (chain
    continuity).

Step 3 failure: the entry's content was modified after writing. Step 4
failure: entries were inserted, deleted, or reordered.

## Examples

``` r
log <- regulog_init(app = "my-app", user = "jsmith")
log_action(log,
  action = "approved", object = "file.csv",
  reason = "Review complete"
)
#> regulog: logged action 'approved' on 'file.csv'
verify_log(log)
#> regulog: Log intact: 1 entry, chain unbroken
#> v Log intact: 1 entry, chain unbroken
```
