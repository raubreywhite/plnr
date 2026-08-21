# R6 Class for Planning and Executing Analyses

The `Plan` class organizes and runs multiple analyses on one or more
datasets. It enforces a structured approach to analysis in three ways.

1.  **Data Management**:

    - Load data once and reuse it across analyses

    - Keep data cleaning separate from analysis

    - Track data changes with a hash

2.  **Analysis Structure**:

    - Require all analyses to use the same data sources

    - Standardize analysis functions to accept only `data` and `argset`
      parameters

    - Organize analyses into clear, maintainable plans

3.  **Execution Control**:

    - Support both single-function and multi-function analysis plans

    - Run analyses either in sequence or in parallel

    - Supply built-in debugging tools

## Details

The framework uses three main concepts:

- **Argset**: A named list that holds a set of arguments for an analysis

- **Analysis**: A combination of one argset and one action function

- **Plan**: A container that holds one data pull and a list of analyses

## See also

[`vignette("plnr")`](https://www.rwhite.no/plnr/articles/plnr.md) for an
introduction to argsets, analyses and plans. See
[`vignette("adding_analyses")`](https://www.rwhite.no/plnr/articles/adding_analyses.md)
for worked single-function and multi-function plans.

## Public fields

- `analyses`:

  List of analyses. Each analysis holds one argset and one action
  function.

## Methods

### Public methods

- [`Plan$new()`](#method-Plan-initialize)

- [`Plan$add_data()`](#method-Plan-add_data)

- [`Plan$add_argset()`](#method-Plan-add_argset)

- [`Plan$add_argset_from_df()`](#method-Plan-add_argset_from_df)

- [`Plan$add_argset_from_list()`](#method-Plan-add_argset_from_list)

- [`Plan$add_analysis()`](#method-Plan-add_analysis)

- [`Plan$add_analysis_from_df()`](#method-Plan-add_analysis_from_df)

- [`Plan$add_analysis_from_list()`](#method-Plan-add_analysis_from_list)

- [`Plan$apply_action_fn_to_all_argsets()`](#method-Plan-apply_action_fn_to_all_argsets)

- [`Plan$apply_analysis_fn_to_all()`](#method-Plan-apply_analysis_fn_to_all)

- [`Plan$x_length()`](#method-Plan-x_length)

- [`Plan$x_seq_along()`](#method-Plan-x_seq_along)

- [`Plan$set_progress()`](#method-Plan-set_progress)

- [`Plan$set_progressor()`](#method-Plan-set_progressor)

- [`Plan$set_verbose()`](#method-Plan-set_verbose)

- [`Plan$set_use_foreach()`](#method-Plan-set_use_foreach)

- [`Plan$get_data()`](#method-Plan-get_data)

- [`Plan$get_analysis()`](#method-Plan-get_analysis)

- [`Plan$get_argset()`](#method-Plan-get_argset)

- [`Plan$get_argsets_as_dt()`](#method-Plan-get_argsets_as_dt)

- [`Plan$run_one_with_data()`](#method-Plan-run_one_with_data)

- [`Plan$run_one()`](#method-Plan-run_one)

- [`Plan$run_all_with_data()`](#method-Plan-run_all_with_data)

- [`Plan$run_all()`](#method-Plan-run_all)

- [`Plan$run_all_progress()`](#method-Plan-run_all_progress)

- [`Plan$run_all_parallel()`](#method-Plan-run_all_parallel)

- [`Plan$clone()`](#method-Plan-clone)

------------------------------------------------------------------------

### `Plan$new()`

Create a new Plan instance.

#### Usage

    Plan$new(verbose = interactive() | config$force_verbose, use_foreach = FALSE)

#### Arguments

- `verbose`:

  Logical. Whether to show verbose output. The default is `TRUE` in
  interactive mode, or when `config$force_verbose` is `TRUE`.

- `use_foreach`:

  Logical. Whether to use foreach for parallel processing. `NULL` lets
  the program decide. `FALSE` uses a loop. `TRUE` uses foreach.

#### Returns

A new Plan instance.

------------------------------------------------------------------------

### `Plan$add_data()`

Add a new dataset to the plan.

#### Usage

    Plan$add_data(name, fn = NULL, fn_name = NULL, direct = NULL)

#### Arguments

- `name`:

  Character string. The name of the dataset.

- `fn`:

  Optional. A function that returns the dataset.

- `fn_name`:

  Optional. A character string that names a function that returns the
  dataset.

- `direct`:

  Optional. The dataset object itself.

#### Returns

NULL. The method changes the plan in place.

#### Examples

    p <- plnr::Plan$new()

    # Add data using a function
    data_fn <- function() { return(plnr::nor_covid19_cases_by_time_location) }
    p$add_data("data_1", fn = data_fn)

    # Add data using a function name
    p$add_data("data_2", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")

    # Add data directly
    p$add_data("data_3", direct = plnr::nor_covid19_cases_by_time_location)

    # View added data
    p$get_data()

------------------------------------------------------------------------

### `Plan$add_argset()`

Add a new argset to the plan.

#### Usage

    Plan$add_argset(name = uuid::UUIDgenerate(), ...)

#### Arguments

- `name`:

  Character string. The name of the argset. The default is a UUID.

- `...`:

  Named arguments that make up the argset.

#### Returns

NULL. The method changes the plan in place.

#### Examples

    p <- plnr::Plan$new()

    # Add argsets with different arguments
    p$add_argset("argset_1", var_1 = 3, var_b = "hello")
    p$add_argset("argset_2", var_1 = 8, var_c = "hello2")

    # View added argsets
    p$get_argsets_as_dt()

------------------------------------------------------------------------

### `Plan$add_argset_from_df()`

Add multiple argsets from a data frame.

#### Usage

    Plan$add_argset_from_df(df)

#### Arguments

- `df`:

  A data frame. Each row is one new argset.

#### Returns

NULL. The method changes the plan in place.

#### Examples

    p <- plnr::Plan$new()

    # Create data frame of argsets
    batch_argset_df <- data.frame(
      name = c("a", "b", "c"),
      var_1 = c(1, 2, 3),
      var_2 = c("i", "j", "k")
    )

    # Add argsets from data frame
    p$add_argset_from_df(batch_argset_df)

    # View added argsets
    p$get_argsets_as_dt()

------------------------------------------------------------------------

### `Plan$add_argset_from_list()`

Add multiple argsets from a list.

#### Usage

    Plan$add_argset_from_list(l)

#### Arguments

- `l`:

  A list of lists. Each inner list is one new argset.

#### Returns

NULL. The method changes the plan in place.

#### Examples

    p <- plnr::Plan$new()

    # Create list of argsets
    batch_argset_list <- list(
      list(name = "a", var_1 = 1, var_2 = "i"),
      list(name = "b", var_1 = 2, var_2 = "j"),
      list(name = "c", var_1 = 3, var_2 = "k")
    )

    # Add argsets from list
    p$add_argset_from_list(batch_argset_list)

    # View added argsets
    p$get_argsets_as_dt()

------------------------------------------------------------------------

### `Plan$add_analysis()`

Add a new analysis to the plan.

#### Usage

    Plan$add_analysis(name = uuid::UUIDgenerate(), fn = NULL, fn_name = NULL, ...)

#### Arguments

- `name`:

  Character string. The name of the analysis. The default is a UUID.

- `fn`:

  Optional. The function to use for the analysis.

- `fn_name`:

  Optional. A character string that names the function to use.

- `...`:

  Further arguments to add to the argset.

#### Returns

NULL. The method changes the plan in place.

#### Examples

    p <- plnr::Plan$new()

    # Add example data
    p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")

    # Add analysis
    p$add_analysis(
      name = "analysis_1",
      fn_name = "plnr::example_action_fn"
    )

    # View argsets and run analysis
    p$get_argsets_as_dt()
    p$run_one("analysis_1")

------------------------------------------------------------------------

### `Plan$add_analysis_from_df()`

Add multiple analyses from a data frame.

#### Usage

    Plan$add_analysis_from_df(fn = NULL, fn_name = NULL, df)

#### Arguments

- `fn`:

  Optional. The function to use for all analyses.

- `fn_name`:

  Optional. A character string that names the function to use.

- `df`:

  A data frame. Each row is one new analysis.

#### Returns

NULL. The method changes the plan in place.

#### Examples

    p <- plnr::Plan$new()

    # Add example data
    p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")

    # Create data frame of analyses
    batch_argset_df <- data.frame(
      name = c("a", "b", "c"),
      var_1 = c(1, 2, 3),
      var_2 = c("i", "j", "k")
    )

    # Add analyses from data frame
    p$add_analysis_from_df(
      fn_name = "plnr::example_action_fn",
      df = batch_argset_df
    )

    # View argsets and run example
    p$get_argsets_as_dt()
    p$run_one(1)

------------------------------------------------------------------------

### `Plan$add_analysis_from_list()`

Add multiple analyses from a list.

#### Usage

    Plan$add_analysis_from_list(fn = NULL, fn_name = NULL, l)

#### Arguments

- `fn`:

  Optional. The function to use for all analyses.

- `fn_name`:

  Optional. A character string that names the function to use.

- `l`:

  A list of lists. Each inner list is one new analysis.

#### Returns

NULL. The method changes the plan in place.

#### Examples

    p <- plnr::Plan$new()

    # Add example data
    p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")

    # Create list of analyses
    batch_argset_list <- list(
      list(name = "analysis_1", var_1 = 1, var_2 = "i"),
      list(name = "analysis_2", var_1 = 2, var_2 = "j"),
      list(name = "analysis_3", var_1 = 3, var_2 = "k")
    )

    # Add analyses from list
    p$add_analysis_from_list(
      fn_name = "plnr::example_action_fn",
      l = batch_argset_list
    )

    # View argsets and run example
    p$get_argsets_as_dt()
    p$run_one("analysis_1")

------------------------------------------------------------------------

### `Plan$apply_action_fn_to_all_argsets()`

Apply one action function to all the argsets.

#### Usage

    Plan$apply_action_fn_to_all_argsets(fn = NULL, fn_name = NULL)

#### Arguments

- `fn`:

  Action function.

- `fn_name`:

  Action function name. p \<- plnr::Plan\$new()
  p\$add_data("covid_data", fn_name =
  "plnr::example_data_fn_nor_covid19_cases_by_time_location")
  batch_argset_list \<- list( list(name = "analysis_1", var_1 = 1, var_2
  = "i"), list(name = "analysis_2", var_1 = 2, var_2 = "j"), list(name =
  "analysis_3", var_1 = 3, var_2 = "k") ) p\$add_argset_from_list(
  fn_name = "plnr::example_action_fn", l = batch_argset_list )
  p\$get_argsets_as_dt() p\$apply_action_fn_to_all_argsets(fn_name =
  "plnr::example_action_fn") p\$run_one("analysis_1")

------------------------------------------------------------------------

### `Plan$apply_analysis_fn_to_all()`

Deprecated. Use `apply_action_fn_to_all_argsets()` instead.

#### Usage

    Plan$apply_analysis_fn_to_all(fn = NULL, fn_name = NULL)

#### Arguments

- `fn`:

  Action function.

- `fn_name`:

  Action function name.

------------------------------------------------------------------------

### `Plan$x_length()`

Number of analyses in the plan.

#### Usage

    Plan$x_length()

------------------------------------------------------------------------

### `Plan$x_seq_along()`

Generate a regular sequence from 1 to the number of analyses in the
plan.

#### Usage

    Plan$x_seq_along()

------------------------------------------------------------------------

### `Plan$set_progress()`

Set an internal progress bar.

#### Usage

    Plan$set_progress(pb)

#### Arguments

- `pb`:

  Progress bar.

------------------------------------------------------------------------

### `Plan$set_progressor()`

Set an internal progressor progress bar.

#### Usage

    Plan$set_progressor(pb)

#### Arguments

- `pb`:

  progressor progress bar.

------------------------------------------------------------------------

### `Plan$set_verbose()`

Set the `verbose` flag.

#### Usage

    Plan$set_verbose(x)

#### Arguments

- `x`:

  Boolean.

------------------------------------------------------------------------

### `Plan$set_use_foreach()`

Set the `use_foreach` flag.

#### Usage

    Plan$set_use_foreach(x)

#### Arguments

- `x`:

  Boolean.

------------------------------------------------------------------------

### `Plan$get_data()`

Extract the data added with `add_data()` and return it as a named list.

#### Usage

    Plan$get_data()

#### Returns

A named list. Most elements come from `add_data()`.

One extra named element is called 'hash'. 'hash' holds the data hashes
of particular datasets and variables.
[`digest::digest()`](https://eddelbuettel.github.io/digest/man/digest.html)
calculates them with the 'spookyhash' algorithm.

'hash' holds two named elements:

- current (the hash of the entire named list)

- current_elements (the hash of the named elements within the named
  list)

#### Examples

    p <- plnr::Plan$new()
    p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
    p$get_data()

------------------------------------------------------------------------

### `Plan$get_analysis()`

Extract one analysis from the plan.

#### Usage

    Plan$get_analysis(index_analysis)

#### Arguments

- `index_analysis`:

  Either an integer in `1:length(analyses)`, or a character string with
  the name of the analysis.

#### Returns

An analysis.

#### Examples

    p <- plnr::Plan$new()
    p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
    batch_argset_list <- list(
      list(name = "analysis_1", var_1 = 1, var_2 = "i"),
      list(name = "analysis_2", var_1 = 2, var_2 = "j"),
      list(name = "analysis_3", var_1 = 3, var_2 = "k")
    )
    p$add_analysis_from_list(
      fn_name = "plnr::example_action_fn",
      l = batch_argset_list
    )
    p$get_analysis("analysis_1")

------------------------------------------------------------------------

### `Plan$get_argset()`

Extract one argset from the plan.

#### Usage

    Plan$get_argset(index_analysis)

#### Arguments

- `index_analysis`:

  Either an integer in `1:length(analyses)`, or a character string with
  the name of the analysis.

#### Returns

An argset.

#### Examples

    p <- plnr::Plan$new()
    p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
    batch_argset_list <- list(
      list(name = "analysis_1", var_1 = 1, var_2 = "i"),
      list(name = "analysis_2", var_1 = 2, var_2 = "j"),
      list(name = "analysis_3", var_1 = 3, var_2 = "k")
    )
    p$add_analysis_from_list(
      fn_name = "plnr::example_action_fn",
      l = batch_argset_list
    )
    p$get_argset("analysis_1")

------------------------------------------------------------------------

### `Plan$get_argsets_as_dt()`

Get all argsets and return them as a data.table.

#### Usage

    Plan$get_argsets_as_dt()

#### Returns

A data.table that holds all the argsets within a plan.

#### Examples

    p <- plnr::Plan$new()
    p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
    batch_argset_list <- list(
      list(name = "analysis_1", var_1 = 1, var_2 = "i"),
      list(name = "analysis_2", var_1 = 2, var_2 = "j"),
      list(name = "analysis_3", var_1 = 3, var_2 = "k")
    )
    p$add_analysis_from_list(
      fn_name = "plnr::example_action_fn",
      l = batch_argset_list
    )
    p$get_argsets_as_dt()

------------------------------------------------------------------------

### `Plan$run_one_with_data()`

Run one analysis. You supply the data.

#### Usage

    Plan$run_one_with_data(index_analysis, data, ...)

#### Arguments

- `index_analysis`:

  Either an integer in `1:length(analyses)`, or a character string with
  the name of the analysis.

- `data`:

  A named list. You normally get it from `p$get_data()`.

- `...`:

  Not used.

#### Returns

The value that the action function returns.

#### Examples

    p <- plnr::Plan$new()
    p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
    batch_argset_list <- list(
      list(name = "analysis_1", var_1 = 1, var_2 = "i"),
      list(name = "analysis_2", var_1 = 2, var_2 = "j"),
      list(name = "analysis_3", var_1 = 3, var_2 = "k")
    )
    p$add_analysis_from_list(
      fn_name = "plnr::example_action_fn",
      l = batch_argset_list
    )
    data <- p$get_data()
    p$run_one_with_data("analysis_1", data)

------------------------------------------------------------------------

### `Plan$run_one()`

Run one analysis. The method gets the data from `self$get_data()`.

#### Usage

    Plan$run_one(index_analysis, ...)

#### Arguments

- `index_analysis`:

  Either an integer in `1:length(analyses)`, or a character string with
  the name of the analysis.

- `...`:

  Not used.

#### Returns

The value that the action function returns.

#### Examples

    p <- plnr::Plan$new()
    p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
    batch_argset_list <- list(
      list(name = "analysis_1", var_1 = 1, var_2 = "i"),
      list(name = "analysis_2", var_1 = 2, var_2 = "j"),
      list(name = "analysis_3", var_1 = 3, var_2 = "k")
    )
    p$add_analysis_from_list(
      fn_name = "plnr::example_action_fn",
      l = batch_argset_list
    )
    p$run_one("analysis_1")

------------------------------------------------------------------------

### `Plan$run_all_with_data()`

Run all analyses. You supply the data.

#### Usage

    Plan$run_all_with_data(data, ...)

#### Arguments

- `data`:

  A named list. You normally get it from `p$get_data()`.

- `...`:

  Not used.

#### Returns

A list. Each element is the value that the action function returns.

#### Examples

    p <- plnr::Plan$new()
    p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
    batch_argset_list <- list(
      list(name = "analysis_1", var_1 = 1, var_2 = "i"),
      list(name = "analysis_2", var_1 = 2, var_2 = "j"),
      list(name = "analysis_3", var_1 = 3, var_2 = "k")
    )
    p$add_analysis_from_list(
      fn_name = "plnr::example_action_fn",
      l = batch_argset_list
    )
    data <- p$get_data()
    p$run_all_with_data(data)

------------------------------------------------------------------------

### `Plan$run_all()`

Run all analyses. The method gets the data from `self$get_data()`.

#### Usage

    Plan$run_all(...)

#### Arguments

- `...`:

  Not used.

#### Returns

A list. Each element is the value that the action function returns.

#### Examples

    p <- plnr::Plan$new()
    p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
    batch_argset_list <- list(
      list(name = "analysis_1", var_1 = 1, var_2 = "i"),
      list(name = "analysis_2", var_1 = 2, var_2 = "j"),
      list(name = "analysis_3", var_1 = 3, var_2 = "k")
    )
    p$add_analysis_from_list(
      fn_name = "plnr::example_action_fn",
      l = batch_argset_list
    )
    p$run_all()

------------------------------------------------------------------------

### `Plan$run_all_progress()`

Run all analyses and show a progress bar. The method gets the data from
`self$get_data()`.

#### Usage

    Plan$run_all_progress(...)

#### Arguments

- `...`:

  Not used.

#### Returns

A list. Each element is the value that the action function returns.

#### Examples

    p <- plnr::Plan$new()
    p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
    batch_argset_list <- list(
      list(name = "analysis_1", var_1 = 1, var_2 = "i"),
      list(name = "analysis_2", var_1 = 2, var_2 = "j"),
      list(name = "analysis_3", var_1 = 3, var_2 = "k")
    )
    p$add_analysis_from_list(
      fn_name = "plnr::example_action_fn",
      l = batch_argset_list
    )
    p$run_all_progress()

------------------------------------------------------------------------

### `Plan$run_all_parallel()`

Run all analyses in parallel. The method gets the data from
`self$get_data()`.

This method works only on linux computers. It uses `pbmcapply` as the
parallel backend.

#### Usage

    Plan$run_all_parallel(mc.cores = getOption("mc.cores", 2L), ...)

#### Arguments

- `mc.cores`:

  The number of cores to use.

- `...`:

  Not used.

#### Returns

A list. Each element is the value that the action function returns.

------------------------------------------------------------------------

### `Plan$clone()`

The objects of this class are cloneable with this method.

#### Usage

    Plan$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
## ------------------------------------------------
## Method `Plan$add_data()`
## ------------------------------------------------

p <- plnr::Plan$new()

# Add data using a function
data_fn <- function() { return(plnr::nor_covid19_cases_by_time_location) }
p$add_data("data_1", fn = data_fn)

# Add data using a function name
p$add_data("data_2", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")

# Add data directly
p$add_data("data_3", direct = plnr::nor_covid19_cases_by_time_location)

# View added data
p$get_data()
#> $data_1
#>        granularity_time granularity_geo country_iso3 location_code border
#>                  <char>          <char>       <char>        <char>  <int>
#>     1:              day          county          nor  county_nor03   2020
#>     2:              day          county          nor  county_nor03   2020
#>     3:              day          county          nor  county_nor03   2020
#>     4:              day          county          nor  county_nor03   2020
#>     5:              day          county          nor  county_nor03   2020
#>    ---                                                                   
#> 11024:          isoweek          nation          nor    nation_nor   2020
#> 11025:          isoweek          nation          nor    nation_nor   2020
#> 11026:          isoweek          nation          nor    nation_nor   2020
#> 11027:          isoweek          nation          nor    nation_nor   2020
#> 11028:          isoweek          nation          nor    nation_nor   2020
#>           age    sex isoyear isoweek isoyearweek    season seasonweek calyear
#>        <char> <char>   <int>   <int>      <char>    <char>      <num>   <int>
#>     1:  total  total    2020       8     2020-08 2019/2020         31    2020
#>     2:  total  total    2020       8     2020-08 2019/2020         31    2020
#>     3:  total  total    2020       8     2020-08 2019/2020         31    2020
#>     4:  total  total    2020       9     2020-09 2019/2020         32    2020
#>     5:  total  total    2020       9     2020-09 2019/2020         32    2020
#>    ---                                                                       
#> 11024:  total  total    2022      14     2022-14 2021/2022         37      NA
#> 11025:  total  total    2022      15     2022-15 2021/2022         38      NA
#> 11026:  total  total    2022      16     2022-16 2021/2022         39      NA
#> 11027:  total  total    2022      17     2022-17 2021/2022         40      NA
#> 11028:  total  total    2022      18     2022-18 2021/2022         41      NA
#>        calmonth calyearmonth       date covid19_cases_testdate_n
#>           <int>       <char>     <Date>                    <int>
#>     1:        2     2020-M02 2020-02-21                        0
#>     2:        2     2020-M02 2020-02-22                        0
#>     3:        2     2020-M02 2020-02-23                        0
#>     4:        2     2020-M02 2020-02-24                        0
#>     5:        2     2020-M02 2020-02-25                        0
#>    ---                                                          
#> 11024:       NA         <NA> 2022-04-10                     6888
#> 11025:       NA         <NA> 2022-04-17                     3635
#> 11026:       NA         <NA> 2022-04-24                     3764
#> 11027:       NA         <NA> 2022-05-01                     2243
#> 11028:       NA         <NA> 2022-05-08                      502
#>        covid19_cases_testdate_pr100000
#>                                  <num>
#>     1:                        0.000000
#>     2:                        0.000000
#>     3:                        0.000000
#>     4:                        0.000000
#>     5:                        0.000000
#>    ---                                
#> 11024:                      126.961423
#> 11025:                       67.001274
#> 11026:                       69.379036
#> 11027:                       41.343564
#> 11028:                        9.252996
#> 
#> $data_2
#>        granularity_time granularity_geo country_iso3 location_code border
#>                  <char>          <char>       <char>        <char>  <int>
#>     1:              day          county          nor  county_nor03   2020
#>     2:              day          county          nor  county_nor03   2020
#>     3:              day          county          nor  county_nor03   2020
#>     4:              day          county          nor  county_nor03   2020
#>     5:              day          county          nor  county_nor03   2020
#>    ---                                                                   
#> 11024:          isoweek          nation          nor    nation_nor   2020
#> 11025:          isoweek          nation          nor    nation_nor   2020
#> 11026:          isoweek          nation          nor    nation_nor   2020
#> 11027:          isoweek          nation          nor    nation_nor   2020
#> 11028:          isoweek          nation          nor    nation_nor   2020
#>           age    sex isoyear isoweek isoyearweek    season seasonweek calyear
#>        <char> <char>   <int>   <int>      <char>    <char>      <num>   <int>
#>     1:  total  total    2020       8     2020-08 2019/2020         31    2020
#>     2:  total  total    2020       8     2020-08 2019/2020         31    2020
#>     3:  total  total    2020       8     2020-08 2019/2020         31    2020
#>     4:  total  total    2020       9     2020-09 2019/2020         32    2020
#>     5:  total  total    2020       9     2020-09 2019/2020         32    2020
#>    ---                                                                       
#> 11024:  total  total    2022      14     2022-14 2021/2022         37      NA
#> 11025:  total  total    2022      15     2022-15 2021/2022         38      NA
#> 11026:  total  total    2022      16     2022-16 2021/2022         39      NA
#> 11027:  total  total    2022      17     2022-17 2021/2022         40      NA
#> 11028:  total  total    2022      18     2022-18 2021/2022         41      NA
#>        calmonth calyearmonth       date covid19_cases_testdate_n
#>           <int>       <char>     <Date>                    <int>
#>     1:        2     2020-M02 2020-02-21                        0
#>     2:        2     2020-M02 2020-02-22                        0
#>     3:        2     2020-M02 2020-02-23                        0
#>     4:        2     2020-M02 2020-02-24                        0
#>     5:        2     2020-M02 2020-02-25                        0
#>    ---                                                          
#> 11024:       NA         <NA> 2022-04-10                     6888
#> 11025:       NA         <NA> 2022-04-17                     3635
#> 11026:       NA         <NA> 2022-04-24                     3764
#> 11027:       NA         <NA> 2022-05-01                     2243
#> 11028:       NA         <NA> 2022-05-08                      502
#>        covid19_cases_testdate_pr100000
#>                                  <num>
#>     1:                        0.000000
#>     2:                        0.000000
#>     3:                        0.000000
#>     4:                        0.000000
#>     5:                        0.000000
#>    ---                                
#> 11024:                      126.961423
#> 11025:                       67.001274
#> 11026:                       69.379036
#> 11027:                       41.343564
#> 11028:                        9.252996
#> 
#> $data_3
#>        granularity_time granularity_geo country_iso3 location_code border
#>                  <char>          <char>       <char>        <char>  <int>
#>     1:              day          county          nor  county_nor03   2020
#>     2:              day          county          nor  county_nor03   2020
#>     3:              day          county          nor  county_nor03   2020
#>     4:              day          county          nor  county_nor03   2020
#>     5:              day          county          nor  county_nor03   2020
#>    ---                                                                   
#> 11024:          isoweek          nation          nor    nation_nor   2020
#> 11025:          isoweek          nation          nor    nation_nor   2020
#> 11026:          isoweek          nation          nor    nation_nor   2020
#> 11027:          isoweek          nation          nor    nation_nor   2020
#> 11028:          isoweek          nation          nor    nation_nor   2020
#>           age    sex isoyear isoweek isoyearweek    season seasonweek calyear
#>        <char> <char>   <int>   <int>      <char>    <char>      <num>   <int>
#>     1:  total  total    2020       8     2020-08 2019/2020         31    2020
#>     2:  total  total    2020       8     2020-08 2019/2020         31    2020
#>     3:  total  total    2020       8     2020-08 2019/2020         31    2020
#>     4:  total  total    2020       9     2020-09 2019/2020         32    2020
#>     5:  total  total    2020       9     2020-09 2019/2020         32    2020
#>    ---                                                                       
#> 11024:  total  total    2022      14     2022-14 2021/2022         37      NA
#> 11025:  total  total    2022      15     2022-15 2021/2022         38      NA
#> 11026:  total  total    2022      16     2022-16 2021/2022         39      NA
#> 11027:  total  total    2022      17     2022-17 2021/2022         40      NA
#> 11028:  total  total    2022      18     2022-18 2021/2022         41      NA
#>        calmonth calyearmonth       date covid19_cases_testdate_n
#>           <int>       <char>     <Date>                    <int>
#>     1:        2     2020-M02 2020-02-21                        0
#>     2:        2     2020-M02 2020-02-22                        0
#>     3:        2     2020-M02 2020-02-23                        0
#>     4:        2     2020-M02 2020-02-24                        0
#>     5:        2     2020-M02 2020-02-25                        0
#>    ---                                                          
#> 11024:       NA         <NA> 2022-04-10                     6888
#> 11025:       NA         <NA> 2022-04-17                     3635
#> 11026:       NA         <NA> 2022-04-24                     3764
#> 11027:       NA         <NA> 2022-05-01                     2243
#> 11028:       NA         <NA> 2022-05-08                      502
#>        covid19_cases_testdate_pr100000
#>                                  <num>
#>     1:                        0.000000
#>     2:                        0.000000
#>     3:                        0.000000
#>     4:                        0.000000
#>     5:                        0.000000
#>    ---                                
#> 11024:                      126.961423
#> 11025:                       67.001274
#> 11026:                       69.379036
#> 11027:                       41.343564
#> 11028:                        9.252996
#> 
#> $hash
#> $hash$current
#> [1] "f94ed40e7cee3cdea8d42ef836fb63cd"
#> 
#> $hash$current_elements
#> $hash$current_elements$data_1
#> [1] "7f1b0a581386e75e907bffd94938a3a7"
#> 
#> $hash$current_elements$data_2
#> [1] "7f1b0a581386e75e907bffd94938a3a7"
#> 
#> $hash$current_elements$data_3
#> [1] "7f1b0a581386e75e907bffd94938a3a7"
#> 
#> 
#> 

## ------------------------------------------------
## Method `Plan$add_argset()`
## ------------------------------------------------

p <- plnr::Plan$new()

# Add argsets with different arguments
p$add_argset("argset_1", var_1 = 3, var_b = "hello")
p$add_argset("argset_2", var_1 = 8, var_c = "hello2")

# View added argsets
p$get_argsets_as_dt()
#>    name_analysis index_analysis  var_1  var_b  var_c
#>           <char>          <int> <list> <list> <list>
#> 1:      argset_1              1      3  hello [NULL]
#> 2:      argset_2              2      8 [NULL] hello2

## ------------------------------------------------
## Method `Plan$add_argset_from_df()`
## ------------------------------------------------

p <- plnr::Plan$new()

# Create data frame of argsets
batch_argset_df <- data.frame(
  name = c("a", "b", "c"),
  var_1 = c(1, 2, 3),
  var_2 = c("i", "j", "k")
)

# Add argsets from data frame
p$add_argset_from_df(batch_argset_df)

# View added argsets
p$get_argsets_as_dt()
#>    name_analysis index_analysis  var_1  var_2
#>           <char>          <int> <list> <list>
#> 1:             a              1      1      i
#> 2:             b              2      2      j
#> 3:             c              3      3      k

## ------------------------------------------------
## Method `Plan$add_argset_from_list()`
## ------------------------------------------------

p <- plnr::Plan$new()

# Create list of argsets
batch_argset_list <- list(
  list(name = "a", var_1 = 1, var_2 = "i"),
  list(name = "b", var_1 = 2, var_2 = "j"),
  list(name = "c", var_1 = 3, var_2 = "k")
)

# Add argsets from list
p$add_argset_from_list(batch_argset_list)

# View added argsets
p$get_argsets_as_dt()
#>    name_analysis index_analysis  var_1  var_2
#>           <char>          <int> <list> <list>
#> 1:             a              1      1      i
#> 2:             b              2      2      j
#> 3:             c              3      3      k

## ------------------------------------------------
## Method `Plan$add_analysis()`
## ------------------------------------------------

p <- plnr::Plan$new()

# Add example data
p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")

# Add analysis
p$add_analysis(
  name = "analysis_1",
  fn_name = "plnr::example_action_fn"
)

# View argsets and run analysis
p$get_argsets_as_dt()
#>    name_analysis index_analysis
#>           <char>          <int>
#> 1:    analysis_1              1
p$run_one("analysis_1")
#> [1] "Data given:"
#> [1] "covid_data" "hash"      
#> [1] "Argset given:"
#> [1] "index_analysis"
#> [1] "index_analysis"

## ------------------------------------------------
## Method `Plan$add_analysis_from_df()`
## ------------------------------------------------

p <- plnr::Plan$new()

# Add example data
p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")

# Create data frame of analyses
batch_argset_df <- data.frame(
  name = c("a", "b", "c"),
  var_1 = c(1, 2, 3),
  var_2 = c("i", "j", "k")
)

# Add analyses from data frame
p$add_analysis_from_df(
  fn_name = "plnr::example_action_fn",
  df = batch_argset_df
)

# View argsets and run example
p$get_argsets_as_dt()
#>    name_analysis index_analysis  var_1  var_2
#>           <char>          <int> <list> <list>
#> 1:             a              1      1      i
#> 2:             b              2      2      j
#> 3:             c              3      3      k
p$run_one(1)
#> [1] "Data given:"
#> [1] "covid_data" "hash"      
#> [1] "Argset given:"
#> [1] "var_1"          "var_2"          "index_analysis"
#> [1] "var_1"          "var_2"          "index_analysis"

## ------------------------------------------------
## Method `Plan$add_analysis_from_list()`
## ------------------------------------------------

p <- plnr::Plan$new()

# Add example data
p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")

# Create list of analyses
batch_argset_list <- list(
  list(name = "analysis_1", var_1 = 1, var_2 = "i"),
  list(name = "analysis_2", var_1 = 2, var_2 = "j"),
  list(name = "analysis_3", var_1 = 3, var_2 = "k")
)

# Add analyses from list
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

## ------------------------------------------------
## Method `Plan$get_data()`
## ------------------------------------------------

p <- plnr::Plan$new()
p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
p$get_data()
#> $covid_data
#>        granularity_time granularity_geo country_iso3 location_code border
#>                  <char>          <char>       <char>        <char>  <int>
#>     1:              day          county          nor  county_nor03   2020
#>     2:              day          county          nor  county_nor03   2020
#>     3:              day          county          nor  county_nor03   2020
#>     4:              day          county          nor  county_nor03   2020
#>     5:              day          county          nor  county_nor03   2020
#>    ---                                                                   
#> 11024:          isoweek          nation          nor    nation_nor   2020
#> 11025:          isoweek          nation          nor    nation_nor   2020
#> 11026:          isoweek          nation          nor    nation_nor   2020
#> 11027:          isoweek          nation          nor    nation_nor   2020
#> 11028:          isoweek          nation          nor    nation_nor   2020
#>           age    sex isoyear isoweek isoyearweek    season seasonweek calyear
#>        <char> <char>   <int>   <int>      <char>    <char>      <num>   <int>
#>     1:  total  total    2020       8     2020-08 2019/2020         31    2020
#>     2:  total  total    2020       8     2020-08 2019/2020         31    2020
#>     3:  total  total    2020       8     2020-08 2019/2020         31    2020
#>     4:  total  total    2020       9     2020-09 2019/2020         32    2020
#>     5:  total  total    2020       9     2020-09 2019/2020         32    2020
#>    ---                                                                       
#> 11024:  total  total    2022      14     2022-14 2021/2022         37      NA
#> 11025:  total  total    2022      15     2022-15 2021/2022         38      NA
#> 11026:  total  total    2022      16     2022-16 2021/2022         39      NA
#> 11027:  total  total    2022      17     2022-17 2021/2022         40      NA
#> 11028:  total  total    2022      18     2022-18 2021/2022         41      NA
#>        calmonth calyearmonth       date covid19_cases_testdate_n
#>           <int>       <char>     <Date>                    <int>
#>     1:        2     2020-M02 2020-02-21                        0
#>     2:        2     2020-M02 2020-02-22                        0
#>     3:        2     2020-M02 2020-02-23                        0
#>     4:        2     2020-M02 2020-02-24                        0
#>     5:        2     2020-M02 2020-02-25                        0
#>    ---                                                          
#> 11024:       NA         <NA> 2022-04-10                     6888
#> 11025:       NA         <NA> 2022-04-17                     3635
#> 11026:       NA         <NA> 2022-04-24                     3764
#> 11027:       NA         <NA> 2022-05-01                     2243
#> 11028:       NA         <NA> 2022-05-08                      502
#>        covid19_cases_testdate_pr100000
#>                                  <num>
#>     1:                        0.000000
#>     2:                        0.000000
#>     3:                        0.000000
#>     4:                        0.000000
#>     5:                        0.000000
#>    ---                                
#> 11024:                      126.961423
#> 11025:                       67.001274
#> 11026:                       69.379036
#> 11027:                       41.343564
#> 11028:                        9.252996
#> 
#> $hash
#> $hash$current
#> [1] "18b3aa368375163b3eee188988c8c15c"
#> 
#> $hash$current_elements
#> $hash$current_elements$covid_data
#> [1] "7f1b0a581386e75e907bffd94938a3a7"
#> 
#> 
#> 

## ------------------------------------------------
## Method `Plan$get_analysis()`
## ------------------------------------------------

p <- plnr::Plan$new()
p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
batch_argset_list <- list(
  list(name = "analysis_1", var_1 = 1, var_2 = "i"),
  list(name = "analysis_2", var_1 = 2, var_2 = "j"),
  list(name = "analysis_3", var_1 = 3, var_2 = "k")
)
p$add_analysis_from_list(
  fn_name = "plnr::example_action_fn",
  l = batch_argset_list
)
p$get_analysis("analysis_1")
#> $fn
#> NULL
#> 
#> $fn_name
#> [1] "plnr::example_action_fn"
#> 
#> $argset
#> $argset$var_1
#> [1] 1
#> 
#> $argset$var_2
#> [1] "i"
#> 
#> $argset$index_analysis
#> [1] "analysis_1"
#> 
#> 

## ------------------------------------------------
## Method `Plan$get_argset()`
## ------------------------------------------------

p <- plnr::Plan$new()
p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
batch_argset_list <- list(
  list(name = "analysis_1", var_1 = 1, var_2 = "i"),
  list(name = "analysis_2", var_1 = 2, var_2 = "j"),
  list(name = "analysis_3", var_1 = 3, var_2 = "k")
)
p$add_analysis_from_list(
  fn_name = "plnr::example_action_fn",
  l = batch_argset_list
)
p$get_argset("analysis_1")
#> $var_1
#> [1] 1
#> 
#> $var_2
#> [1] "i"
#> 

## ------------------------------------------------
## Method `Plan$get_argsets_as_dt()`
## ------------------------------------------------

p <- plnr::Plan$new()
p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
batch_argset_list <- list(
  list(name = "analysis_1", var_1 = 1, var_2 = "i"),
  list(name = "analysis_2", var_1 = 2, var_2 = "j"),
  list(name = "analysis_3", var_1 = 3, var_2 = "k")
)
p$add_analysis_from_list(
  fn_name = "plnr::example_action_fn",
  l = batch_argset_list
)
p$get_argsets_as_dt()
#>    name_analysis index_analysis  var_1  var_2
#>           <char>          <int> <list> <list>
#> 1:    analysis_1              1      1      i
#> 2:    analysis_2              2      2      j
#> 3:    analysis_3              3      3      k

## ------------------------------------------------
## Method `Plan$run_one_with_data()`
## ------------------------------------------------

p <- plnr::Plan$new()
p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
batch_argset_list <- list(
  list(name = "analysis_1", var_1 = 1, var_2 = "i"),
  list(name = "analysis_2", var_1 = 2, var_2 = "j"),
  list(name = "analysis_3", var_1 = 3, var_2 = "k")
)
p$add_analysis_from_list(
  fn_name = "plnr::example_action_fn",
  l = batch_argset_list
)
data <- p$get_data()
p$run_one_with_data("analysis_1", data)
#> [1] "Data given:"
#> [1] "covid_data" "hash"      
#> [1] "Argset given:"
#> [1] "var_1"          "var_2"          "index_analysis"
#> [1] "var_1"          "var_2"          "index_analysis"

## ------------------------------------------------
## Method `Plan$run_one()`
## ------------------------------------------------

p <- plnr::Plan$new()
p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
batch_argset_list <- list(
  list(name = "analysis_1", var_1 = 1, var_2 = "i"),
  list(name = "analysis_2", var_1 = 2, var_2 = "j"),
  list(name = "analysis_3", var_1 = 3, var_2 = "k")
)
p$add_analysis_from_list(
  fn_name = "plnr::example_action_fn",
  l = batch_argset_list
)
p$run_one("analysis_1")
#> [1] "Data given:"
#> [1] "covid_data" "hash"      
#> [1] "Argset given:"
#> [1] "var_1"          "var_2"          "index_analysis"
#> [1] "var_1"          "var_2"          "index_analysis"

## ------------------------------------------------
## Method `Plan$run_all_with_data()`
## ------------------------------------------------

p <- plnr::Plan$new()
p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
batch_argset_list <- list(
  list(name = "analysis_1", var_1 = 1, var_2 = "i"),
  list(name = "analysis_2", var_1 = 2, var_2 = "j"),
  list(name = "analysis_3", var_1 = 3, var_2 = "k")
)
p$add_analysis_from_list(
  fn_name = "plnr::example_action_fn",
  l = batch_argset_list
)
data <- p$get_data()
p$run_all_with_data(data)
#> [1] "Data given:"
#> [1] "covid_data" "hash"      
#> [1] "Argset given:"
#> [1] "var_1"          "var_2"          "index_analysis"
#> [1] "Data given:"
#> [1] "covid_data" "hash"      
#> [1] "Argset given:"
#> [1] "var_1"          "var_2"          "index_analysis"
#> [1] "Data given:"
#> [1] "covid_data" "hash"      
#> [1] "Argset given:"
#> [1] "var_1"          "var_2"          "index_analysis"

## ------------------------------------------------
## Method `Plan$run_all()`
## ------------------------------------------------

p <- plnr::Plan$new()
p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
batch_argset_list <- list(
  list(name = "analysis_1", var_1 = 1, var_2 = "i"),
  list(name = "analysis_2", var_1 = 2, var_2 = "j"),
  list(name = "analysis_3", var_1 = 3, var_2 = "k")
)
p$add_analysis_from_list(
  fn_name = "plnr::example_action_fn",
  l = batch_argset_list
)
p$run_all()
#> [1] "Data given:"
#> [1] "covid_data" "hash"      
#> [1] "Argset given:"
#> [1] "var_1"          "var_2"          "index_analysis"
#> [1] "Data given:"
#> [1] "covid_data" "hash"      
#> [1] "Argset given:"
#> [1] "var_1"          "var_2"          "index_analysis"
#> [1] "Data given:"
#> [1] "covid_data" "hash"      
#> [1] "Argset given:"
#> [1] "var_1"          "var_2"          "index_analysis"

## ------------------------------------------------
## Method `Plan$run_all_progress()`
## ------------------------------------------------

p <- plnr::Plan$new()
p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
batch_argset_list <- list(
  list(name = "analysis_1", var_1 = 1, var_2 = "i"),
  list(name = "analysis_2", var_1 = 2, var_2 = "j"),
  list(name = "analysis_3", var_1 = 3, var_2 = "k")
)
p$add_analysis_from_list(
  fn_name = "plnr::example_action_fn",
  l = batch_argset_list
)
p$run_all_progress()
#> [1] "Data given:"
#> [1] "covid_data" "hash"      
#> [1] "Argset given:"
#> [1] "var_1"          "var_2"          "index_analysis"
#> [1] "Data given:"
#> [1] "covid_data" "hash"      
#> [1] "Argset given:"
#> [1] "var_1"          "var_2"          "index_analysis"
#> [1] "Data given:"
#> [1] "covid_data" "hash"      
#> [1] "Argset given:"
#> [1] "var_1"          "var_2"          "index_analysis"
```
