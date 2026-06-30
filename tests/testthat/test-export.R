test_that("CSV export returns a data frame with required columns", {
  log <- regulog_init(app = "test-app", user = "tester")
  log_action(log, action = "approved", object = "f.csv", reason = "ok")
  log_change(log,
    object = "rec", field = "val",
    before = "a", after = "b", reason = "fix"
  )

  df <- export_audit_trail(log, format = "csv")

  expect_s3_class(df, "data.frame")
  expect_equal(nrow(df), 2L)

  required_cols <- c(
    "entry_id", "timestamp", "app", "app_version", "user",
    "type", "reason", "entry_hash", "prev_hash"
  )
  expect_true(all(required_cols %in% names(df)))
})

test_that("CSV export: ACTION rows have action field, CHANGE rows have field/before/after", {
  log <- regulog_init(app = "test-app", user = "tester")
  log_action(log, action = "approved", object = "f.csv", reason = "ok")
  log_change(log,
    object = "rec", field = "status",
    before = "draft", after = "final", reason = "fix"
  )

  df <- export_audit_trail(log, format = "csv")

  action_row <- df[df$type == "ACTION", ]
  change_row <- df[df$type == "CHANGE", ]

  expect_equal(action_row$action, "approved")
  expect_true(is.na(action_row$field))

  expect_equal(change_row$field, "status")
  expect_equal(change_row$before, "draft")
  expect_equal(change_row$after, "final")
})

