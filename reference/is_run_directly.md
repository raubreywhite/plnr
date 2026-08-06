# Check whether code runs directly, or from within a function

`is_run_directly()` reports whether the code runs directly in the global
environment, or from within a function call. Use it during development
and debugging. A function can then behave one way when you run it
directly, and another way when a larger analysis plan calls it.

## Usage

``` r
is_run_directly()
```

## Value

A logical value. `TRUE` means the code runs directly, from the global
environment. `FALSE` means the code runs from within a function call.

## See also

[`vignette("plnr")`](https://www.rwhite.no/plnr/articles/plnr.md). Its
"Debugging Tools" section calls `is_run_directly()` inside an action
function, to load `data` and `argset` while you develop that function.

## Examples

``` r
# When run directly
is_run_directly()  # TRUE
#> [1] FALSE

# When run from within a function
test_fn <- function() {
  is_run_directly()  # FALSE
}
test_fn()
#> [1] FALSE
```
