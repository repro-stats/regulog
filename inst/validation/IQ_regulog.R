# regulog — Installation Qualification (IQ)
# Protocol: regulog-IQ-v0.2
# Regulation: 21 CFR Part 11 §11.10(a); EU Annex 11 Clause 4
#
# Purpose: Confirm that regulog and its dependencies are correctly installed
# in the target environment and that the runtime meets minimum requirements.
#
# Instructions:
#   Source this file in R. All checks must pass before proceeding to OQ.
#   Record the console output in the validation dossier.

cat("=============================================================\n")
cat("regulog Installation Qualification (IQ)\n")
cat("Protocol: regulog-IQ-v0.2\n")
cat("Date:    ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"), "\n")
cat("R:       ", R.version.string, "\n")
cat("Platform:", R.version$platform, "\n")
cat("=============================================================\n\n")

.iq_pass  <- 0L
.iq_fail  <- 0L
.iq_check <- function(id, desc, expr) {
  ok     <- tryCatch(isTRUE(expr), error = function(e) FALSE)
  status <- if (ok) "PASS" else "FAIL"
  cat(sprintf("[%s] %s — %s\n", status, id, desc))
  if (ok) .iq_pass <<- .iq_pass + 1L else .iq_fail <<- .iq_fail + 1L
  invisible(ok)
}

# IQ-001: R version >= 4.2.0
.iq_check("IQ-001", "R version >= 4.2.0",
  utils::compareVersion(
    paste0(R.version$major, ".", R.version$minor), "4.2.0"
  ) >= 0L
)

# IQ-002: regulog is installed
.iq_check("IQ-002", "regulog package installed",
  requireNamespace("regulog", quietly = TRUE)
)

# IQ-003: regulog is loadable
.iq_check("IQ-003", "regulog package loadable",
  tryCatch({ library(regulog); TRUE }, error = function(e) FALSE)
)

# IQ-004: digest installed
.iq_check("IQ-004", "Dependency: digest installed",
  requireNamespace("digest", quietly = TRUE)
)

# IQ-005: jsonlite installed
.iq_check("IQ-005", "Dependency: jsonlite installed",
  requireNamespace("jsonlite", quietly = TRUE)
)

# IQ-006: SHA-256 produces a 64-char hex string
.iq_check("IQ-006", "SHA-256 produces 64-char hex output", {
  h <- digest::digest("regulog:iq:check", algo = "sha256", serialize = FALSE)
  nchar(h) == 64L && grepl("^[a-f0-9]+$", h)
})

# IQ-007: JSON serialisation round-trips correctly
.iq_check("IQ-007", "jsonlite round-trip integrity", {
  obj <- list(a = 1L, b = "hello", c = TRUE)
  identical(
    jsonlite::fromJSON(jsonlite::toJSON(obj, auto_unbox = TRUE),
                       simplifyVector = FALSE),
    obj
  )
})

# IQ-008: File system write access (for .rlog persistence)
.iq_check("IQ-008", "File system write access in tempdir()", {
  f <- tempfile(fileext = ".rlog")
  writeLines("test", f)
  ok <- file.exists(f)
  unlink(f)
  ok
})

# IQ-009: regulog_init executes without error
.iq_check("IQ-009", "regulog_init() executes without error",
  tryCatch({
    log <- regulog_init(app = "iq-check", user = "validator")
    inherits(log, "regulog")
  }, error = function(e) FALSE)
)

# IQ-010: v0.2.0 functions are available
.iq_check("IQ-010", "v0.2.0 functions available: log_note, log_signature, filter_log, rl_read, with_log",
  all(c("log_note", "log_signature", "filter_log",
        "rl_read", "with_log") %in%
      getNamespaceExports("regulog"))
)

cat("\n=============================================================\n")
cat(sprintf("IQ RESULT: %d PASS / %d FAIL\n", .iq_pass, .iq_fail))
if (.iq_fail == 0L) {
  cat("STATUS: PASS — proceed to Operational Qualification (OQ)\n")
} else {
  cat("STATUS: FAIL — resolve failures before proceeding\n")
}
cat("=============================================================\n")