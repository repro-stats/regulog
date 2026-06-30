test_that("verify_log passes for an unmodified in-memory log", {
  log <- regulog_init(app = "test-app", user = "tester")
  log_action(log, action = "a1", object = "o", reason = "r1")
  log_action(log, action = "a2", object = "o", reason = "r2")
  log_change(log,
    object = "p", field = "f", before = "x", after = "y",
    reason = "r3"
  )

  result <- verify_log(log, verbose = FALSE)
  expect_true(result$intact)
  expect_equal(result$n_entries, 3L)
  expect_true(is.na(result$first_broken))
  expect_equal(length(result$errors), 0L)
})

test_that("verify_log detects content tampering", {
  log <- regulog_init(app = "test-app", user = "tester")
  log_action(log, action = "approved", object = "f.csv", reason = "ok")
  log_action(log, action = "archived", object = "f.csv", reason = "done")

  # Tamper: change action field after commit
  log$entries[[1L]]$action <- "TAMPERED"

  result <- verify_log(log, verbose = FALSE)
  expect_false(result$intact)
  expect_equal(result$first_broken, 1L)
  expect_true(any(grepl("entry_hash mismatch", result$errors)))
})

test_that("verify_log detects reason tampering", {
  log <- regulog_init(app = "test-app", user = "tester")
  log_action(log, action = "approved", object = "f", reason = "Legitimate reason")

  log$entries[[1L]]$reason <- "Fabricated reason"

  result <- verify_log(log, verbose = FALSE)
  expect_false(result$intact)
})

test_that("verify_log detects chain link break", {
  log <- regulog_init(app = "test-app", user = "tester")
  log_action(log, action = "a1", object = "o", reason = "r1")
  log_action(log, action = "a2", object = "o", reason = "r2")

  # Sever the link between entries 1 and 2
  log$entries[[2L]]$prev_hash <- "0000000000000000000000000000000000000000000000000000000000000000"

  result <- verify_log(log, verbose = FALSE)
  expect_false(result$intact)
  expect_true(any(grepl("prev_hash mismatch", result$errors)))
})

test_that("verify_log identifies first_broken correctly", {
  log <- regulog_init(app = "test-app", user = "tester")
  for (i in 1:5) {
    log_action(log,
      action = paste0("a", i), object = "o",
      reason = paste0("r", i)
    )
  }

  # Tamper entry 3 only
  log$entries[[3L]]$action <- "TAMPERED"

  result <- verify_log(log, verbose = FALSE)
  expect_false(result$intact)
  # first_broken should be entry_id 3, and entry 4's chain also breaks
  expect_equal(result$first_broken, 3L)
})

test_that("verify_log.character works from a .rlog file path", {
  tmp <- withr::local_tempfile(fileext = ".rlog")
  log <- regulog_init(app = "disk-test", user = "tester", path = tmp)
  log_action(log, action = "saved", object = "report.pdf", reason = "Final")
  log_change(log,
    object = "rec", field = "status",
    before = "draft", after = "final", reason = "Approved"
  )

  result <- verify_log(tmp, verbose = FALSE)
  expect_true(result$intact)
  expect_equal(result$n_entries, 2L)
})

test_that("verify_log.character detects tampering in file", {
  tmp <- withr::local_tempfile(fileext = ".rlog")
  log <- regulog_init(app = "disk-test", user = "tester", path = tmp)
  log_action(log,
    action = "approved", object = "protocol.pdf",
    reason = "Reviewed"
  )

  # Surgically alter the file
  lines <- readLines(tmp, warn = FALSE)
  lines[2] <- sub('"approved"', '"TAMPERED"', lines[2], fixed = TRUE)
  writeLines(lines, tmp)

  result <- verify_log(tmp, verbose = FALSE)
  expect_false(result$intact)
})

test_that("verify_log.character errors on missing file", {
  expect_error(verify_log("nonexistent.rlog"), "not found")
})

test_that("verify_log.character errors on empty file", {
  tmp <- withr::local_tempfile(fileext = ".rlog")
  writeLines("", tmp)
  expect_error(verify_log(tmp, verbose = FALSE), "empty")
})

test_that("verify_log.character handles missing genesis record", {
  tmp <- withr::local_tempfile(fileext = ".rlog")
  log <- regulog_init(app = "test-app", user = "tester", path = tmp)
  log_action(log, action = "a", object = "o", reason = "r")

  # Strip the genesis line
  lines <- readLines(tmp, warn = FALSE)
  writeLines(lines[-1], tmp)

  expect_warning(result <- verify_log(tmp, verbose = FALSE), "GENESIS")
})

test_that("verify_log verbose=TRUE prints message for intact log", {
  log <- regulog_init(app = "test-app", user = "tester")
  log_action(log, action = "a", object = "o", reason = "r")
  expect_message(verify_log(log, verbose = TRUE), "intact")
})

test_that("verify_log verbose=TRUE prints warning for broken log", {
  log <- regulog_init(app = "test-app", user = "tester")
  log_action(log, action = "a", object = "o", reason = "r")
  log$entries[[1L]]$action <- "TAMPERED"
  expect_warning(verify_log(log, verbose = TRUE), "FAILED")
})

test_that("verify_log.character errors on non-existent file", {
  expect_error(verify_log("nonexistent.rlog"), "not found")
})

test_that("verify_log.character errors on empty file", {
  tmp <- withr::local_tempfile(fileext = ".rlog")
  writeLines("", tmp)
  expect_error(verify_log(tmp, verbose = FALSE), "empty")
})

test_that("verify_log.character warns when no GENESIS record found", {
  tmp <- withr::local_tempfile(fileext = ".rlog")
  # Write an entry without a genesis record
  entry <- list(
    entry_id = 1L, timestamp = "2026-01-01T00:00:00Z",
    app = "test", app_version = "1.0", user = "u",
    type = "ACTION", action = "a", object = "o", reason = "r",
    prev_hash = "0", entry_hash = "abc"
  )
  cat(jsonlite::toJSON(entry, auto_unbox = TRUE), "\n", file = tmp)
  expect_warning(verify_log(tmp, verbose = FALSE), "No GENESIS record")
})

test_that("verify_log verbose=TRUE prints message for intact log", {
  log <- regulog_init(app = "test-app", user = "tester")
  log_action(log, action = "a", object = "o", reason = "r")
  expect_message(verify_log(log, verbose = TRUE), "intact")
})

test_that("verify_log verbose=TRUE warns for broken log", {
  log <- regulog_init(app = "test-app", user = "tester")
  log_action(log, action = "a", object = "o", reason = "r")
  log$entries[[1L]]$action <- "TAMPERED"
  expect_warning(verify_log(log, verbose = TRUE), "FAILED")
})

test_that("verify_log.character intact log from file prints message", {
  tmp <- withr::local_tempfile(fileext = ".rlog")
  log <- regulog_init(app = "test-app", user = "tester", path = tmp)
  log_action(log, action = "a", object = "o", reason = "r")
  expect_message(verify_log(tmp, verbose = TRUE), "intact")
})
