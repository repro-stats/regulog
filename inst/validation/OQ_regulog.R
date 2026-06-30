# regulog — Operational Qualification (OQ)
# Protocol: regulog-OQ-v0.2
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
cat("Protocol: regulog-OQ-v0.2\n")
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

# ── Original tests (OQ-001 to OQ-014) ────────────────────────────────────────

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

# ── v0.2.0 additions (OQ-015 to OQ-024c) ─────────────────────────────────────

# -- OQ-015: NOTE entry type -------------------------------------------------
.oq_test("OQ-015", "CFR §11.10(e)", "log_note() creates a NOTE entry with mandatory reason", {
  log <- regulog_init(app = "oq-test", user = "validator")
  log_note(log, "Baseline window defined as Day -1 to Day 1 per protocol v3")
  e <- log$entries[[1L]]
  e$type   == "NOTE" &&
  e$action == "note" &&
  e$reason == "Baseline window defined as Day -1 to Day 1 per protocol v3" &&
  e$user   == "validator"
})

# -- OQ-016: NOTE chain integrity -------------------------------------------
.oq_test("OQ-016", "CFR §11.10(e)", "log_note() entries are hash-chained and tamper-evident", {
  log <- regulog_init(app = "oq-test", user = "validator")
  log_action(log, action = "run",  object = "analysis.R", reason = "Primary model fitted")
  log_note(log,   "Outlier in subject 042 retained per SAP section 8.3")
  log_action(log, action = "done", object = "analysis.R", reason = "Analysis complete")
  vr <- verify_log(log, verbose = FALSE)
  vr$intact && vr$n_entries == 3L
})

# -- OQ-017: NOTE reason is mandatory ----------------------------------------
.oq_test("OQ-017", "CFR §11.10(e)", "log_note() rejects blank text (no silent entries)", {
  log <- regulog_init(app = "oq-test", user = "validator")
  tryCatch({
    log_note(log, "")
    FALSE
  }, error = function(e) grepl("reason", tolower(conditionMessage(e))))
})

# -- OQ-018: SIGNATURE entry structure ---------------------------------------
.oq_test("OQ-018", "CFR §11.100 / §11.200", "log_signature() records signer identity and meaning", {
  log <- regulog_init(app = "oq-test", user = "jsmith")
  log_action(log, action = "run", object = "analysis.R", reason = "Model fitted")
  log_signature(log,
    "I certify this analysis is accurate and complete per SAP version 2.0"
  )
  e <- log$entries[[2L]]
  e$type   == "SIGNATURE" &&
  e$action == "signature" &&
  e$object == "jsmith" &&
  e$reason == "I certify this analysis is accurate and complete per SAP version 2.0"
})

# -- OQ-019: SIGNATURE entries_covered is automatic -------------------------
.oq_test("OQ-019", "CFR §11.200", "log_signature() records entries_covered without user input", {
  log <- regulog_init(app = "oq-test", user = "validator")
  log_action(log, action = "a1", object = "o", reason = "Step 1")
  log_action(log, action = "a2", object = "o", reason = "Step 2")
  log_action(log, action = "a3", object = "o", reason = "Step 3")
  log_signature(log, "Certified complete")
  sig <- log$entries[[4L]]
  sig$type == "SIGNATURE" && as.integer(sig$after) == 3L
})

# -- OQ-020: SIGNATURE hash chain --------------------------------------------
.oq_test("OQ-020", "CFR §11.10(e)", "log_signature() entry is part of the hash chain", {
  log <- regulog_init(app = "oq-test", user = "validator")
  log_action(log, action = "run",    object = "a.R", reason = "Step 1")
  log_note(log,   "Intermediate annotation")
  log_signature(log, "Analysis certified accurate")
  vr <- verify_log(log, verbose = FALSE)
  vr$intact && vr$n_entries == 3L
})

