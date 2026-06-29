# Create a cross product of lists

This function creates a cross product of multiple lists, similar to
[`tidyr::expand_grid()`](https://tidyr.tidyverse.org/reference/expand_grid.html)
but with a more convenient interface that doesn't require wrapping
arguments in an extra [`list()`](https://rdrr.io/r/base/list.html). It's
useful for generating combinations of parameters for analysis.

## Usage

``` r
expand_list(...)
```

## Arguments

- ...:

  Named arguments, each containing a vector or list of values to combine

## Value

A list of lists, where each inner list contains one combination of
values from the input arguments

## Examples

``` r
# Create combinations of parameters
combinations <- plnr::expand_list(
  a = 1:2,
  b = c("a", "b")
)

# View the combinations
str(combinations)
#> List of 4
#>  $ :List of 2
#>   ..$ a: int 1
#>   ..$ b: chr "a"
#>  $ :List of 2
#>   ..$ a: int 1
#>   ..$ b: chr "b"
#>  $ :List of 2
#>   ..$ a: int 2
#>   ..$ b: chr "a"
#>  $ :List of 2
#>   ..$ a: int 2
#>   ..$ b: chr "b"

# Compare with tidyr::expand_grid
tidyr::expand_grid(list(
  a = 1:2,
  b = c("a", "b")
))
#> # A tibble: 2 × 1
#>   `list(a = 1:2, b = c("a", "b"))`
#>   <named list>                    
#> 1 <int [2]>                       
#> 2 <chr [2]>                       
```
