# regulog — Performance Qualification (PQ)
# Protocol: regulog-PQ-v0.1
# Regulation: 21 CFR Part 11 §11.10(a); EU Annex 11 Clause 4
#
# Purpose: Simulate representative production workflows to confirm regulog
# performs correctly end-to-end in the intended use environment.
#
# Prerequisite: IQ and OQ must both have passed.

library(regulog)

cat("=============================================================\n")
cat("regulog Performance Qualification (PQ)\n")
cat("Protocol: regulog-PQ-v0.1\n")
cat("Date:    ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"), "\n")
cat("regulog: ", as.character(utils::packageVersion("regulog")), "\n")
cat("=============================================================\n\n")

.pq_pass <- 0L
.pq_fail <- 0L
.pq_scenario <- function(id, desc, expr) {
  result <- tryCatch(isTRUE(expr), error = function(e) {
    cat(sprintf("  ERROR: %s\n", conditionMessage(e)))
    FALSE
  })
  cat(sprintf("[%s] %s — %s\n", if (result) "PASS" else "FAIL", id, desc))
  if (result) .pq_pass <<- .pq_pass + 1L else .pq_fail <<- .pq_fail + 1L
  invisible(result)
}

# -- PQ-001: Clinical data review workflow -----------------------------------
.pq_scenario("PQ-001", "Clinical data review workflow", {
  tmp <- tempfile(fileext = ".rlog")
  on.exit(unlink(tmp))

  log <- regulog_init(app = "clinical-review-tool", version = "1.2.0",
                       user = "dr.jones", path = tmp)

  log_action(log, action = "opened",
             object = "study_DB_v3.sas7bdat",
             reason = "Initiating data review per SAP section 5.2")

  log_action(log, action = "queried",
             object = "AE table",
             reason = "Checking adverse event coding completeness")

  log_change(log, object = "patient_10472", field = "ae_onset_date",
             before = "2026-03-01", after = "2026-03-11",
             reason = "Transcription error — date corrected per CRF page 14")

  log_action(log, action = "approved",
             object = "study_DB_v3.sas7bdat",
             reason = "All queries resolved; database lock approved")

  vr <- verify_log(log, verbose = FALSE)
  vr$intact && vr$n_entries == 4L
})

# -- PQ-002: Regulatory submission export ------------------------------------
.pq_scenario("PQ-002", "Regulatory submission export (signed CSV)", {
  tmp_log <- tempfile(fileext = ".rlog")
  tmp_csv <- tempfile(fileext = ".csv")
  on.exit({ unlink(tmp_log); unlink(tmp_csv) })

  log <- regulog_init(app = "submission-tool", version = "2.0.0",
                       user = "stat.lead", path = tmp_log)

  for (i in seq_len(10L)) {
    log_action(log,
      action = "reviewed",
      object = sprintf("TLF_%03d", i),
      reason = sprintf("Table %d reviewed against SAP v2.1", i)
    )
  }

  export_audit_trail(log, format = "csv", signed = TRUE, path = tmp_csv)

  file.exists(tmp_csv) &&
    nrow(utils::read.csv(tmp_csv)) == 10L &&
    "chain_intact" %in% names(utils::read.csv(tmp_csv)) &&
    isTRUE(utils::read.csv(tmp_csv)$chain_intact[[1L]])
})

# -- PQ-003: Multi-user concurrent session simulation -----------------------
.pq_scenario("PQ-003", "Multi-user independent session integrity", {
  users <- c("biostat.1", "dm.lead", "medical.monitor")
  logs  <- lapply(users, function(u) {
    regulog_init(app = "multi-user-app", user = u)
  })

  for (i in seq_along(users)) {
    log_action(logs[[i]],
      action = "reviewed",
      object = sprintf("dataset_%d", i),
      reason = sprintf("Scope review by %s", users[[i]])
    )
  }

  all(vapply(logs, function(l) {
    verify_log(l, verbose = FALSE)$intact
  }, logical(1L)))
})

# -- PQ-004: Load test (500 entries) ----------------------------------------
.pq_scenario("PQ-004", "Load test: 500 chained entries verified intact", {
  log <- regulog_init(app = "load-test", user = "validator")
  for (i in seq_len(500L)) {
    log_action(log,
      action = "processed",
      object = sprintf("record_%05d", i),
      reason = sprintf("Batch processing step %d of 500", i)
    )
  }
  vr <- verify_log(log, verbose = FALSE)
  vr$intact && vr$n_entries == 500L
})

# -- PQ-005: Tamper detection from .rlog file --------------------------------
.pq_scenario("PQ-005", "File-level tamper detection in .rlog", {
  tmp <- tempfile(fileext = ".rlog")
  on.exit(unlink(tmp))

  log <- regulog_init(app = "tamper-test", user = "validator", path = tmp)
  log_action(log, action = "signed",  object = "protocol_v5.pdf",
             reason = "Final protocol approved by sponsor")
  log_action(log, action = "archived", object = "protocol_v5.pdf",
             reason = "Archived to Trial Master File")

  # Tamper: alter action field in line 2 (first data entry after genesis)
  lines    <- readLines(tmp, warn = FALSE)
  lines[2] <- sub('"signed"', '"TAMPERED"', lines[2], fixed = TRUE)
  writeLines(lines, tmp)

  !verify_log(tmp, verbose = FALSE)$intact
})

cat("\n=============================================================\n")
cat(sprintf("PQ RESULT: %d PASS / %d FAIL\n", .pq_pass, .pq_fail))
if (.pq_fail == 0L) {
  cat("STATUS: PASS — regulog is qualified for use in this environment\n")
} else {
  cat("STATUS: FAIL — resolve failures; do not use in regulated context\n")
}
cat("=============================================================\n")
