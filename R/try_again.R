#' Retry code execution with exponential backoff
#'
#' This function attempts to execute code multiple times with random delays between
#' attempts. It's particularly useful for handling transient failures in operations
#' that may succeed on subsequent attempts, such as network requests or file operations.
#'
#' The function is adapted from the `try_again` function in the testthat package,
#' but with additional features for controlling retry behavior and verbosity.
#'
#' @param x The code to execute (as an expression)
#' @param times Integer, the maximum number of attempts to make. Defaults to 2
#' @param delay_seconds_min Numeric, the minimum delay in seconds between attempts.
#' Defaults to 5
#' @param delay_seconds_max Numeric, the maximum delay in seconds between attempts.
#' Defaults to 10
#' @param verbose Logical, whether to show progress information. Defaults to `FALSE`
#' @return `TRUE` invisibly if successful, otherwise throws an error with the last
#' error message
#' @examples
#' # A call that succeeds on the first attempt returns immediately
#' print(try_again(1 + 1))
#'
#' # A call that fails once and then succeeds on the second attempt. The delays
#' # are set to zero so the example runs instantly; they default to 5-10 seconds.
#' attempt_n <- 0
#' try_again(
#'   {
#'     attempt_n <- attempt_n + 1
#'     if (attempt_n < 2) stop("not ready yet")
#'     "succeeded"
#'   },
#'   times = 3,
#'   delay_seconds_min = 0,
#'   delay_seconds_max = 0
#' )
#'
#' # The expression really was evaluated twice
#' attempt_n
#' @seealso `vignette("plnr")` for an introduction to the framework. This is a
#' general-purpose retry helper and is not part of the [Plan] workflow.
#' @export
try_again <- function(
  x,
  times = 2,
  delay_seconds_min = 5,
  delay_seconds_max = 10,
  verbose = FALSE
) {
  i <- 1
  while (i <= times) {
    err <- tryCatch(
      withCallingHandlers(
        {
          x
          NULL
        },
        warning = function(err) {
          if (
            identical(err$message, "restarting interrupted promise evaluation")
          ) {
            if (!is.null(findRestart("muffleWarning"))) {
              invokeRestart("muffleWarning")
            }
          }
        }
      ),
      expectation_failure = function(err) {
        err
      },
      error = function(err) {
        err
      }
    )

    if (is.null(err)) {
      if (i > 1 & verbose) {
        message(i, "/", times, ": Succeeded.")
      }
      return(invisible(TRUE))
    }

    if (verbose) {
      warning(i, "/", times, ": Failed", call. = FALSE, immediate. = TRUE)
    }
    Sys.sleep(stats::runif(1, delay_seconds_min, delay_seconds_max))
    i <- i + 1L
  }
  stop(err)
}
