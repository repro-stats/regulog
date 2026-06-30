# ── as.data.frame.regulog() ───────────────────────────────────────────────────

test_that("as.data.frame() on empty log returns zero-row data frame", {
  log <- regulog_init(app = "test", version = "0.1", user = "tester")
  df <- as.data.frame(log)
  expect_s3_class(df, "data.frame")
  expect_equal(nrow(df), 0L)
  expect_true(all(c(
    "entry_id", "timestamp", "app", "app_version",
    "user", "type", "action", "object",
    "field", "before", "after", "reason",
    "entry_hash", "prev_hash"
  ) %in% names(df)))
})

test_that("as.data.frame() excludes genesis record", {
  log <- regulog_init(app = "test", version = "0.1", user = "tester")
  log_action(log, "run", "a.R", "Ran")
  df <- as.data.frame(log)
  expect_equal(nrow(df), 1L)
  expect_false("GENESIS" %in% df$type)
})

test_that("as.data.frame() handles ACTION entries", {
  log <- regulog_init(app = "test", version = "0.1", user = "tester")
  log_action(log, "approved", "report.pdf", "QC passed")
  df <- as.data.frame(log)
  expect_equal(df$type[[1L]], "ACTION")
  expect_equal(df$action[[1L]], "approved")
  expect_equal(df$object[[1L]], "report.pdf")
  expect_equal(df$reason[[1L]], "QC passed")
})

test_that("as.data.frame() handles CHANGE entries with field/before/after", {
  log <- regulog_init(app = "test", version = "0.1", user = "tester")
  log_change(log,
    object = "patient_01", field = "dob",
    before = "1985-01-01", after = "1985-01-11",
    reason = "Correction per CRF"
  )
  df <- as.data.frame(log)
  expect_equal(df$type[[1L]], "CHANGE")
  expect_equal(df$field[[1L]], "dob")
  expect_equal(df$before[[1L]], "1985-01-01")
  expect_equal(df$after[[1L]], "1985-01-11")
})

test_that("as.data.frame() handles all four entry types in one log", {
  log <- regulog_init(app = "test", version = "0.1", user = "tester")
  log_action(log, "run", "a.R", "Ran model")
  log_change(log,
    object = "p", field = "alpha",
    before = "0.05", after = "0.025", reason = "Amendment"
  )
  log_note(log, "Decision note")
  log_signature(log, "Certified")

  df <- as.data.frame(log)
  expect_equal(nrow(df), 4L)
  expect_setequal(df$type, c("ACTION", "CHANGE", "NOTE", "SIGNATURE"))
})

# ── filter_log() — type ───────────────────────────────────────────────────────

test_that("filter_log() with no args returns all non-genesis entries", {
  log <- regulog_init(app = "test", version = "0.1", user = "tester")
  log_action(log, "a1", "o", "S1")
  log_note(log, "N1")
  log_signature(log, "Sig")
  expect_equal(nrow(filter_log(log)), 3L)
})

test_that("filter_log() filters by single type", {
  log <- regulog_init(app = "test", version = "0.1", user = "tester")
  log_action(log, "run", "a.R", "S1")
  log_note(log, "N1")
  log_signature(log, "Sig")

  expect_equal(nrow(filter_log(log, type = "ACTION")), 1L)
  expect_equal(nrow(filter_log(log, type = "NOTE")), 1L)
  expect_equal(nrow(filter_log(log, type = "SIGNATURE")), 1L)
})

test_that("filter_log() filters by multiple types", {
  log <- regulog_init(app = "test", version = "0.1", user = "tester")
  log_action(log, "run", "a.R", "S1")
  log_note(log, "N1")
  log_signature(log, "Sig")

  df <- filter_log(log, type = c("ACTION", "NOTE"))
  expect_equal(nrow(df), 2L)
  expect_true(all(df$type %in% c("ACTION", "NOTE")))
})

test_that("filter_log() returns zero-row data frame when type has no match", {
  log <- regulog_init(app = "test", version = "0.1", user = "tester")
  log_action(log, "run", "a.R", "Ran")
  df <- filter_log(log, type = "SIGNATURE")
  expect_equal(nrow(df), 0L)
  expect_s3_class(df, "data.frame")
})

# ── filter_log() — action & user ─────────────────────────────────────────────

