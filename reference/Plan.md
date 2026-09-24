# Plan and run analyses

A `Plan` holds data sources and analyses, and runs the analyses on the
data. An analysis is one argset plus one action function.

## Value

`Plan$new()` returns a new `Plan` object.

## Details

An argset is a named list of arguments for one analysis. When an
analysis runs, its argset also holds `index_analysis`: the position or
name that ran it.

An action function MUST take the data as its first argument and the
argset as its second. It MAY take further arguments. The run methods
pass their `...` to it in one of two ways:

- A function given as `fn` gets the argset by position, and every
  argument in `...`.

- A function given as `fn_name` gets `data` and `argset` by name. It
  gets `...` only when it has more than two formal arguments.

[`get_anything()`](https://www.rwhite.no/plnr/reference/get_anything.md)
finds the function that `fn_name` names when the analysis runs. If the
name resolved in a local environment when you set `fn_name`, the plan
stores that environment and looks there first.

## See also

[`vignette("plnr")`](https://www.rwhite.no/plnr/articles/plnr.md) for
the concepts.
[`vignette("adding_analyses")`](https://www.rwhite.no/plnr/articles/adding_analyses.md)
for worked single-function and multi-function plans.

Other plan helpers:
[`expand_list()`](https://www.rwhite.no/plnr/reference/expand_list.md),
[`get_anything()`](https://www.rwhite.no/plnr/reference/get_anything.md),
[`is_run_directly()`](https://www.rwhite.no/plnr/reference/is_run_directly.md),
[`set_opts()`](https://www.rwhite.no/plnr/reference/set_opts.md)

## Public fields

- `analyses`:

  A named list with one element for each analysis. Each element holds
  `argset` and, once set, `fn`, `fn_name` and `fn_env`.

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

Create a new plan.

#### Usage

    Plan$new(verbose = interactive() | config$force_verbose, use_foreach = FALSE)

#### Arguments

- `verbose`:

  Logical. `TRUE` makes `run_all()` show progress. The default is `TRUE`
  in an interactive session, or after `set_opts(force_verbose = TRUE)`.

- `use_foreach`:

  Logical or `NULL`. `TRUE` makes `run_all()` use foreach, and `FALSE` a
  loop. `NULL` uses foreach when a backend with more than one worker is
  registered and progressr is installed. The default is `FALSE`.

#### Returns

A new `Plan` object.

------------------------------------------------------------------------

### `Plan$add_data()`

Add a data source. `get_data()` loads every data source. Give one of
`fn`, `fn_name` and `direct`. If you give more, `direct` wins over
`fn_name`, and `fn_name` wins over `fn`.

#### Usage

    Plan$add_data(name, fn = NULL, fn_name = NULL, direct = NULL)

#### Arguments

- `name`:

  Character string. The name of the dataset in the list that
  `get_data()` returns.

- `fn`:

  Optional. A function with no arguments that returns the dataset.

- `fn_name`:

  Optional. The name of such a function, as a character string.
  `"pkg::fn"` also works.

- `direct`:

  Optional. The dataset itself.

#### Returns

The stored data source, invisibly: a list that holds `fn`, `fn_name`,
`direct`, `name` and `fn_env`.

#### Examples

    p <- plnr::Plan$new()
    data_fn <- function() {
      return(plnr::nor_covid19_cases_by_time_location)
    }
    p$add_data("data_1", fn = data_fn)
    p$add_data("data_2", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
    p$add_data("data_3", direct = plnr::nor_covid19_cases_by_time_location)
    names(p$get_data())

------------------------------------------------------------------------

### `Plan$add_argset()`

Add an argset: an analysis that has no action function yet. If an
analysis with this name exists, `add_argset()` replaces its argset and
keeps its action function.

#### Usage

    Plan$add_argset(name = uuid::UUIDgenerate(), ...)

#### Arguments

- `name`:

  Character string. The name of the analysis. The default is a UUID.

- `...`:

  Named arguments. They make up the argset.

#### Returns

The argset, invisibly.

#### Examples

    p <- plnr::Plan$new()
    p$add_argset("argset_1", var_1 = 3, var_b = "hello")
    p$add_argset("argset_2", var_1 = 8, var_c = "hello2")
    p$get_argsets_as_dt()

------------------------------------------------------------------------

### `Plan$add_argset_from_df()`

Add one argset for each row of a data frame.

#### Usage

    Plan$add_argset_from_df(df)

#### Arguments

- `df`:

  A data frame. Each row is one argset. A column `name` names the
  analyses.

#### Returns

`NULL`, invisibly.

#### Examples

    p <- plnr::Plan$new()
    p$add_argset_from_df(data.frame(name = c("a", "b"), var_1 = c(1, 2)))
    p$get_argsets_as_dt()

------------------------------------------------------------------------

### `Plan$add_argset_from_list()`

Add one argset for each element of a list.

#### Usage

    Plan$add_argset_from_list(l)

#### Arguments

- `l`:

  A list of named lists. Each inner list is one argset. An element
  `name` names the analysis.

#### Returns

`NULL`, invisibly.

#### Examples

    p <- plnr::Plan$new()
    p$add_argset_from_list(plnr::expand_list(var_1 = 1:2, var_2 = c("i", "j")))
    p$get_argsets_as_dt()

------------------------------------------------------------------------

### `Plan$add_analysis()`

Add an analysis: one argset and one action function. If an analysis with
this name exists, `add_analysis()` replaces it.

#### Usage

    Plan$add_analysis(name = uuid::UUIDgenerate(), fn = NULL, fn_name = NULL, ...)

#### Arguments

- `name`:

  Character string. The name of the analysis. The default is a UUID.

- `fn`:

  Optional. The action function.

- `fn_name`:

  Optional. The name of the action function, as a character string.
  `"pkg::fn"` also works. Give `fn` or `fn_name`, not both.

- `...`:

  Named arguments. They make up the argset.

#### Returns

The argset, invisibly.

#### Examples

    p <- plnr::Plan$new()
    p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
    p$add_analysis(name = "analysis_1", fn_name = "plnr::example_action_fn")
    p$run_one("analysis_1")

------------------------------------------------------------------------

### `Plan$add_analysis_from_df()`

Add one analysis for each row of a data frame.

#### Usage

    Plan$add_analysis_from_df(fn = NULL, fn_name = NULL, df)

#### Arguments

- `fn`:

  Optional. The action function of every analysis.

- `fn_name`:

  Optional. The name of the action function of every analysis. A column
  `fn_name` in `df` overrides it.

- `df`:

  A data frame. Each row is one argset. A column `name` names the
  analyses.

#### Returns

`NULL`, invisibly.

#### Examples

    p <- plnr::Plan$new()
    p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
    p$add_analysis_from_df(
      fn_name = "plnr::example_action_fn",
      df = data.frame(name = c("a", "b"), var_1 = c(1, 2))
    )
    p$run_one("a")

------------------------------------------------------------------------

### `Plan$add_analysis_from_list()`

Add one analysis for each element of a list.

#### Usage

    Plan$add_analysis_from_list(fn = NULL, fn_name = NULL, l)

#### Arguments

- `fn`:

  Optional. The action function of every analysis.

- `fn_name`:

  Optional. The name of the action function of every analysis. An
  element `fn_name` in an inner list overrides it.

- `l`:

  A list of named lists. Each inner list is one argset. An element
  `name` names the analysis.

#### Returns

`NULL`, invisibly.

#### Examples

    p <- plnr::Plan$new()
    p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
    p$add_analysis_from_list(
      fn_name = "plnr::example_action_fn",
      l = list(
        list(name = "analysis_1", var_1 = 1),
        list(name = "analysis_2", var_1 = 2)
      )
    )
    p$run_one("analysis_1")

------------------------------------------------------------------------

### `Plan$apply_action_fn_to_all_argsets()`

Give every analysis in the plan the same action function. It replaces
any action function that an analysis already has.

#### Usage

    Plan$apply_action_fn_to_all_argsets(fn = NULL, fn_name = NULL)

#### Arguments

- `fn`:

  Optional. The action function.

- `fn_name`:

  Optional. The name of the action function, as a character string.

#### Returns

`NULL`, invisibly.

#### Examples

    p <- plnr::Plan$new()
    p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
    p$add_argset_from_list(list(
      list(name = "analysis_1", var_1 = 1),
      list(name = "analysis_2", var_1 = 2)
    ))
    p$apply_action_fn_to_all_argsets(fn_name = "plnr::example_action_fn")
    p$run_one("analysis_1")

------------------------------------------------------------------------

### `Plan$apply_analysis_fn_to_all()`

Deprecated. Use `apply_action_fn_to_all_argsets()`.

#### Usage

    Plan$apply_analysis_fn_to_all(fn = NULL, fn_name = NULL)

#### Arguments

- `fn`:

  Optional. The action function.

- `fn_name`:

  Optional. The name of the action function.

#### Returns

`NULL`, invisibly.

------------------------------------------------------------------------

### `Plan$x_length()`

Count the analyses in the plan.

#### Usage

    Plan$x_length()

#### Returns

An integer.

------------------------------------------------------------------------

### `Plan$x_seq_along()`

Get the positions of the analyses, `seq_along(analyses)`.

#### Usage

    Plan$x_seq_along()

#### Returns

An integer vector.

------------------------------------------------------------------------

### `Plan$set_progress()`

Set a progress bar that `run_all()` ticks once for each analysis.

#### Usage

    Plan$set_progress(pb)

#### Arguments

- `pb`:

  An object with a `tick()` method, such as one from
  `progress::progress_bar$new()`.

#### Returns

`pb`, invisibly.

------------------------------------------------------------------------

### `Plan$set_progressor()`

Set a progressr progressor that `run_all()` calls once for each
analysis.

#### Usage

    Plan$set_progressor(pb)

#### Arguments

- `pb`:

  A function from
  [`progressr::progressor()`](https://progressr.futureverse.org/reference/progressor.html).

#### Returns

`pb`, invisibly.

------------------------------------------------------------------------

### `Plan$set_verbose()`

Set `verbose`, which `new()` describes.

#### Usage

    Plan$set_verbose(x)

#### Arguments

- `x`:

  Logical.

#### Returns

`x`, invisibly.

------------------------------------------------------------------------

### `Plan$set_use_foreach()`

Set `use_foreach`, which `new()` describes.

#### Usage

    Plan$set_use_foreach(x)

#### Arguments

- `x`:

  Logical or `NULL`.

#### Returns

`x`, invisibly.

------------------------------------------------------------------------

### `Plan$get_data()`

Load every data source, and return the datasets as a named list.

#### Usage

    Plan$get_data()

#### Returns

A named list with one element for each dataset, and an element `hash`.
`hash$current` is the spookyhash digest of the datasets.
`hash$current_elements` holds one digest for each dataset. plnr does not
read these digests.

If the only data source is `data__________go_up_one_level` and it
returns a named list, that list holds the datasets.

#### Examples

    p <- plnr::Plan$new()
    p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
    str(p$get_data(), max.level = 1)

------------------------------------------------------------------------

### `Plan$get_analysis()`

Get one analysis.

#### Usage

    Plan$get_analysis(index_analysis)

#### Arguments

- `index_analysis`:

  The position of the analysis, or its name.

#### Returns

The analysis, as `analyses` holds it. Its argset also holds
`index_analysis`.

#### Examples

    p <- plnr::Plan$new()
    p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
    p$add_analysis_from_list(
      fn_name = "plnr::example_action_fn",
      l = list(
        list(name = "analysis_1", var_1 = 1),
        list(name = "analysis_2", var_1 = 2)
      )
    )
    p$get_analysis("analysis_1")

------------------------------------------------------------------------

### `Plan$get_argset()`

Get the argset of one analysis.

#### Usage

    Plan$get_argset(index_analysis)

#### Arguments

- `index_analysis`:

  The position of the analysis, or its name.

#### Returns

The argset, a named list.

#### Examples

    p <- plnr::Plan$new()
    p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
    p$add_analysis_from_list(
      fn_name = "plnr::example_action_fn",
      l = list(
        list(name = "analysis_1", var_1 = 1),
        list(name = "analysis_2", var_1 = 2)
      )
    )
    p$get_argset("analysis_1")

------------------------------------------------------------------------

### `Plan$get_argsets_as_dt()`

Get every argset as one row of a data.table.

#### Usage

    Plan$get_argsets_as_dt()

#### Returns

A data.table. Its first columns are `name_analysis` and
`index_analysis`, and it has one more column for each argset element.

#### Examples

    p <- plnr::Plan$new()
    p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
    p$add_analysis_from_list(
      fn_name = "plnr::example_action_fn",
      l = list(
        list(name = "analysis_1", var_1 = 1),
        list(name = "analysis_2", var_1 = 2)
      )
    )
    p$get_argsets_as_dt()

------------------------------------------------------------------------

### `Plan$run_one_with_data()`

Run one analysis on data that you give it.

#### Usage

    Plan$run_one_with_data(index_analysis, data, ...)

#### Arguments

- `index_analysis`:

  The position of the analysis, or its name.

- `data`:

  A named list of datasets, normally from `get_data()`.

- `...`:

  Further arguments for the action function. See 'Details'.

#### Returns

The value that the action function returns.

#### Examples

    p <- plnr::Plan$new()
    p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
    p$add_analysis_from_list(
      fn_name = "plnr::example_action_fn",
      l = list(
        list(name = "analysis_1", var_1 = 1),
        list(name = "analysis_2", var_1 = 2)
      )
    )
    data <- p$get_data()
    p$run_one_with_data("analysis_1", data)

------------------------------------------------------------------------

### `Plan$run_one()`

Run one analysis. `run_one()` loads the data with `get_data()` each time
you call it.

#### Usage

    Plan$run_one(index_analysis, ...)

#### Arguments

- `index_analysis`:

  The position of the analysis, or its name.

- `...`:

  Further arguments for the action function. See 'Details'.

#### Returns

The value that the action function returns.

#### Examples

    p <- plnr::Plan$new()
    p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
    p$add_analysis_from_list(
      fn_name = "plnr::example_action_fn",
      l = list(
        list(name = "analysis_1", var_1 = 1),
        list(name = "analysis_2", var_1 = 2)
      )
    )
    p$run_one("analysis_1")

------------------------------------------------------------------------

### `Plan$run_all_with_data()`

Run every analysis on data that you give it.

#### Usage

    Plan$run_all_with_data(data, ..., .plnr.options = NULL)

#### Arguments

- `data`:

  A named list of datasets, normally from `get_data()`.

- `...`:

  Further arguments for the action function. See 'Details'.

- `.plnr.options`:

  A list of options for plnr. The action function does not get it.
  `chunk_size` goes to foreach as
  `.options.future = list(chunk.size = chunk_size)`. Only a future-based
  backend, such as doFuture, reads it. The default is 1.

#### Returns

A list, invisibly. Element `i` is the value that the action function of
analysis `i` returns. Without foreach, a `NULL` value at the end of the
plan adds no element, so the list can be shorter than the plan.

#### Examples

    p <- plnr::Plan$new()
    p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
    p$add_analysis_from_list(
      fn_name = "plnr::example_action_fn",
      l = list(
        list(name = "analysis_1", var_1 = 1),
        list(name = "analysis_2", var_1 = 2)
      )
    )
    data <- p$get_data()
    results <- p$run_all_with_data(data)

------------------------------------------------------------------------

### `Plan$run_all()`

Run every analysis. `run_all()` loads the data once with `get_data()`,
and passes it to every analysis.

#### Usage

    Plan$run_all(...)

#### Arguments

- `...`:

  Further arguments for the action function, and `.plnr.options`.
  `run_all_with_data()` describes both.

#### Returns

A list, invisibly, as `run_all_with_data()` returns it.

#### Examples

    p <- plnr::Plan$new()
    p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
    p$add_analysis_from_list(
      fn_name = "plnr::example_action_fn",
      l = list(
        list(name = "analysis_1", var_1 = 1),
        list(name = "analysis_2", var_1 = 2)
      )
    )
    results <- p$run_all()

------------------------------------------------------------------------

### `Plan$run_all_progress()`

Run every analysis, as `run_all()` does, inside
[`progressr::with_progress()`](https://progressr.futureverse.org/reference/with_progress.html).
A progressr progressor then shows progress. It stops with an error when
the progressr package is not installed.

#### Usage

    Plan$run_all_progress(...)

#### Arguments

- `...`:

  Passed to `run_all()`.

#### Returns

A list, invisibly, as `run_all()` returns it.

#### Examples

    p <- plnr::Plan$new()
    p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
    p$add_analysis_from_list(
      fn_name = "plnr::example_action_fn",
      l = list(
        list(name = "analysis_1", var_1 = 1),
        list(name = "analysis_2", var_1 = 2)
      )
    )
    if (requireNamespace("progressr", quietly = TRUE)) {
      results <- p$run_all_progress()
    }

------------------------------------------------------------------------

### `Plan$run_all_parallel()`

Run every analysis in forked processes with
[`pbmcapply::pbmclapply()`](https://rdrr.io/pkg/pbmcapply/man/pbmclapply.html),
which shows a progress bar. It loads the data once with `get_data()`.
Windows cannot fork. There, pbmcapply sets `mc.cores` to 1, warns, and
runs the analyses in sequence.

#### Usage

    Plan$run_all_parallel(mc.cores = getOption("mc.cores", 2L), ...)

#### Arguments

- `mc.cores`:

  The number of processes.

- `...`:

  Further arguments for the action function. See 'Details'.

#### Returns

A list, invisibly. Element `i` is the value that the action function of
analysis `i` returns.

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
data_fn <- function() {
  return(plnr::nor_covid19_cases_by_time_location)
}
p$add_data("data_1", fn = data_fn)
p$add_data("data_2", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
p$add_data("data_3", direct = plnr::nor_covid19_cases_by_time_location)
names(p$get_data())
#> [1] "data_1" "data_2" "data_3" "hash"  

## ------------------------------------------------
## Method `Plan$add_argset()`
## ------------------------------------------------

p <- plnr::Plan$new()
p$add_argset("argset_1", var_1 = 3, var_b = "hello")
p$add_argset("argset_2", var_1 = 8, var_c = "hello2")
p$get_argsets_as_dt()
#>    name_analysis index_analysis  var_1  var_b  var_c
#>           <char>          <int> <list> <list> <list>
#> 1:      argset_1              1      3  hello [NULL]
#> 2:      argset_2              2      8 [NULL] hello2

## ------------------------------------------------
## Method `Plan$add_argset_from_df()`
## ------------------------------------------------

p <- plnr::Plan$new()
p$add_argset_from_df(data.frame(name = c("a", "b"), var_1 = c(1, 2)))
p$get_argsets_as_dt()
#>    name_analysis index_analysis  var_1
#>           <char>          <int> <list>
#> 1:             a              1      1
#> 2:             b              2      2

## ------------------------------------------------
## Method `Plan$add_argset_from_list()`
## ------------------------------------------------

p <- plnr::Plan$new()
p$add_argset_from_list(plnr::expand_list(var_1 = 1:2, var_2 = c("i", "j")))
p$get_argsets_as_dt()
#>                           name_analysis index_analysis  var_1  var_2
#>                                  <char>          <int> <list> <list>
#> 1: 44a5a9d3-41c2-4664-8548-4199cf82c063              1      1      i
#> 2: 538102a9-441c-4626-b496-31b018081ca3              2      1      j
#> 3: 2e0882d0-fb08-4156-9061-39d02e85fb74              3      2      i
#> 4: 79a8d43d-6c03-4db9-b0d7-2299c6f0c35f              4      2      j

## ------------------------------------------------
## Method `Plan$add_analysis()`
## ------------------------------------------------

p <- plnr::Plan$new()
p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
p$add_analysis(name = "analysis_1", fn_name = "plnr::example_action_fn")
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
p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
p$add_analysis_from_df(
  fn_name = "plnr::example_action_fn",
  df = data.frame(name = c("a", "b"), var_1 = c(1, 2))
)
p$run_one("a")
#> [1] "Data given:"
#> [1] "covid_data" "hash"      
#> [1] "Argset given:"
#> [1] "var_1"          "index_analysis"
#> [1] "var_1"          "index_analysis"

## ------------------------------------------------
## Method `Plan$add_analysis_from_list()`
## ------------------------------------------------

p <- plnr::Plan$new()
p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
p$add_analysis_from_list(
  fn_name = "plnr::example_action_fn",
  l = list(
    list(name = "analysis_1", var_1 = 1),
    list(name = "analysis_2", var_1 = 2)
  )
)
p$run_one("analysis_1")
#> [1] "Data given:"
#> [1] "covid_data" "hash"      
#> [1] "Argset given:"
#> [1] "var_1"          "index_analysis"
#> [1] "var_1"          "index_analysis"

## ------------------------------------------------
## Method `Plan$apply_action_fn_to_all_argsets()`
## ------------------------------------------------

p <- plnr::Plan$new()
p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
p$add_argset_from_list(list(
  list(name = "analysis_1", var_1 = 1),
  list(name = "analysis_2", var_1 = 2)
))
p$apply_action_fn_to_all_argsets(fn_name = "plnr::example_action_fn")
p$run_one("analysis_1")
#> [1] "Data given:"
#> [1] "covid_data" "hash"      
#> [1] "Argset given:"
#> [1] "var_1"          "index_analysis"
#> [1] "var_1"          "index_analysis"

## ------------------------------------------------
## Method `Plan$get_data()`
## ------------------------------------------------

p <- plnr::Plan$new()
p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
str(p$get_data(), max.level = 1)
#> List of 2
#>  $ covid_data:Classes ‘data.table’ and 'data.frame': 11028 obs. of  18 variables:
#>   ..- attr(*, ".internal.selfref")=<pointer: (nil)> 
#>   ..- attr(*, "index")= int(0) 
#>  $ hash      :List of 2

## ------------------------------------------------
## Method `Plan$get_analysis()`
## ------------------------------------------------

p <- plnr::Plan$new()
p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
p$add_analysis_from_list(
  fn_name = "plnr::example_action_fn",
  l = list(
    list(name = "analysis_1", var_1 = 1),
    list(name = "analysis_2", var_1 = 2)
  )
)
p$get_analysis("analysis_1")
#> $fn
#> NULL
#> 
#> $fn_name
#> [1] "plnr::example_action_fn"
#> 
#> $fn_env
#> NULL
#> 
#> $argset
#> $argset$var_1
#> [1] 1
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
p$add_analysis_from_list(
  fn_name = "plnr::example_action_fn",
  l = list(
    list(name = "analysis_1", var_1 = 1),
    list(name = "analysis_2", var_1 = 2)
  )
)
p$get_argset("analysis_1")
#> $var_1
#> [1] 1
#> 

## ------------------------------------------------
## Method `Plan$get_argsets_as_dt()`
## ------------------------------------------------

p <- plnr::Plan$new()
p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
p$add_analysis_from_list(
  fn_name = "plnr::example_action_fn",
  l = list(
    list(name = "analysis_1", var_1 = 1),
    list(name = "analysis_2", var_1 = 2)
  )
)
p$get_argsets_as_dt()
#>    name_analysis index_analysis  var_1
#>           <char>          <int> <list>
#> 1:    analysis_1              1      1
#> 2:    analysis_2              2      2

## ------------------------------------------------
## Method `Plan$run_one_with_data()`
## ------------------------------------------------

p <- plnr::Plan$new()
p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
p$add_analysis_from_list(
  fn_name = "plnr::example_action_fn",
  l = list(
    list(name = "analysis_1", var_1 = 1),
    list(name = "analysis_2", var_1 = 2)
  )
)
data <- p$get_data()
p$run_one_with_data("analysis_1", data)
#> [1] "Data given:"
#> [1] "covid_data" "hash"      
#> [1] "Argset given:"
#> [1] "var_1"          "index_analysis"
#> [1] "var_1"          "index_analysis"

## ------------------------------------------------
## Method `Plan$run_one()`
## ------------------------------------------------

p <- plnr::Plan$new()
p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
p$add_analysis_from_list(
  fn_name = "plnr::example_action_fn",
  l = list(
    list(name = "analysis_1", var_1 = 1),
    list(name = "analysis_2", var_1 = 2)
  )
)
p$run_one("analysis_1")
#> [1] "Data given:"
#> [1] "covid_data" "hash"      
#> [1] "Argset given:"
#> [1] "var_1"          "index_analysis"
#> [1] "var_1"          "index_analysis"

## ------------------------------------------------
## Method `Plan$run_all_with_data()`
## ------------------------------------------------

p <- plnr::Plan$new()
p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
p$add_analysis_from_list(
  fn_name = "plnr::example_action_fn",
  l = list(
    list(name = "analysis_1", var_1 = 1),
    list(name = "analysis_2", var_1 = 2)
  )
)
data <- p$get_data()
results <- p$run_all_with_data(data)
#> [1] "Data given:"
#> [1] "covid_data" "hash"      
#> [1] "Argset given:"
#> [1] "var_1"          "index_analysis"
#> [1] "Data given:"
#> [1] "covid_data" "hash"      
#> [1] "Argset given:"
#> [1] "var_1"          "index_analysis"

## ------------------------------------------------
## Method `Plan$run_all()`
## ------------------------------------------------

p <- plnr::Plan$new()
p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
p$add_analysis_from_list(
  fn_name = "plnr::example_action_fn",
  l = list(
    list(name = "analysis_1", var_1 = 1),
    list(name = "analysis_2", var_1 = 2)
  )
)
results <- p$run_all()
#> [1] "Data given:"
#> [1] "covid_data" "hash"      
#> [1] "Argset given:"
#> [1] "var_1"          "index_analysis"
#> [1] "Data given:"
#> [1] "covid_data" "hash"      
#> [1] "Argset given:"
#> [1] "var_1"          "index_analysis"

## ------------------------------------------------
## Method `Plan$run_all_progress()`
## ------------------------------------------------

p <- plnr::Plan$new()
p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
p$add_analysis_from_list(
  fn_name = "plnr::example_action_fn",
  l = list(
    list(name = "analysis_1", var_1 = 1),
    list(name = "analysis_2", var_1 = 2)
  )
)
if (requireNamespace("progressr", quietly = TRUE)) {
  results <- p$run_all_progress()
}
#> [1] "Data given:"
#> [1] "covid_data" "hash"      
#> [1] "Argset given:"
#> [1] "var_1"          "index_analysis"
#> [1] "Data given:"
#> [1] "covid_data" "hash"      
#> [1] "Argset given:"
#> [1] "var_1"          "index_analysis"
```
