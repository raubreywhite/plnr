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

## Examples

``` r
if (FALSE) { # \dontrun{
# Try a simple operation
try_again({
  # Your code here
  stop("Simulated error")
}, times = 3, verbose = TRUE)

# Try with custom delays
try_again({
  # Your code here
  stop("Simulated error")
}, delay_seconds_min = 1, delay_seconds_max = 3)
} # }
```
