## Resubmission (0.2.1)

Addressing reviewer feedback:

- Removed "for R" from the title and description
- Package names now in single quotes in the description ('shiny', 'SHA-256')
- Replaced \dontrun{} with if(interactive()){} in shiny.R examples
- \dontrun{} kept in read.R where examples need actual data files
  (haven::read_sas, readr::read_csv on files that cannot exist in check)

## R CMD check results

0 errors | 0 warnings | 2 notes

- New submission — expected
- Unable to verify current time — macOS network issue, unrelated to the package