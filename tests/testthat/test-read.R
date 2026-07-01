# test-read.R
# Tests for rl_read() and with_log() -- the explicit, call-site logging
# design that replaced namespace-patching (formerly log_hooks_enable() /
# log_hooks_disable(), tested in the now-removed test-hooks.R).


# ── rl_read() ─────────────────────────────────────────────────────────────────

test_that("rl_read() requires a regulog object", {
  expect_error(rl_read("not a log", utils::read.csv, "x.csv"))
  expect_error(rl_read(list(), utils::read.csv, "x.csv"))
  expect_error(rl_read(NULL, utils::read.csv, "x.csv"))
})

test_that("rl_read() requires reader to be a function", {
  log <- regulog_init(app = "test", version = "0.1", user = "tester")
  expect_error(rl_read(log, "not a function", "x.csv"))
  expect_error(rl_read(log, 42L, "x.csv"))
})

test_that("rl_read() returns the result of calling reader()", {
  tmp <- tempfile(fileext = ".csv")
  utils::write.csv(data.frame(x = 1:5, y = letters[1:5]), tmp, row.names = FALSE)
  on.exit(unlink(tmp))

  log <- regulog_init(app = "test", version = "0.1", user = "tester")
  result <- rl_read(log, utils::read.csv, tmp)

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 5L)
})

test_that("rl_read() logs a data_read ACTION entry", {
  tmp <- tempfile(fileext = ".csv")
  utils::write.csv(data.frame(x = 1:5, y = letters[1:5]), tmp, row.names = FALSE)
  on.exit(unlink(tmp))

  log <- regulog_init(app = "test", version = "0.1", user = "tester")
  rl_read(log, utils::read.csv, tmp)

  entries <- filter_log(log, action = "data_read")
  expect_equal(nrow(entries), 1L)
  expect_equal(entries$type[[1L]], "ACTION")
  expect_equal(entries$action[[1L]], "data_read")
})

test_that("rl_read() records the correct path from a positional argument", {
  tmp <- tempfile(fileext = ".csv")
  utils::write.csv(data.frame(x = 1), tmp, row.names = FALSE)
  on.exit(unlink(tmp))

  log <- regulog_init(app = "test", version = "0.1", user = "tester")
  rl_read(log, utils::read.csv, tmp)

  entries <- filter_log(log, action = "data_read")
  expect_equal(entries$object[[1L]], tmp)
})

test_that("rl_read() records the correct path from a named argument, regardless of position", {
  skip_if_not_installed("readr")
  tmp <- tempfile(fileext = ".csv")
  utils::write.csv(data.frame(x = 1, y = 2), tmp, row.names = FALSE)
  on.exit(unlink(tmp))

  log <- regulog_init(app = "test", version = "0.1", user = "tester")

  # Named argument supplied before the file path -- a purely positional
  # extraction would record the wrong value here.
  rl_read(log, readr::read_csv, col_types = "dd", file = tmp, show_col_types = FALSE)

  entries <- filter_log(log, action = "data_read")
  expect_equal(entries$object[[1L]], tmp)
})

test_that("rl_read() falls back to 'unknown' when no path can be resolved", {
  log <- regulog_init(app = "test", version = "0.1", user = "tester")

  rl_read(log, function() data.frame(x = 1))

  entries <- filter_log(log, action = "data_read")
  expect_equal(entries$object[[1L]], "unknown")
})

test_that("rl_read() records nrow and ncol in the reason string for data.frame results", {
  tmp <- tempfile(fileext = ".csv")
  utils::write.csv(data.frame(a = 1:10, b = 1:10, c = 1:10), tmp, row.names = FALSE)
  on.exit(unlink(tmp))

  log <- regulog_init(app = "test", version = "0.1", user = "tester")
  rl_read(log, utils::read.csv, tmp)

  entries <- filter_log(log, action = "data_read")
  expect_match(entries$reason[[1L]], "10 rows")
  expect_match(entries$reason[[1L]], "3 cols")
})

test_that("rl_read() handles non-data.frame results without row/col counts", {
  log <- regulog_init(app = "test", version = "0.1", user = "tester")
  rl_read(log, function(...) "not a data frame", "irrelevant.txt")

  entries <- filter_log(log, action = "data_read")
  expect_false(grepl("rows", entries$reason[[1L]]))
})

test_that("rl_read() entries are hash-chained and verifiable", {
  tmp <- tempfile(fileext = ".csv")
  utils::write.csv(data.frame(x = 1:3), tmp, row.names = FALSE)
  on.exit(unlink(tmp))

  log <- regulog_init(app = "test", version = "0.1", user = "tester")
  rl_read(log, utils::read.csv, tmp)

  result <- verify_log(log, verbose = FALSE)
  expect_true(result$intact)
  expect_equal(result$n_entries, 1L)
})

