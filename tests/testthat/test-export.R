test_that("CSV export returns a data frame with required columns", {
  log <- regulog_init(app = "test-app", user = "tester")
  log_action(log, action = "approved", object = "f.csv", reason = "ok")
  log_change(log, object = "rec", field = "val",
             before = "a", after = "b", reason = "fix")

  df <- export_audit_trail(log, format = "csv")

  expect_s3_class(df, "data.frame")
  expect_equal(nrow(df), 2L)

  required_cols <- c("entry_id", "timestamp", "app", "app_version", "user",
                      "type", "reason", "entry_hash", "prev_hash")
  expect_true(all(required_cols %in% names(df)))
})

test_that("CSV export: ACTION rows have action field, CHANGE rows have field/before/after", {
  log <- regulog_init(app = "test-app", user = "tester")
  log_action(log, action = "approved", object = "f.csv", reason = "ok")
  log_change(log, object = "rec", field = "status",
             before = "draft", after = "final", reason = "fix")

  df <- export_audit_trail(log, format = "csv")

  action_row <- df[df$type == "ACTION", ]
  change_row <- df[df$type == "CHANGE", ]

  expect_equal(action_row$action, "approved")
  expect_true(is.na(action_row$field))

  expect_equal(change_row$field,  "status")
  expect_equal(change_row$before, "draft")
  expect_equal(change_row$after,  "final")
})

test_that("signed CSV export includes chain_intact and verified_at", {
  log <- regulog_init(app = "test-app", user = "tester")
  log_action(log, action = "approved", object = "f", reason = "ok")

  df <- export_audit_trail(log, format = "csv", signed = TRUE)

  expect_true("chain_intact" %in% names(df))
  expect_true("verified_at"  %in% names(df))
  expect_true(isTRUE(df$chain_intact[[1L]]))
  expect_true(nzchar(df$verified_at[[1L]]))
})

test_that("signed CSV export flags tampered log", {
  log <- regulog_init(app = "test-app", user = "tester")
  log_action(log, action = "approved", object = "f", reason = "ok")
  log$entries[[1L]]$action <- "TAMPERED"

  df <- suppressWarnings(export_audit_trail(log, format = "csv", signed = TRUE))
  expect_false(isTRUE(df$chain_intact[[1L]]))
})

test_that("JSON export has envelope with metadata", {
  log <- regulog_init(app = "test-app", user = "tester")
  log_action(log, action = "approved", object = "f", reason = "ok")

  env <- export_audit_trail(log, format = "json")

  expect_true(!is.null(env$export_metadata))
  expect_true(!is.null(env$export_metadata$exported_at))
  expect_equal(env$export_metadata$app, "test-app")
  expect_equal(env$export_metadata$entry_count, 1L)
  expect_equal(length(env$entries), 1L)
})

test_that("date filter `from` excludes earlier entries", {
  log <- regulog_init(app = "test-app", user = "tester")
  log_action(log, action = "approved", object = "f", reason = "ok")

  df <- export_audit_trail(log, format = "csv", from = "2099-01-01")
  expect_equal(nrow(df), 0L)
})

test_that("date filter `to` excludes later entries", {
  log <- regulog_init(app = "test-app", user = "tester")
  log_action(log, action = "approved", object = "f", reason = "ok")

  df <- export_audit_trail(log, format = "csv", to = "2000-01-01")
  expect_equal(nrow(df), 0L)
})

test_that("export writes CSV to disk when path is supplied", {
  log <- regulog_init(app = "test-app", user = "tester")
  log_action(log, action = "approved", object = "f", reason = "ok")

  tmp <- withr::local_tempfile(fileext = ".csv")
  export_audit_trail(log, format = "csv", path = tmp)

  expect_true(file.exists(tmp))
  on_disk <- utils::read.csv(tmp)
  expect_equal(nrow(on_disk), 1L)
})

test_that("export writes JSON to disk when path is supplied", {
  log <- regulog_init(app = "test-app", user = "tester")
  log_action(log, action = "approved", object = "f", reason = "ok")

  tmp <- withr::local_tempfile(fileext = ".json")
  export_audit_trail(log, format = "json", path = tmp)

  expect_true(file.exists(tmp))
  parsed <- jsonlite::fromJSON(tmp)
  expect_equal(parsed$export_metadata$entry_count, 1L)
})

test_that("empty log exports to 0-row data frame without error", {
  log <- regulog_init(app = "test-app", user = "tester")
  df  <- export_audit_trail(log, format = "csv")
  expect_s3_class(df, "data.frame")
  expect_equal(nrow(df), 0L)
})
