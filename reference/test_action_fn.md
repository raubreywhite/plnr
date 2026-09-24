# Return 1, whatever the input

`test_action_fn()` is a placeholder action function. It ignores its
arguments.

## Usage

``` r
test_action_fn(data, argset)
```

## Arguments

- data:

  Not used.

- argset:

  Not used.

## Value

The number 1, a double.

## See also

[`vignette("plnr")`](https://www.rwhite.no/plnr/articles/plnr.md) for
what an action function is.

Other example and test functions:
[`example_action_fn()`](https://www.rwhite.no/plnr/reference/example_action_fn.md),
[`example_data_fn_nor_covid19_cases_by_time_location()`](https://www.rwhite.no/plnr/reference/example_data_fn_nor_covid19_cases_by_time_location.md)

## Examples

``` r
test_action_fn(data = list(), argset = list())
#> [1] 1

p <- plnr::Plan$new()
p$add_data(name = "deaths", direct = data.frame(deaths = 1:4, year = 2001:2004))
p$add_analysis(name = "analysis_1", fn_name = "plnr::test_action_fn")
p$run_one("analysis_1")
#> [1] 1
```
