# regulog — Operational Qualification (OQ)
# Protocol: regulog-OQ-v0.1
# Regulation: 21 CFR Part 11 §11.10(a),(e); EU Annex 11 Clauses 9, 11
#
# Purpose: Verify that regulog functions correctly under normal and boundary
# conditions. Each test is mapped to a specific regulatory requirement via
# the Requirements Traceability Matrix (RTM).
#
# Prerequisite: IQ must have passed before running OQ.
# Instructions: Source this file. All tests must pass.

library(regulog)

cat("=============================================================\n")
cat("regulog Operational Qualification (OQ)\n")
cat("Protocol: regulog-OQ-v0.1\n")
cat("Date:    ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"), "\n")
cat("regulog: ", as.character(utils::packageVersion("regulog")), "\n")
cat("=============================================================\n\n")

.oq_pass <- 0L
.oq_fail <- 0L
.oq_test <- function(id, req, desc, expr) {
  result <- tryCatch(isTRUE(expr), error = function(e) {
    cat(sprintf("  ERROR: %s\n", conditionMessage(e)))
    FALSE
  })
  status <- if (result) "PASS" else "FAIL"
  cat(sprintf("[%s] %s [%s]\n       %s\n", status, id, req, desc))
  if (result) .oq_pass <<- .oq_pass + 1L else .oq_fail <<- .oq_fail + 1L
  invisible(result)
}

# -- OQ-001: Hash chain formation --------------------------------------------
.oq_test("OQ-001", "CFR §11.10(e)", "Genesis hash is 64-char hex", {
  log <- regulog_init(app = "oq-test", user = "validator")
  nchar(log$last_hash) == 64L && grepl("^[a-f0-9]+$", log$last_hash)
})

# -- OQ-002: Action chaining -------------------------------------------------
.oq_test("OQ-002", "CFR §11.10(e)", "log_action entry links to genesis hash", {
  log <- regulog_init(app = "oq-test", user = "validator")
  h0  <- log$last_hash
  log_action(log, action = "approved", object = "f.csv", reason = "ok")
  log$entries[[1L]]$prev_hash == h0 && log$last_hash != h0
})

# -- OQ-003: Change before/after capture ------------------------------------
.oq_test("OQ-003", "CFR §11.10(e)", "log_change captures before and after values", {
  log <- regulog_init(app = "oq-test", user = "validator")
  log_change(log, object = "p", field = "dob",
             before = "1985-01-01", after = "1985-01-11",
             reason = "Correction")
  e <- log$entries[[1L]]
  e$before == "1985-01-01" && e$after == "1985-01-11" && e$field == "dob"
})

# -- OQ-004: Mandatory reason -----------------------------------------------
.oq_test("OQ-004", "CFR §11.10(e)", "Blank reason raises an error", {
  log <- regulog_init(app = "oq-test", user = "validator")
  tryCatch({
    log_action(log, action = "a", object = "o", reason = "")
    FALSE
  }, error = function(e) grepl("reason", tolower(conditionMessage(e))))
})

# -- OQ-005: User attribution ------------------------------------------------
.oq_test("OQ-005", "CFR §11.50", "User identity preserved in every entry", {
  log <- regulog_init(app = "oq-test", user = "j.smith")
  log_action(log, action = "approved", object = "f", reason = "ok")
  log$entries[[1L]]$user == "j.smith"
})

# -- OQ-006: Timestamp format ------------------------------------------------
.oq_test("OQ-006", "CFR §11.10(e)", "Timestamp is ISO-8601 UTC format", {
  log <- regulog_init(app = "oq-test", user = "validator")
  log_action(log, action = "a", object = "o", reason = "r")
  ts <- log$entries[[1L]]$timestamp
  grepl("^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}", ts)
})