test_that("multiple rl_read() calls chain correctly in sequence", {
  tmp1 <- tempfile(fileext = ".csv")
  tmp2 <- tempfile(fileext = ".csv")
  utils::write.csv(data.frame(x = 1), tmp1, row.names = FALSE)
  utils::write.csv(data.frame(y = 2), tmp2, row.names = FALSE)
  on.exit(unlink(c(tmp1, tmp2)))

  log <- regulog_init(app = "test", version = "0.1", user = "tester")
  rl_read(log, utils::read.csv, tmp1)
  rl_read(log, utils::read.csv, tmp2)

  result <- verify_log(log, verbose = FALSE)
  expect_true(result$intact)
  expect_equal(result$n_entries, 2L)
})


# ── with_log() ────────────────────────────────────────────────────────────────

test_that("with_log() requires a regulog object", {
  expect_error(with_log("not a log", {
    1 + 1
  }))
  expect_error(with_log(NULL, {
    1 + 1
  }))
})

test_that("with_log() returns the value of expr", {
  log <- regulog_init(app = "test", version = "0.1", user = "tester")
  result <- with_log(log, {
    42L
  })
  expect_equal(result, 42L)
})

test_that("with_log() exposes a local read() bound to the supplied log", {
  tmp <- tempfile(fileext = ".csv")
  utils::write.csv(data.frame(x = 1:3), tmp, row.names = FALSE)
  on.exit(unlink(tmp))

  log <- regulog_init(app = "test", version = "0.1", user = "tester")
  with_log(log, {
    df <- read(utils::read.csv, tmp)
  })

  entries <- filter_log(log, action = "data_read")
  expect_equal(nrow(entries), 1L)
  expect_equal(entries$object[[1L]], tmp)
})

test_that("with_log() propagates errors raised inside the block", {
  log <- regulog_init(app = "test", version = "0.1", user = "tester")
  expect_error(
    with_log(log, {
      stop("deliberate error")
    }),
    "deliberate error"
  )
})

test_that("with_log() preserves entries logged before an error inside the block", {
  log <- regulog_init(app = "test", version = "0.1", user = "tester")
  log_action(log, action = "setup", object = "init", reason = "Pre-block entry")

  tryCatch(
    with_log(log, {
      stop("deliberate error")
    }),
    error = function(e) NULL
  )

  result <- verify_log(log, verbose = FALSE)
  expect_true(result$intact)
  expect_equal(result$n_entries, 1L)
})

test_that("with_log()'s read() binding does not leak into the calling environment", {
  log <- regulog_init(app = "test", version = "0.1", user = "tester")
  with_log(log, {
    1 + 1
  })

  # `read` should not exist in this test's local frame after with_log() returns
  expect_false(exists("read", where = environment(), inherits = FALSE))
})

test_that("with_log() entries are hash-chained and verifiable", {
  tmp <- tempfile(fileext = ".csv")
  utils::write.csv(data.frame(x = 1:3), tmp, row.names = FALSE)
  on.exit(unlink(tmp))

  log <- regulog_init(app = "test", version = "0.1", user = "tester")
  with_log(log, {
    read(utils::read.csv, tmp)
  })

  result <- verify_log(log, verbose = FALSE)
  expect_true(result$intact)
  expect_equal(result$n_entries, 1L)
})

test_that("two independent with_log() calls on separate logs do not interfere", {
  tmp <- tempfile(fileext = ".csv")
  utils::write.csv(data.frame(x = 1), tmp, row.names = FALSE)
  on.exit(unlink(tmp))

  log_a <- regulog_init(app = "test", version = "0.1", user = "user_a")
  log_b <- regulog_init(app = "test", version = "0.1", user = "user_b")

  with_log(log_a, {
    read(utils::read.csv, tmp)
  })
  with_log(log_b, {
    read(utils::read.csv, tmp)
  })

  expect_equal(length(log_a$entries), 1L)
  expect_equal(length(log_b$entries), 1L)
  expect_equal(log_a$entries[[1L]]$user, "user_a")
  expect_equal(log_b$entries[[1L]]$user, "user_b")
})

test_that("with_log() can be nested without one block's log leaking into the other's read()", {
  tmp <- tempfile(fileext = ".csv")
  utils::write.csv(data.frame(x = 1), tmp, row.names = FALSE)
  on.exit(unlink(tmp))

  log_outer <- regulog_init(app = "test", version = "0.1", user = "outer")
  log_inner <- regulog_init(app = "test", version = "0.1", user = "inner")

  with_log(log_outer, {
    read(utils::read.csv, tmp)
    with_log(log_inner, {
      read(utils::read.csv, tmp)
    })
  })

  expect_equal(length(log_outer$entries), 1L)
  expect_equal(length(log_inner$entries), 1L)
})
