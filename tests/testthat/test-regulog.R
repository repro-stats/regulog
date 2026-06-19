test_that("regulog_init returns a regulog object with correct fields", {
  log <- regulog_init(app = "test-app", version = "0.1.0", user = "tester")

  expect_s3_class(log, "regulog")
  expect_equal(log$app, "test-app")
  expect_equal(log$version, "0.1.0")
  expect_equal(log$user, "tester")
  expect_equal(log$entry_id, 0L)
  expect_equal(length(log$entries), 0L)
  expect_true(nzchar(log$last_hash))
  expect_equal(nchar(log$last_hash), 64L)   # sha256 → 64 hex chars
})

test_that("regulog_init errors on empty app or user", {
  expect_error(regulog_init(app = "",    user = "u"), "`app`")
  expect_error(regulog_init(app = "app", user = ""),  "`user`")
})

test_that("log_action appends a flat entry and advances the chain", {
  log         <- regulog_init(app = "test-app", user = "tester")
  genesis_hash <- log$last_hash

  log_action(log,
    action = "approved",
    object = "dataset_v3.csv",
    reason = "QC review complete"
  )

  expect_equal(log$entry_id, 1L)
  expect_equal(length(log$entries), 1L)

  e <- log$entries[[1L]]
  expect_equal(e$type,       "ACTION")
  expect_equal(e$action,     "approved")
  expect_equal(e$object,     "dataset_v3.csv")
  expect_equal(e$reason,     "QC review complete")
  expect_equal(e$user,       "tester")
  expect_equal(e$prev_hash,  genesis_hash)
  expect_equal(nchar(e$entry_hash), 64L)
  expect_false(identical(log$last_hash, genesis_hash))
})

test_that("log_action errors when reason is missing or blank", {
  log <- regulog_init(app = "test-app", user = "tester")

  expect_error(
    log_action(log, action = "approved", object = "f.csv", reason = ""),
    "reason"
  )
  expect_error(
    log_action(log, action = "approved", object = "f.csv", reason = "   "),
    "reason"
  )
})

test_that("log_change stores before/after and field name", {
  log <- regulog_init(app = "test-app", user = "tester")
  log_change(log,
    object = "patient_10472",
    field  = "dob",
    before = "1985-03-01",
    after  = "1985-03-11",
    reason = "Transcription error — corrected per source document"
  )

  e <- log$entries[[1L]]
  expect_equal(e$type,   "CHANGE")
  expect_equal(e$object, "patient_10472")
  expect_equal(e$field,  "dob")
  expect_equal(e$before, "1985-03-01")
  expect_equal(e$after,  "1985-03-11")
  expect_equal(e$reason, "Transcription error — corrected per source document")
})

test_that("log_change errors when reason is missing", {
  log <- regulog_init(app = "test-app", user = "tester")
  expect_error(
    log_change(log, object = "p", field = "f",
               before = "a", after = "b", reason = ""),
    "reason"
  )
})

test_that("entry_id is monotonically increasing across mixed entry types", {
  log <- regulog_init(app = "test-app", user = "tester")
  log_action(log, action = "a1", object = "o", reason = "r1")
  log_change(log, object = "p", field = "f", before = "x", after = "y", reason = "r2")
  log_action(log, action = "a3", object = "o", reason = "r3")

  ids <- vapply(log$entries, `[[`, integer(1L), "entry_id")
  expect_equal(ids, 1L:3L)
})

test_that("each entry references the previous entry's hash", {
  log <- regulog_init(app = "test-app", user = "tester")
  h0  <- log$last_hash

  log_action(log, action = "a1", object = "o", reason = "r1")
  log_action(log, action = "a2", object = "o", reason = "r2")

  expect_equal(log$entries[[1L]]$prev_hash, h0)
  expect_equal(log$entries[[2L]]$prev_hash, log$entries[[1L]]$entry_hash)
})

test_that("user attribution can be overridden per entry", {
  log <- regulog_init(app = "test-app", user = "default_user")
  log_action(log, action = "approved", object = "f", reason = "ok",
             user = "reviewer_b")

  expect_equal(log$entries[[1L]]$user, "reviewer_b")
})

test_that("print.regulog works without error", {
  log <- regulog_init(app = "test-app", user = "tester")
  expect_output(print(log), "regulog")
})

test_that("disk persistence: entries round-trip through NDJSON", {
  tmp <- withr::local_tempfile(fileext = ".rlog")
  log <- regulog_init(app = "disk-test", user = "tester", path = tmp)

  log_action(log, action = "approved", object = "report.pdf", reason = "Final")
  log_change(log, object = "rec", field = "status",
             before = "draft", after = "final", reason = "Signed off")

  expect_true(file.exists(tmp))
  lines <- readLines(tmp, warn = FALSE)
  lines <- lines[nzchar(lines)]
  expect_equal(length(lines), 3L)  # genesis + 2 entries

  # Each line must be valid JSON
  parsed <- lapply(lines, jsonlite::fromJSON)
  expect_equal(parsed[[1L]]$type, "GENESIS")
  expect_equal(parsed[[2L]]$action, "approved")
  expect_equal(parsed[[3L]]$field,  "status")
})

test_that("log_action returns log invisibly for piping", {
  log <- regulog_init(app = "test-app", user = "tester")
  result <- log_action(log, action = "a", object = "o", reason = "r")
  expect_identical(result, log)
})

test_that("log_action errors when log is not a regulog object", {
  expect_error(
    log_action(list(), action = "a", object = "o", reason = "r"),
    "regulog"
  )
})

test_that("log_change errors when log is not a regulog object", {
  expect_error(
    log_change(list(), object = "o", field = "f",
               before = "a", after = "b", reason = "r"),
    "regulog"
  )
})