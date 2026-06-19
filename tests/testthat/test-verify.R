test_that("verify_log passes for an unmodified in-memory log", {
  log <- regulog_init(app = "test-app", user = "tester")
  log_action(log, action = "a1", object = "o", reason = "r1")
  log_action(log, action = "a2", object = "o", reason = "r2")
  log_change(log, object = "p", field = "f", before = "x", after = "y",
             reason = "r3")

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
    log_action(log, action = paste0("a", i), object = "o",
               reason = paste0("r", i))
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
  log_change(log, object = "rec", field = "status",
             before = "draft", after = "final", reason = "Approved")

  result <- verify_log(tmp, verbose = FALSE)
  expect_true(result$intact)
  expect_equal(result$n_entries, 2L)
})

test_that("verify_log.character detects tampering in file", {
  tmp <- withr::local_tempfile(fileext = ".rlog")
  log <- regulog_init(app = "disk-test", user = "tester", path = tmp)
  log_action(log, action = "approved", object = "protocol.pdf",
             reason = "Reviewed")

  # Surgically alter the file
  lines    <- readLines(tmp, warn = FALSE)
  lines[2] <- sub('"approved"', '"TAMPERED"', lines[2], fixed = TRUE)
  writeLines(lines, tmp)

  result <- verify_log(tmp, verbose = FALSE)
  expect_false(result$intact)
})

test_that("verify_log on empty log returns intact with 0 entries", {
  log <- regulog_init(app = "test-app", user = "tester")
  result <- verify_log(log, verbose = FALSE)
  expect_true(result$intact)
  expect_equal(result$n_entries, 0L)
})
