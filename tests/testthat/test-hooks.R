# ── log_hooks_enable() ───────────────────────────────────────────────────────

test_that("log_hooks_enable() requires a regulog object", {
  expect_error(log_hooks_enable("not a log"))
  expect_error(log_hooks_enable(list()))
  expect_error(log_hooks_enable(NULL))
})

test_that("log_hooks_enable() messages and returns early when hooks already active", {
  log      <- regulog_init(app = "test", version = "0.1", user = "tester")
  hook_env <- getFromNamespace(".rl_hooks", "regulog")

  hook_env$log <- log
  on.exit({
    hook_env$log       <- NULL
    hook_env$originals <- list()
  })

  expect_message(log_hooks_enable(log), "already active")
})

test_that("log_hooks_enable() skips namespaces that are not loaded", {
  log <- regulog_init(app = "test", version = "0.1", user = "tester")
  # Only utils is guaranteed to be loaded; haven/readr/data.table may not be.
  # Enabling should succeed without error regardless.
  expect_no_error(suppressMessages(log_hooks_enable(log)))
  suppressMessages(log_hooks_disable())
})

test_that("log_hooks_enable() messages how many functions were patched", {
  log <- regulog_init(app = "test", version = "0.1", user = "tester")
  # Message always emitted, even if 0 functions were patched
  expect_message(log_hooks_enable(log), "patched")
  suppressMessages(log_hooks_disable())
})

# ── log_hooks_disable() ───────────────────────────────────────────────────────

test_that("log_hooks_disable() is safe when hooks were never enabled", {
  expect_no_error(suppressMessages(log_hooks_disable()))
})

test_that("log_hooks_disable() clears log and originals", {
  log      <- regulog_init(app = "test", version = "0.1", user = "tester")
  hook_env <- getFromNamespace(".rl_hooks", "regulog")

  suppressMessages(log_hooks_enable(log))
  suppressMessages(log_hooks_disable())

  expect_null(hook_env$log)
  expect_length(hook_env$originals, 0L)
})

test_that("log_hooks_disable() messages when it restores functions", {
  hook_env <- getFromNamespace(".rl_hooks", "regulog")
  hook_env$originals[["utils::read.csv"]] <- function(x) x
  hook_env$log <- regulog_init(app = "test", version = "0.1", user = "tester")
  on.exit({
    hook_env$log       <- NULL
    hook_env$originals <- list()
  })

  expect_message(log_hooks_disable(), "hooks disabled")
  expect_null(hook_env$log)
  expect_length(hook_env$originals, 0L)
})

test_that("log_hooks_disable() skips NULL entries in originals (patch failed)", {
  hook_env <- getFromNamespace(".rl_hooks", "regulog")
  hook_env$originals[["utils::read.csv"]] <- NULL
  hook_env$log <- regulog_init(app = "test", version = "0.1", user = "tester")

  expect_no_error(suppressMessages(log_hooks_disable()))
  expect_null(hook_env$log)
})

# ── with_log() ────────────────────────────────────────────────────────────────

test_that("with_log() disables hooks on normal exit", {
  log      <- regulog_init(app = "test", version = "0.1", user = "tester")
  hook_env <- getFromNamespace(".rl_hooks", "regulog")

  suppressMessages(with_log(log, { 1 + 1 }))
  expect_null(hook_env$log)
})

test_that("with_log() disables hooks on error", {
  log      <- regulog_init(app = "test", version = "0.1", user = "tester")
  hook_env <- getFromNamespace(".rl_hooks", "regulog")

  tryCatch(
    suppressMessages(with_log(log, { stop("deliberate error") })),
    error = function(e) NULL
  )
  expect_null(hook_env$log)
})

test_that("with_log() returns value of expr", {
  log <- regulog_init(app = "test", version = "0.1", user = "tester")
  result <- suppressMessages(with_log(log, { 42L }))
  expect_equal(result, 42L)
})

# ── wrapper body — requires readr to patch and call ──────────────────────────

test_that("wrapper logs a data_read ACTION when a hooked read function is called", {
  skip_if_not_installed("readr")

  tmp <- tempfile(fileext = ".csv")
  write.csv(data.frame(x = 1:5, y = letters[1:5]), tmp, row.names = FALSE)
  on.exit(unlink(tmp))

  log <- regulog_init(app = "test", version = "0.1", user = "tester")

  suppressMessages(log_hooks_enable(log))
  df <- readr::read_csv(tmp, show_col_types = FALSE)
  suppressMessages(log_hooks_disable())

  entries <- filter_log(log, action = "data_read")
  expect_gte(nrow(entries), 1L)
  expect_equal(entries$type[[1L]],   "ACTION")
  expect_equal(entries$action[[1L]], "data_read")
  expect_true(grepl(basename(tmp), entries$reason[[1L]]))
})

test_that("wrapper records nrow and ncol in the reason string", {
  skip_if_not_installed("readr")

  tmp <- tempfile(fileext = ".csv")
  write.csv(data.frame(a = 1:10, b = 1:10, c = 1:10), tmp, row.names = FALSE)
  on.exit(unlink(tmp))

  log <- regulog_init(app = "test", version = "0.1", user = "tester")

  suppressMessages(log_hooks_enable(log))
  readr::read_csv(tmp, show_col_types = FALSE)
  suppressMessages(log_hooks_disable())

  entries <- filter_log(log, action = "data_read")
  expect_match(entries$reason[[1L]], "10 rows")
  expect_match(entries$reason[[1L]], "3 cols")
})

test_that("hooked read entries are hash-chained and verifiable", {
  skip_if_not_installed("readr")

  tmp <- tempfile(fileext = ".csv")
  write.csv(data.frame(x = 1:3), tmp, row.names = FALSE)
  on.exit(unlink(tmp))

  log <- regulog_init(app = "test", version = "0.1", user = "tester")

  suppressMessages(with_log(log, {
    readr::read_csv(tmp, show_col_types = FALSE)
  }))

  result <- verify_log(log, verbose = FALSE)
  expect_true(result$intact)
  expect_gte(result$n_entries, 1L)
})
