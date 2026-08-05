# Version 2026.8.3

- Mostly documentation and roxygen comments, plus two bug fixes that do change
  behaviour: `create_rmarkdown()` and `Plan$add_analysis_from_list()`. Both are
  described below. Apart from those two, the R sources are semantically
  identical to the previous release.
- `@seealso` added to all ten exported functions. Eight point at the vignette
  that covers them; `set_opts()` and `try_again()` are not covered by either
  vignette, and their text says so rather than implying coverage.
- `@family example and test functions` added to `example_action_fn()`, `test_action_fn()` and `example_data_fn_nor_covid19_cases_by_time_location()`.
- Runnable examples added to `example_data_fn_nor_covid19_cases_by_time_location()` and `test_action_fn()`, which previously had none.
- `try_again()` examples taken out of `\dontrun{}`. They now run, and show a retry that fails once and succeeds on the second attempt.
- `create_rmarkdown()` examples moved from `\dontrun{}` to `\donttest{}`, so `R CMD check` runs them.
- Fixed `create_rmarkdown()`, which evaluated `{lubridate::today()}` while
  generating `run.R` instead of writing it out literally. The brace was not
  escaped, so glue resolved it at generation time. Two consequences: every
  generated project had a frozen date baked in rather than one that evaluates
  when the user runs it, and `create_rmarkdown()` silently required lubridate,
  which plnr does not depend on. Both are gone.
- `index.md` and `Rplots.pdf` added to `.Rbuildignore`, so the pkgdown home page source is no longer shipped in the tarball.
- Fixed `Plan$add_analysis_from_list()`, which decided whether to apply the
  method-level `fn_name` by reading `names(df)`. `df` is not a parameter of that
  method and is not defined in it, so the lookup escaped to whatever `df` the
  search path happened to offer: normally `stats::df`, the F-distribution
  density. `names(stats::df)` is `NULL`, so the guard always passed and the
  mistake stayed invisible. It now reads `names(argset)`, which is what the line
  above it builds and what the sibling `add_analysis_from_df()` guards on. Two
  consequences: an argset that carries its own `fn_name` keeps it instead of
  being silently overwritten, matching `add_analysis_from_df()`; and the method
  no longer fails when `stats` is not attached, which is how `R CMD check` loads
  a package in its minimal-namespace tests. Covered by
  `tests/testthat/test-add-analysis-from-list.R`.

# Version 2025.11.22

- Replacing `purrr::cross` with `tidyr::expand_grid()`

# Version 2025.3.19

- Comprehensive improvements to roxygen2 documentation across all R files:
  - Enhanced Plan class documentation with better structure and clearer explanations
  - Improved method documentation with detailed parameter descriptions and examples
  - Added comprehensive documentation for internal functions
  - Enhanced documentation for utility functions (is_run_directly, get_anything, expand_list)
  - Added detailed examples and usage patterns for all functions
  - Improved clarity and consistency across all documentation

# Version 2024.1.18

- plan$run_all_parallel public method created.

# Version 2022.6.8

- plan$set_use_foreach public method created

# Version 2022.6.7

- CRAN submission
- Additional documentation
- Moving some plan public fields into private

# Version 2022.5.27

- Including new vignette explaining how to add analyses to a plan.

# Version 2022.4.6

- Inclusion of hash functions in get_data.

# Version 2021.6.9

- Inclusion of easy_split.

# Version 2020.5.11

- fn_name can now take package::function_name arguments.

# Version 2020.5.4

- is_run_directly function created, allowing the user to see if their code is being run directly or from within a function.

# Version 2020.4.3

- set_opts function created, allowing for force_verbose to be set package wide.

# Version 2020.2.20

- create_rmarkdown skeleton created.

# Version 2020.1.28

- parallel_possible variable when initializing new Plan.