test_that("signed CSV export includes chain_intact and verified_at", {
  log <- regulog_init(app = "test-app", user = "tester")
  log_action(log, action = "approved", object = "f", reason = "ok")

  df <- export_audit_trail(log, format = "csv", signed = TRUE)

  expect_true("chain_intact" %in% names(df))
  expect_true("verified_at" %in% names(df))
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

test_that("export from .rlog file path works for CSV", {
  tmp_log <- withr::local_tempfile(fileext = ".rlog")
  tmp_csv <- withr::local_tempfile(fileext = ".csv")
  log <- regulog_init(app = "test-app", user = "tester", path = tmp_log)
  log_action(log, action = "approved", object = "f", reason = "ok")

  df <- export_audit_trail(tmp_log, format = "csv", path = tmp_csv)
  expect_s3_class(df, "data.frame")
  expect_equal(nrow(df), 1L)
  expect_true(file.exists(tmp_csv))
})

test_that("export from .rlog file path works for JSON", {
  tmp_log <- withr::local_tempfile(fileext = ".rlog")
  log <- regulog_init(app = "test-app", user = "tester", path = tmp_log)
  log_action(log, action = "approved", object = "f", reason = "ok")

  env <- export_audit_trail(tmp_log, format = "json")
  expect_equal(env$export_metadata$app, "test-app")
})

test_that("export errors on invalid log argument", {
  expect_error(export_audit_trail(123), "`log` must be")
})

test_that("include_genesis = TRUE includes genesis record", {
  tmp <- withr::local_tempfile(fileext = ".rlog")
  log <- regulog_init(app = "test-app", user = "tester", path = tmp)
  log_action(log, action = "a", object = "o", reason = "r")
  df_with <- export_audit_trail(tmp, format = "csv", include_genesis = TRUE)
  df_without <- export_audit_trail(tmp, format = "csv", include_genesis = FALSE)
  expect_equal(nrow(df_with), nrow(df_without) + 1L)
})

test_that("date filter `to` keeps entries before cutoff", {
  log <- regulog_init(app = "test-app", user = "tester")
  log_action(log, action = "a", object = "o", reason = "r")
  df <- export_audit_trail(log, format = "csv", to = "2099-12-31")
  expect_equal(nrow(df), 1L)
})

test_that("signed JSON export includes chain_intact in envelope", {
  log <- regulog_init(app = "test-app", user = "tester")
  log_action(log, action = "a", object = "o", reason = "r")
  env <- export_audit_trail(log, format = "json", signed = TRUE)
  expect_true(!is.null(env$export_metadata$chain_intact))
  expect_true(isTRUE(env$export_metadata$chain_intact))
})

test_that("empty log JSON export has zero entry_count", {
  log <- regulog_init(app = "test-app", user = "tester")
  env <- export_audit_trail(log, format = "json")
  expect_equal(env$export_metadata$entry_count, 0L)
})

test_that("empty signed CSV export includes chain_intact column", {
  log <- regulog_init(app = "test-app", user = "tester")
  df <- export_audit_trail(log, format = "csv", signed = TRUE)
  expect_true("chain_intact" %in% names(df))
})

test_that("export_audit_trail errors on invalid log type", {
  expect_error(export_audit_trail(42, format = "csv"), "regulog.*path")
})

test_that("export_audit_trail include_genesis=TRUE includes genesis row", {
  tmp <- withr::local_tempfile(fileext = ".rlog")
  log <- regulog_init(app = "test-app", user = "tester", path = tmp)
  log_action(log, action = "a", object = "o", reason = "r")
  df_with <- export_audit_trail(tmp, format = "csv", include_genesis = TRUE)
  df_without <- export_audit_trail(tmp, format = "csv", include_genesis = FALSE)
  expect_equal(nrow(df_with), nrow(df_without) + 1L)
})

test_that("export_audit_trail works from a .rlog file path", {
  tmp <- withr::local_tempfile(fileext = ".rlog")
  log <- regulog_init(app = "test-app", user = "tester", path = tmp)
  log_action(log, action = "approved", object = "f", reason = "ok")
  df <- export_audit_trail(tmp, format = "csv")
  expect_s3_class(df, "data.frame")
  expect_equal(nrow(df), 1L)
})

test_that("export_audit_trail `to` date filter excludes later entries", {
  log <- regulog_init(app = "test-app", user = "tester")
  log_action(log, action = "a", object = "o", reason = "r")
  df <- export_audit_trail(log, format = "csv", to = "2000-01-01")
  expect_equal(nrow(df), 0L)
})

test_that("export_audit_trail from+to both applied", {
  log <- regulog_init(app = "test-app", user = "tester")
  log_action(log, action = "a", object = "o", reason = "r")
  df <- export_audit_trail(log,
    format = "csv",
    from = "2000-01-01", to = "2099-12-31"
  )
  expect_equal(nrow(df), 1L)
})

test_that("signed JSON export includes chain_intact in metadata", {
  log <- regulog_init(app = "test-app", user = "tester")
  log_action(log, action = "approved", object = "f", reason = "ok")
  env <- export_audit_trail(log, format = "json", signed = TRUE)
  expect_true(!is.null(env$export_metadata$chain_intact))
  expect_true(isTRUE(env$export_metadata$chain_intact))
})

test_that("JSON export message uses 'ies' for multiple entries", {
  log <- regulog_init(app = "test-app", user = "tester")
  log_action(log, action = "a1", object = "o", reason = "r1")
  log_action(log, action = "a2", object = "o", reason = "r2")
  tmp <- withr::local_tempfile(fileext = ".json")
  expect_message(
    export_audit_trail(log, format = "json", path = tmp),
    "entries"
  )
})

test_that("JSON export message uses 'y' for single entry", {
  log <- regulog_init(app = "test-app", user = "tester")
  log_action(log, action = "a", object = "o", reason = "r")
  tmp <- withr::local_tempfile(fileext = ".json")
  expect_message(
    export_audit_trail(log, format = "json", path = tmp),
    "entry"
  )
})

test_that("empty signed CSV export has chain_intact column", {
  log <- regulog_init(app = "test-app", user = "tester")
  df <- export_audit_trail(log, format = "csv", signed = TRUE)
  expect_true("chain_intact" %in% names(df))
  expect_equal(nrow(df), 0L)
})

# --- Missing branch coverage ---

test_that("export_audit_trail errors on invalid log argument", {
  expect_error(export_audit_trail(42, format = "csv"), "`log` must be")
})

test_that("export_audit_trail works from a .rlog file path", {
  tmp <- withr::local_tempfile(fileext = ".rlog")
  log <- regulog_init(app = "test-app", user = "tester", path = tmp)
  log_action(log, action = "approved", object = "f", reason = "ok")
  df <- export_audit_trail(tmp, format = "csv")
  expect_s3_class(df, "data.frame")
  expect_equal(nrow(df), 1L)
})

test_that("export_audit_trail signed=TRUE on empty log CSV has correct columns", {
  log <- regulog_init(app = "test-app", user = "tester")
  df <- export_audit_trail(log, format = "csv", signed = TRUE)
  expect_s3_class(df, "data.frame")
  expect_equal(nrow(df), 0L)
  expect_true("chain_intact" %in% names(df))
  expect_true("verified_at" %in% names(df))
})

test_that("export_audit_trail JSON with multiple entries uses plural message", {
  log <- regulog_init(app = "test-app", user = "tester")
  log_action(log, action = "a1", object = "o", reason = "r1")
  log_action(log, action = "a2", object = "o", reason = "r2")
  tmp <- withr::local_tempfile(fileext = ".json")
  expect_message(
    export_audit_trail(log, format = "json", path = tmp),
    "entries"
  )
})

test_that("export_audit_trail `to` date filter excludes future entries", {
  log <- regulog_init(app = "test-app", user = "tester")
  log_action(log, action = "a", object = "o", reason = "r")
  df <- export_audit_trail(log, format = "csv", to = "2000-01-01")
  expect_equal(nrow(df), 0L)
})

test_that("export_audit_trail `to` filter includes entries on or before date", {
  log <- regulog_init(app = "test-app", user = "tester")
  log_action(log, action = "a", object = "o", reason = "r")
  df <- export_audit_trail(log, format = "csv", to = "2099-12-31")
  expect_equal(nrow(df), 1L)
})

test_that("export_audit_trail include_genesis=TRUE adds genesis row", {
  tmp <- withr::local_tempfile(fileext = ".rlog")
  log <- regulog_init(app = "test-app", user = "tester", path = tmp)
  log_action(log, action = "a", object = "o", reason = "r")
  df_with <- export_audit_trail(tmp, format = "csv", include_genesis = TRUE)
  df_without <- export_audit_trail(tmp, format = "csv", include_genesis = FALSE)
  expect_equal(nrow(df_with), nrow(df_without) + 1L)
})

test_that("export_audit_trail signed JSON includes chain_intact in metadata", {
  log <- regulog_init(app = "test-app", user = "tester")
  log_action(log, action = "a", object = "o", reason = "r")
  env <- export_audit_trail(log, format = "json", signed = TRUE)
  expect_true(!is.null(env$export_metadata$chain_intact))
  expect_true(isTRUE(env$export_metadata$chain_intact))
})
