test_that("log_note() rejects blank text", {
  log <- regulog_init(app = "test", version = "0.1", user = "tester")
  expect_error(log_note(log, ""))
  expect_error(log_note(log, "   "))
})

test_that("log_note() rejects non-character input", {
  log <- regulog_init(app = "test", version = "0.1", user = "tester")
  expect_error(log_note(log, NULL))
})

test_that("log_note() adds a NOTE entry with correct fields", {
  log <- regulog_init(app = "test", version = "0.1", user = "tester")
  log_note(log, "Baseline window defined as Day -1 to Day 1 per protocol v3")

  e <- log$entries[[1L]]
  expect_equal(e$type, "NOTE")
  expect_equal(e$action, "note")
  expect_equal(e$user, "tester")
  expect_equal(e$reason, "Baseline window defined as Day -1 to Day 1 per protocol v3")
})

test_that("log_note() is pipe-friendly (returns log invisibly)", {
  log <- regulog_init(app = "test", version = "0.1", user = "tester")
  result <- log_note(log, "A note")
  expect_identical(result, log)
})

test_that("log_note() increments entry_id correctly", {
  log <- regulog_init(app = "test", version = "0.1", user = "tester")
  log_action(log, "run", "a.R", "Step 1")
  log_note(log, "An annotation after step 1")

  expect_equal(log$entries[[1L]]$entry_id, 1L)
  expect_equal(log$entries[[2L]]$entry_id, 2L)
})

test_that("log_note() entry is part of the hash chain", {
  log <- regulog_init(app = "test", version = "0.1", user = "tester")
  log_action(log, "run", "a.R", "Step 1")
  log_note(log, "Intermediate annotation")
  log_action(log, "done", "a.R", "Step 2")

  result <- verify_log(log, verbose = FALSE)
  expect_true(result$intact)
  expect_equal(result$n_entries, 3L)
})

test_that("log_note() tamper detection works", {
  log <- regulog_init(app = "test", version = "0.1", user = "tester")
  log_note(log, "Original note")
  log$entries[[1L]]$reason <- "TAMPERED"

  result <- suppressWarnings(verify_log(log, verbose = FALSE))
  expect_false(result$intact)
  expect_equal(result$first_broken, 1L)
})

test_that("log_note() persists to .rlog file", {
  tmp <- tempfile(fileext = ".rlog")
  on.exit(unlink(tmp))
  log <- regulog_init(app = "test", version = "0.1", user = "tester", path = tmp)
  log_note(log, "Persisted note")

  lines <- readLines(tmp, warn = FALSE)
  lines <- lines[nzchar(trimws(lines))]
  # genesis (line 1) + note (line 2)
  expect_equal(length(lines), 2L)
  expect_true(grepl("NOTE", lines[[2L]]))
})
