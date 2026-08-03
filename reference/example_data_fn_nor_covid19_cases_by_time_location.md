# An example data_fn that returns a data set

An example data_fn that returns a data set

## Usage

``` r
example_data_fn_nor_covid19_cases_by_time_location()
```

## See also

[`vignette("adding_analyses")`](https://www.rwhite.no/plnr/articles/adding_analyses.md),
which defines the same kind of zero-argument `data_fn` and attaches it
to a plan with `fn_name`.

Other example and test functions:
[`example_action_fn()`](https://www.rwhite.no/plnr/reference/example_action_fn.md),
[`test_action_fn()`](https://www.rwhite.no/plnr/reference/test_action_fn.md)

## Examples

``` r
# A data function takes no arguments and returns one data set
d <- example_data_fn_nor_covid19_cases_by_time_location()
dim(d)
#> [1] 11028    18

# Its intended use is as an `fn_name` passed to Plan$add_data()
p <- plnr::Plan$new()
p$add_data(
  name = "covid19_cases",
  fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location"
)
names(p$get_data())
#> [1] "covid19_cases" "hash"         
```
