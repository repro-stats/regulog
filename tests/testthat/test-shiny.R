# Mock Shiny session object — avoids needing a real Shiny server
.mock_session <- function(user = "testuser", token = "test-token-123") {
  ended_callbacks <- list()
  list(
    user  = user,
    token = token,
    onSessionEnded = function(fn) {
      ended_callbacks[[length(ended_callbacks) + 1L]] <<- fn
      invisible(NULL)
    },
    .fire_ended = function() {
      for (fn in ended_callbacks) fn()
    }
  )
}

test_that("regulog_shiny_init returns a regulog object", {
  skip_if_not_installed("shiny")
  session <- .mock_session(user = "jsmith", token = "tok-001")
  log <- regulog_shiny_init(session = session, app = "test-app", version = "1.0")
  expect_s3_class(log, "regulog")
  expect_equal(log$user, "jsmith")
  expect_equal(log$app,  "test-app")
})

test_that("regulog_shiny_init logs session_start automatically", {
  skip_if_not_installed("shiny")
  session <- .mock_session(user = "jsmith", token = "tok-002")
  log <- regulog_shiny_init(session = session, app = "test-app")
  expect_equal(length(log$entries), 1L)
  expect_equal(log$entries[[1L]]$action, "session_start")
  expect_equal(log$entries[[1L]]$object, "tok-002")
})

test_that("regulog_shiny_init logs session_end when session closes", {
  skip_if_not_installed("shiny")
  session <- .mock_session(user = "jsmith", token = "tok-003")
  log <- regulog_shiny_init(session = session, app = "test-app")
  session$.fire_ended()
  expect_equal(length(log$entries), 2L)
  expect_equal(log$entries[[2L]]$action, "session_end")
})

test_that("regulog_shiny_init warns when no path supplied", {
  skip_if_not_installed("shiny")
  session <- .mock_session()
  expect_warning(
    regulog_shiny_init(session = session, app = "test-app"),
    "no `path` supplied"
  )
})

test_that("regulog_shiny_init does not warn when path is supplied", {
  skip_if_not_installed("shiny")
  tmp <- withr::local_tempfile(fileext = ".rlog")
  session <- .mock_session()
  expect_no_warning(
    regulog_shiny_init(session = session, app = "test-app", path = tmp)
  )
})

test_that("regulog_shiny_init falls back to system user when session$user is NULL", {
  skip_if_not_installed("shiny")
  session <- .mock_session(user = NULL)
  expect_warning(
    log <- regulog_shiny_init(session = session, app = "test-app"),
    "session\\$user is NULL"
  )
  expect_equal(log$user, Sys.info()[["user"]])
})

test_that("regulog_shiny_init falls back to system user when session$user is empty", {
  skip_if_not_installed("shiny")
  session <- .mock_session(user = "")
  expect_warning(
    log <- regulog_shiny_init(session = session, app = "test-app"),
    "session\\$user is NULL"
  )
  expect_equal(log$user, Sys.info()[["user"]])
})

test_that("regulog_shiny_init persists to disk when path supplied", {
  skip_if_not_installed("shiny")
  tmp <- withr::local_tempfile(fileext = ".rlog")
  session <- .mock_session(user = "jsmith")
  regulog_shiny_init(session = session, app = "test-app", path = tmp)
  expect_true(file.exists(tmp))
  lines <- readLines(tmp, warn = FALSE)
  lines <- lines[nzchar(lines)]
  expect_gte(length(lines), 2L)  # genesis + session_start
})

test_that("regulog_shiny_init chain verifies after session lifecycle", {
  skip_if_not_installed("shiny")
  tmp <- withr::local_tempfile(fileext = ".rlog")
  session <- .mock_session(user = "jsmith")
  log <- regulog_shiny_init(session = session, app = "test-app", path = tmp)
  log_action(log, action = "approved", object = "item", reason = "ok")
  session$.fire_ended()
  result <- verify_log(log, verbose = FALSE)
  expect_true(result$intact)
  expect_equal(result$n_entries, 3L)  # session_start + approved + session_end
})

test_that(".require_shiny errors informatively when shiny not available", {
  # Simulate shiny not being installed by mocking requireNamespace
  mockery_available <- requireNamespace("mockery", quietly = TRUE)
  skip_if_not(mockery_available, "mockery not available")

  mockery::with_mock(
    requireNamespace = function(pkg, ...) if (pkg == "shiny") FALSE else TRUE,
    expect_error(.require_shiny(), "shiny.*required")
  )
})

test_that(".resolve_shiny_user returns session user when set", {
  session <- .mock_session(user = "analyst")
  expect_equal(.resolve_shiny_user(session), "analyst")
})

test_that(".resolve_shiny_user handles session$user access error gracefully", {
  bad_session <- list(
    user = stop("cannot access user"),
    token = "tok"
  )
  expect_warning(
    user <- .resolve_shiny_user(bad_session),
    "session\\$user is NULL"
  )
  expect_equal(user, Sys.info()[["user"]])
})