# Example action function that shows the analysis structure

`example_action_fn()` shows how to structure an action function for the
`Plan` class. It prints the names of the data and argset components it
receives.

## Usage

``` r
example_action_fn(data, argset)
```

## Arguments

- data:

  A named list that holds the datasets for the analysis.

- argset:

  A named list that holds the arguments for the analysis.

## Value

NULL. `example_action_fn()` prints information about the input data and
argset.

## See also

[`vignette("adding_analyses")`](https://www.rwhite.no/plnr/articles/adding_analyses.md)
for worked single-function and multi-function plans. Those plans attach
an action function to a plan by `fn_name`.

Other example and test functions:
[`example_data_fn_nor_covid19_cases_by_time_location()`](https://www.rwhite.no/plnr/reference/example_data_fn_nor_covid19_cases_by_time_location.md),
[`test_action_fn()`](https://www.rwhite.no/plnr/reference/test_action_fn.md)

## Examples

``` r
# Create a new plan
p <- plnr::Plan$new()

# Add example data
p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")

# Create batch of argsets
batch_argset_list <- list(
  list(name = "analysis_1", var_1 = 1, var_2 = "i"),
  list(name = "analysis_2", var_1 = 2, var_2 = "j"),
  list(name = "analysis_3", var_1 = 3, var_2 = "k")
)

# Add analyses to plan
p$add_analysis_from_list(
  fn_name = "plnr::example_action_fn",
  l = batch_argset_list
)

# View argsets and run example
p$get_argsets_as_dt()
#>    name_analysis index_analysis  var_1  var_2
#>           <char>          <int> <list> <list>
#> 1:    analysis_1              1      1      i
#> 2:    analysis_2              2      2      j
#> 3:    analysis_3              3      3      k
p$run_one("analysis_1")
#> [1] "Data given:"
#> [1] "covid_data" "hash"      
#> [1] "Argset given:"
#> [1] "var_1"          "var_2"          "index_analysis"
#> [1] "var_1"          "var_2"          "index_analysis"
```