# -- OQ-007: Chain verify passes for intact log ------------------------------
.oq_test("OQ-007", "Annex 11 §11", "verify_log passes for intact log", {
  log <- regulog_init(app = "oq-test", user = "validator")
  log_action(log, action = "a1", object = "o", reason = "r1")
  log_action(log, action = "a2", object = "o", reason = "r2")
  verify_log(log, verbose = FALSE)$intact
})

# -- OQ-008: Content tampering detected -------------------------------------
.oq_test("OQ-008", "Annex 11 §11", "verify_log detects content modification", {
  log <- regulog_init(app = "oq-test", user = "validator")
  log_action(log, action = "approved", object = "f", reason = "ok")
  log$entries[[1L]]$action <- "TAMPERED"
  !verify_log(log, verbose = FALSE)$intact
})

# -- OQ-009: Chain break detected -------------------------------------------
.oq_test("OQ-009", "Annex 11 §11", "verify_log detects chain link break", {
  log <- regulog_init(app = "oq-test", user = "validator")
  log_action(log, action = "a1", object = "o", reason = "r1")
  log_action(log, action = "a2", object = "o", reason = "r2")
  log$entries[[2L]]$prev_hash <- paste(rep("0", 64L), collapse = "")
  !verify_log(log, verbose = FALSE)$intact
})

# -- OQ-010: CSV export columns ---------------------------------------------
.oq_test("OQ-010", "CFR §11.10(b)", "CSV export has required regulatory columns", {
  log <- regulog_init(app = "oq-test", user = "validator")
  log_action(log, action = "approved", object = "f.csv", reason = "ok")
  df  <- export_audit_trail(log, format = "csv")
  all(c("entry_id", "timestamp", "user", "type", "reason",
        "entry_hash", "prev_hash") %in% names(df))
})

# -- OQ-011: Signed export --------------------------------------------------
.oq_test("OQ-011", "CFR §11.10(b)", "Signed CSV export includes chain_intact field", {
  log <- regulog_init(app = "oq-test", user = "validator")
  log_action(log, action = "approved", object = "f", reason = "ok")
  df  <- export_audit_trail(log, format = "csv", signed = TRUE)
  "chain_intact" %in% names(df) && isTRUE(df$chain_intact[[1L]])
})

# -- OQ-012: Date filtering -------------------------------------------------
.oq_test("OQ-012", "CFR §11.10(b)", "Date filter excludes out-of-range entries", {
  log <- regulog_init(app = "oq-test", user = "validator")
  log_action(log, action = "a", object = "o", reason = "r")
  nrow(export_audit_trail(log, format = "csv", from = "2099-01-01")) == 0L
})

# -- OQ-013: Disk round-trip ------------------------------------------------
.oq_test("OQ-013", "CFR §11.10(c)", "Entries persist to .rlog and verify from path", {
  tmp <- tempfile(fileext = ".rlog")
  on.exit(unlink(tmp))
  log <- regulog_init(app = "oq-test", user = "validator", path = tmp)
  log_action(log, action = "saved", object = "r.pdf", reason = "Final")
  verify_log(tmp, verbose = FALSE)$intact
})

# -- OQ-014: Monotone sequence numbers --------------------------------------
.oq_test("OQ-014", "CFR §11.10(e)", "entry_id values are monotonically increasing", {
  log <- regulog_init(app = "oq-test", user = "validator")
  for (i in 1:5) log_action(log, action = paste0("a", i), object = "o",
                              reason = paste0("r", i))
  ids <- vapply(log$entries, `[[`, integer(1L), "entry_id")
  identical(ids, 1L:5L)
})

cat("\n=============================================================\n")
cat(sprintf("OQ RESULT: %d PASS / %d FAIL\n", .oq_pass, .oq_fail))
if (.oq_fail == 0L) {
  cat("STATUS: PASS — proceed to Performance Qualification (PQ)\n")
} else {
  cat("STATUS: FAIL — resolve failures before proceeding\n")
}
cat("=============================================================\n")