# -- OQ-021: Tampering after signature detected ------------------------------
.oq_test("OQ-021", "CFR §11.10(e)", "Tampering with entry before signature is detected", {
  log <- regulog_init(app = "oq-test", user = "validator")
  log_action(log, action = "run",  object = "a.R", reason = "Fitted")
  log_signature(log, "I certify this analysis is accurate")
  log$entries[[1L]]$action <- "TAMPERED"
  !verify_log(log, verbose = FALSE)$intact
})

# -- OQ-022: filter_log() by type -------------------------------------------
.oq_test("OQ-022", "CFR §11.10(b)", "filter_log() returns only entries matching the requested type", {
  log <- regulog_init(app = "oq-test", user = "validator")
  log_action(log,    action = "run", object = "a.R", reason = "Ran model")
  log_note(log,      "Decision note")
  log_signature(log, "Analysis certified")
  df_sig  <- filter_log(log, type = "SIGNATURE")
  df_note <- filter_log(log, type = "NOTE")
  df_act  <- filter_log(log, type = "ACTION")
  nrow(df_sig)  == 1L && df_sig$type[[1L]]  == "SIGNATURE" &&
  nrow(df_note) == 1L && df_note$type[[1L]] == "NOTE" &&
  nrow(df_act)  == 1L && df_act$type[[1L]]  == "ACTION"
})

# -- OQ-023: as.data.frame() excludes genesis --------------------------------
.oq_test("OQ-023", "CFR §11.10(b)", "as.data.frame.regulog() excludes genesis record from export", {
  log <- regulog_init(app = "oq-test", user = "validator")
  log_action(log, action = "run", object = "a.R", reason = "Ran")
  df <- as.data.frame(log)
  nrow(df) == 1L && !any(df$type == "GENESIS")
})

# -- OQ-024: with_log() propagates errors and preserves prior entries -------
.oq_test("OQ-024", "CFR §11.10(e)", "with_log() propagates errors without corrupting or losing prior chain entries", {
  log <- regulog_init(app = "oq-test", user = "validator")
  log_action(log, action = "setup", object = "init", reason = "Pre-block entry")

  err_caught <- FALSE
  tryCatch(
    with_log(log, { stop("deliberate error") }),
    error = function(e) err_caught <<- TRUE
  )

  vr <- verify_log(log, verbose = FALSE)
  err_caught && vr$intact && vr$n_entries == 1L
})

# -- OQ-024b: with_log()'s read() logs a data_read ACTION entry -------------
.oq_test("OQ-024b", "CFR §11.10(e)", "with_log()'s read() logs a data_read ACTION entry with correct path", {
  log <- regulog_init(app = "oq-test", user = "validator")
  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp))
  utils::write.csv(data.frame(x = 1:3), tmp, row.names = FALSE)

  with_log(log, {
    df <- read(utils::read.csv, tmp)
  })

  e <- log$entries[[1L]]
  e$type == "ACTION" && e$action == "data_read" && e$object == tmp
})

# -- OQ-024c: concurrent with_log() sessions do not interfere ---------------
.oq_test("OQ-024c", "CFR §11.10(e)", "Two independent with_log() calls on separate logs do not share state", {
  log_a <- regulog_init(app = "oq-test", user = "user_a")
  log_b <- regulog_init(app = "oq-test", user = "user_b")
  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp))
  utils::write.csv(data.frame(x = 1), tmp, row.names = FALSE)

  with_log(log_a, { read(utils::read.csv, tmp) })
  with_log(log_b, { read(utils::read.csv, tmp) })

  length(log_a$entries) == 1L && length(log_b$entries) == 1L &&
    log_a$entries[[1L]]$user == "user_a" &&
    log_b$entries[[1L]]$user == "user_b"
})

# ── Summary ───────────────────────────────────────────────────────────────────

cat("\n=============================================================\n")
cat(sprintf("OQ RESULT: %d PASS / %d FAIL\n", .oq_pass, .oq_fail))
if (.oq_fail == 0L) {
  cat("STATUS: PASS — proceed to Performance Qualification (PQ)\n")
} else {
  cat("STATUS: FAIL — resolve failures before proceeding\n")
}
cat("=============================================================\n")