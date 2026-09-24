#' Retry code, with a random delay between attempts
#'
#' `try_again()` evaluates `x` up to `times` times, and stops at the first
#' attempt that raises no error. After each failed attempt it waits a number of
#' seconds drawn from a uniform distribution on
#' `[delay_seconds_min, delay_seconds_max]`. The delay does not grow with the
#' attempt number, so this is not exponential backoff.
#'
#' `try_again()` is adapted from `try_again()` in testthat. It adds the delay
#' and the `verbose` argument.
#'
#' @param x The code to run. `try_again()` evaluates it once for each attempt.
#' @param times The maximum number of attempts. The default is 2.
#' @param delay_seconds_min The shortest delay in seconds. The default is 5.
#' @param delay_seconds_max The longest delay in seconds. The default is 10.
#' @param verbose Logical. `TRUE` reports each failed attempt as a warning, and
#' a success after a retry as a message. The default is `FALSE`.
#' @return `TRUE`, invisibly, after the first attempt that succeeds. When every
#' attempt fails, `try_again()` signals the error of the last attempt.
#' @examples
#' try_again(1 + 1)
#'
#' # Fail once, then succeed. The delays are 0 so that the example runs fast.
#' attempt_n <- 0
#' try_again(
#'   {
#'     attempt_n <- attempt_n + 1
#'     if (attempt_n < 2) stop("not ready yet")
#'   },
#'   times = 3,
#'   delay_seconds_min = 0,
#'   delay_seconds_max = 0
#' )
#' attempt_n
#' @family utilities
#' @seealso `vignette("plnr")` for the concepts. `try_again()` itself is not
#' part of the [Plan] workflow.
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
        return(err)
      },
      error = function(err) {
        return(err)
      }
    )

    if (is.null(err)) {
      if (i > 1 && verbose) {
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
