test_that("log_signature() rejects blank meaning", {
  log <- regulog_init(app = "test", version = "0.1", user = "tester")
  expect_error(log_signature(log, ""))
  expect_error(log_signature(log, " "))
  expect_error(log_signature(log, NULL))
})

test_that("log_signature() adds a SIGNATURE entry with correct fields", {
  log <- regulog_init(app = "test", version = "0.1", user = "jsmith")
  log_action(log, "run", "analysis.R", "Model fitted")
  log_signature(log, "I certify this analysis is accurate per SAP v2")

  e <- log$entries[[2L]]
  expect_equal(e$type, "SIGNATURE")
  expect_equal(e$action, "signature")
  expect_equal(e$object, "jsmith") # signer = session user, not overrideable
  expect_equal(e$reason, "I certify this analysis is accurate per SAP v2")
  expect_equal(e$field, "entries_covered")
})

test_that("log_signature() records entries_covered automatically", {
  log <- regulog_init(app = "test", version = "0.1", user = "tester")
  log_action(log, "a1", "o", "Step 1")
  log_action(log, "a2", "o", "Step 2")
  log_action(log, "a3", "o", "Step 3")
  log_signature(log, "Certified")

  sig <- log$entries[[4L]]
  expect_equal(as.integer(sig$after), 3L)
})

test_that("log_signature() with zero prior entries records 0", {
  log <- regulog_init(app = "test", version = "0.1", user = "tester")
  log_signature(log, "Signing empty log")

  sig <- log$entries[[1L]]
  expect_equal(as.integer(sig$after), 0L)
})

test_that("log_signature() is pipe-friendly", {
  log <- regulog_init(app = "test", version = "0.1", user = "tester")
  result <- log_signature(log, "Certified")
  expect_identical(result, log)
})

test_that("log_signature() is part of the hash chain", {
  log <- regulog_init(app = "test", version = "0.1", user = "tester")
  log_action(log, "run", "a.R", "Fitted")
  log_note(log, "Outlier retained per SAP")
  log_signature(log, "Analysis certified accurate")

  result <- verify_log(log, verbose = FALSE)
  expect_true(result$intact)
  expect_equal(result$n_entries, 3L)
})

test_that("tampering with entry before signature is detected", {
  log <- regulog_init(app = "test", version = "0.1", user = "tester")
  log_action(log, "run", "a.R", "Fitted")
  log_signature(log, "Certified accurate")

  log$entries[[1L]]$action <- "TAMPERED"

  result <- suppressWarnings(verify_log(log, verbose = FALSE))
  expect_false(result$intact)
  expect_equal(result$first_broken, 1L)
})

test_that("tampering with the signature entry itself is detected", {
  log <- regulog_init(app = "test", version = "0.1", user = "tester")
  log_action(log, "run", "a.R", "Fitted")
  log_signature(log, "Certified accurate")

  log$entries[[2L]]$reason <- "TAMPERED MEANING"

  result <- suppressWarnings(verify_log(log, verbose = FALSE))
  expect_false(result$intact)
  expect_equal(result$first_broken, 2L)
})

test_that("log_signature() persists to .rlog file", {
  tmp <- tempfile(fileext = ".rlog")
  on.exit(unlink(tmp))
  log <- regulog_init(app = "test", version = "0.1", user = "tester", path = tmp)
  log_action(log, "run", "a.R", "Ran")
  log_signature(log, "Certified")

  lines <- readLines(tmp, warn = FALSE)
  lines <- lines[nzchar(trimws(lines))]
  # genesis + action + signature = 3 lines
  expect_equal(length(lines), 3L)
  expect_true(grepl("SIGNATURE", lines[[3L]]))
})
