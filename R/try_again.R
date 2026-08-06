#' Retry code execution with exponential backoff
#'
#' `try_again()` runs code multiple times, with a random delay between attempts.
#' Use it for transient failures in operations that a later attempt can succeed
#' at, such as network requests or file operations.
#'
#' `try_again()` is adapted from the `try_again` function in the testthat
#' package. It adds features that control the retry behavior and the verbosity.
#'
#' @param x The code to run, as an expression.
#' @param times Integer. The maximum number of attempts to make. The default
#' is 2.
#' @param delay_seconds_min Numeric. The minimum delay in seconds between
#' attempts. The default is 5.
#' @param delay_seconds_max Numeric. The maximum delay in seconds between
#' attempts. The default is 10.
#' @param verbose Logical. Whether to show progress information. The default is
#' `FALSE`.
#' @return `TRUE`, invisibly, after an attempt succeeds. `try_again()` throws an
#' error with the last error message when every attempt fails.
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
#' @seealso `vignette("plnr")` for an introduction to the framework.
#' `try_again()` is a general-purpose retry helper. It is not part of the [Plan]
#' workflow.
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