test_that("filter_log() filters by action value", {
  log <- regulog_init(app = "test", version = "0.1", user = "tester")
  log_action(log, "approved", "report.pdf", "QC passed")
  log_action(log, "exported", "report.pdf", "Sent to sponsor")

  df <- filter_log(log, action = "approved")
  expect_equal(nrow(df), 1L)
  expect_equal(df$action[[1L]], "approved")
})

test_that("filter_log() filters by user", {
  log <- regulog_init(app = "test", version = "0.1", user = "alice")
  log_action(log, "run", "a.R", "Alice ran", user = "alice")
  log_action(log, "run", "b.R", "Bob ran", user = "bob")

  df <- filter_log(log, user = "alice")
  expect_equal(nrow(df), 1L)
  expect_equal(df$user[[1L]], "alice")
})

# ── filter_log() — date filters ───────────────────────────────────────────────

test_that("filter_log(from) with far-future date excludes all entries", {
  log <- regulog_init(app = "test", version = "0.1", user = "tester")
  log_action(log, "run", "a.R", "Ran")
  expect_equal(nrow(filter_log(log, from = "2099-01-01")), 0L)
})

test_that("filter_log(from) with far-past date includes all entries", {
  log <- regulog_init(app = "test", version = "0.1", user = "tester")
  log_action(log, "run", "a.R", "Ran")
  log_note(log, "A note")
  expect_equal(nrow(filter_log(log, from = "2000-01-01")), 2L)
})

test_that("filter_log(to) with far-past date excludes all entries", {
  log <- regulog_init(app = "test", version = "0.1", user = "tester")
  log_action(log, "run", "a.R", "Ran")
  expect_equal(nrow(filter_log(log, to = "2000-01-01")), 0L)
})

test_that("filter_log(to) with far-future date includes all entries", {
  log <- regulog_init(app = "test", version = "0.1", user = "tester")
  log_action(log, "run", "a.R", "Ran")
  log_note(log, "A note")
  expect_equal(nrow(filter_log(log, to = "2099-12-31")), 2L)
})

test_that("filter_log(from, to) includes entries within the window", {
  log <- regulog_init(app = "test", version = "0.1", user = "tester")
  log_action(log, "run", "a.R", "Ran")
  expect_equal(nrow(filter_log(log, from = "2000-01-01", to = "2099-12-31")), 1L)
})

test_that("filter_log(from, to) excludes entries outside the window", {
  log <- regulog_init(app = "test", version = "0.1", user = "tester")
  log_action(log, "run", "a.R", "Ran")
  expect_equal(nrow(filter_log(log, from = "2099-01-01", to = "2099-12-31")), 0L)
})

# ── filter_log() — file path ──────────────────────────────────────────────────

test_that("filter_log() reads entries from a .rlog file path", {
  tmp <- tempfile(fileext = ".rlog")
  on.exit(unlink(tmp))
  log <- regulog_init(app = "test", version = "0.1", user = "tester", path = tmp)
  log_action(log, "run", "a.R", "Ran")
  log_note(log, "A file-path note")
  log_signature(log, "Certified from file")

  df <- filter_log(tmp)
  expect_equal(nrow(df), 3L)
})

test_that("filter_log() applies type filter on file path", {
  tmp <- tempfile(fileext = ".rlog")
  on.exit(unlink(tmp))
  log <- regulog_init(app = "test", version = "0.1", user = "tester", path = tmp)
  log_action(log, "run", "a.R", "Ran")
  log_note(log, "File path note")

  df <- filter_log(tmp, type = "NOTE")
  expect_equal(nrow(df), 1L)
  expect_equal(df$type[[1L]], "NOTE")
})

test_that("filter_log() applies date filter on file path", {
  tmp <- tempfile(fileext = ".rlog")
  on.exit(unlink(tmp))
  log <- regulog_init(app = "test", version = "0.1", user = "tester", path = tmp)
  log_action(log, "run", "a.R", "Ran")

  expect_equal(nrow(filter_log(tmp, from = "2099-01-01")), 0L)
  expect_equal(nrow(filter_log(tmp, to = "2000-01-01")), 0L)
})

test_that("filter_log() errors on a missing file path", {
  expect_error(filter_log("/non/existent/file.rlog"), "not found")
})

test_that("filter_log() errors on non-regulog non-path input", {
  expect_error(filter_log(list(x = 1)))
  expect_error(filter_log(42L))
})
