# Retry code execution with exponential backoff

This function attempts to execute code multiple times with random delays
between attempts. It's particularly useful for handling transient
failures in operations that may succeed on subsequent attempts, such as
network requests or file operations.

## Usage

``` r
try_again(
  x,
  times = 2,
  delay_seconds_min = 5,
  delay_seconds_max = 10,
  verbose = FALSE
)
```

## Arguments

- x:

  The code to execute (as an expression)

- times:

  Integer, the maximum number of attempts to make. Defaults to 2

- delay_seconds_min:

  Numeric, the minimum delay in seconds between attempts. Defaults to 5

- delay_seconds_max:

  Numeric, the maximum delay in seconds between attempts. Defaults to 10

- verbose:

  Logical, whether to show progress information. Defaults to `FALSE`

## Value

`TRUE` invisibly if successful, otherwise throws an error with the last
error message

## Details

The function is adapted from the `try_again` function in the testthat
package, but with additional features for controlling retry behavior and
verbosity.

## See also

[`vignette("plnr")`](https://www.rwhite.no/plnr/articles/plnr.md) for an
introduction to the framework. This is a general-purpose retry helper
and is not part of the
[Plan](https://www.rwhite.no/plnr/reference/Plan.md) workflow.

## Examples

``` r
# A call that succeeds on the first attempt returns immediately
print(try_again(1 + 1))
#> [1] TRUE

# A call that fails once and then succeeds on the second attempt. The delays
# are set to zero so the example runs instantly; they default to 5-10 seconds.
attempt_n <- 0
try_again(
  {
    attempt_n <- attempt_n + 1
    if (attempt_n < 2) stop("not ready yet")
    "succeeded"
  },
  times = 3,
  delay_seconds_min = 0,
  delay_seconds_max = 0
)

# The expression really was evaluated twice
attempt_n
#> [1] 2
```
