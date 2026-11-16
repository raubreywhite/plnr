# Package index

## Plan Management

Classes and functions related to defining and managing an analysis plan.

- [`Plan`](https://www.rwhite.no/plnr/reference/Plan.md) : Plan and run
  analyses

## Utility Functions

General-purpose utility functions for various tasks.

- [`expand_list()`](https://www.rwhite.no/plnr/reference/expand_list.md)
  : Make a list of argsets from every combination of values
- [`get_anything()`](https://www.rwhite.no/plnr/reference/get_anything.md)
  : Find an object by name
- [`is_run_directly()`](https://www.rwhite.no/plnr/reference/is_run_directly.md)
  : Check whether code runs at the top level of the console
- [`set_opts()`](https://www.rwhite.no/plnr/reference/set_opts.md) : Set
  plnr options

## Testing Functions

Functions designed for testing analysis workflows.

- [`example_action_fn()`](https://www.rwhite.no/plnr/reference/example_action_fn.md)
  : Print what an action function receives
- [`example_data_fn_nor_covid19_cases_by_time_location()`](https://www.rwhite.no/plnr/reference/example_data_fn_nor_covid19_cases_by_time_location.md)
  : Return the example Covid-19 dataset
- [`nor_covid19_cases_by_time_location`](https://www.rwhite.no/plnr/reference/nor_covid19_cases_by_time_location.md)
  : Covid-19 cases confirmed by PCR in Norway, by nation and county
- [`test_action_fn()`](https://www.rwhite.no/plnr/reference/test_action_fn.md)
  : Return 1, whatever the input
