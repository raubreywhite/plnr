# Retry code execution with a random delay between attempts

`try_again()` runs code multiple times, with a random delay between
attempts. The delay is drawn from a uniform distribution on
`[delay_seconds_min, delay_seconds_max]` before every retry. It does not
grow with the attempt number, so this is not exponential backoff. Use it
for transient failures in operations that a later attempt can succeed
at, such as network requests or file operations.

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

  The code to run, as an expression.

- times:

  Integer. The maximum number of attempts to make. The default is 2.

- delay_seconds_min:

  Numeric. The minimum delay in seconds between attempts. The default is
  5.

- delay_seconds_max:

  Numeric. The maximum delay in seconds between attempts. The default is
  10.

- verbose:

  Logical. Whether to show progress information. The default is `FALSE`.

## Value

`TRUE`, invisibly, after an attempt succeeds. `try_again()` throws an
error with the last error message when every attempt fails.

## Details

`try_again()` is adapted from the `try_again` function in the testthat
package. It adds features that control the retry behavior and the
verbosity.

## See also

[`vignette("plnr")`](https://www.rwhite.no/plnr/articles/plnr.md) for an
introduction to the framework. `try_again()` is a general-purpose retry
helper. It is not part of the
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
