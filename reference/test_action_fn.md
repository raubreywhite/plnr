# Test action function that returns a constant value

`test_action_fn()` always returns 1. Use it to test the `Plan`
framework.

## Usage

``` r
test_action_fn(data, argset)
```

## Arguments

- data:

  A named list that holds the datasets. This example does not use it.

- argset:

  A named list that holds the arguments. This example does not use it.

## Value

The integer 1

## See also

[`vignette("plnr")`](https://www.rwhite.no/plnr/articles/plnr.md) for
the `data`/`argset` contract. An action function MUST accept at least
the supplied data and argset values. It MAY take further arguments. A
directly supplied `fn` receives the argset positionally, so its second
formal need not be named `argset`.

Other example and test functions:
[`example_action_fn()`](https://www.rwhite.no/plnr/reference/example_action_fn.md),
[`example_data_fn_nor_covid19_cases_by_time_location()`](https://www.rwhite.no/plnr/reference/example_data_fn_nor_covid19_cases_by_time_location.md)

## Examples

``` r
# Called directly, it ignores both arguments and returns 1
test_action_fn(data = list(), argset = list())
#> [1] 1

# Its intended use is as a placeholder action function inside a plan
p <- plnr::Plan$new()
p$add_data(
  name = "deaths",
  direct = data.table::data.table(deaths = 1:4, year = 2001:2004)
)
p$add_analysis(name = "analysis_1", fn_name = "plnr::test_action_fn")
p$run_one("analysis_1")
#> [1] 1
```
