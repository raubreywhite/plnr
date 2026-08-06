# Version 2026.8.6

## Corrections

- `try_again()` was titled "Retry code execution with exponential backoff". It
  does not implement exponential backoff. The delay is
  `stats::runif(1, delay_seconds_min, delay_seconds_max)`, drawn afresh before
  every retry from fixed bounds that the loop never reassigns, so it does not
  grow with the attempt number. The title now names the real behaviour, and the
  description says what the delay is and what it is not. No code changed, and
  the arguments and their defaults are untouched.

- Prose only. This release rewrites the roxygen documentation, both vignettes,
  `README.md`, `index.md` and `NEWS.md` to ASD-STE100 (Simplified Technical
  English). The R sources are semantically identical to the previous release.
- No claim changed. The sweep found documented claims that the code does not
  support. It left every one of those claims in place, and reported it.
- The rewrite splits long sentences, prefers the active voice, and uses one term
  for each concept. It also uses the RFC-2119 keywords MUST and MAY in the
  `test_action_fn()` `@seealso`, which states the action-function contract.

# Version 2026.8.3

- This release is mostly documentation and roxygen comments. It also carries two
  bug fixes that do change behavior: `create_rmarkdown()` and
  `Plan$add_analysis_from_list()`. The entries below describe both. Apart from
  those two fixes, the R sources are semantically identical to the previous
  release.
- `@seealso` added to all ten exported functions. Eight point at the vignette
  that covers them. No vignette covers `set_opts()` or `try_again()`, and the
  text of those two says so.
- `@family example and test functions` added to `example_action_fn()`, `test_action_fn()` and `example_data_fn_nor_covid19_cases_by_time_location()`.
- Runnable examples added to `example_data_fn_nor_covid19_cases_by_time_location()` and `test_action_fn()`, which previously had none.
- `try_again()` examples taken out of `\dontrun{}`. They now run, and show a retry that fails once and succeeds on the second attempt.
- `create_rmarkdown()` examples moved from `\dontrun{}` to `\donttest{}`, so `R CMD check` runs them.
- Fixed `create_rmarkdown()`, which evaluated `{lubridate::today()}` while it
  generated `run.R`, instead of writing the brace out literally. The brace was
  not escaped, so glue resolved it at generation time. That had two
  consequences. Every generated project carried a frozen date, not one that
  evaluates when the user runs it. `create_rmarkdown()` also silently needed
  lubridate, which plnr does not depend on. Both consequences are gone.
- `index.md` and `Rplots.pdf` added to `.Rbuildignore`, so `R CMD build` no
  longer ships the pkgdown home page source in the tarball.
- Fixed `Plan$add_analysis_from_list()`. It decided whether to apply the
  method-level `fn_name` by reading `names(df)`. `df` is not a parameter of that
  method, and the method does not define it. The lookup therefore escaped to
  whatever `df` the search path offered, normally `stats::df`, the
  F-distribution density. `names(stats::df)` is `NULL`, so the guard always
  passed and the mistake stayed invisible. The method now reads
  `names(argset)`. That is what the line above it builds, and what the sibling
  `add_analysis_from_df()` guards on. The fix has two consequences. An argset
  that carries its own `fn_name` keeps it, instead of losing it to a silent
  overwrite, which matches `add_analysis_from_df()`. The method also no longer
  fails when `stats` is not attached, which is how `R CMD check` loads a package
  in its minimal-namespace tests. `tests/testthat/test-add-analysis-from-list.R`
  covers the fix.

# Version 2025.11.22

- Replaced `purrr::cross` with `tidyr::expand_grid()`.

# Version 2025.3.19

- Improvements to roxygen2 documentation across all R files:
  - Restructured the Plan class documentation and made the explanations clearer
  - Added detailed parameter descriptions and examples to the method documentation
  - Added documentation for the internal functions
  - Added documentation for the utility functions `is_run_directly()`, `get_anything()` and `expand_list()`
  - Added detailed examples and usage patterns for all functions
  - Made all the documentation clearer and more consistent

# Version 2024.1.18

- Created the `plan$run_all_parallel()` public method.

# Version 2022.6.8

- Created the `plan$set_use_foreach()` public method.

# Version 2022.6.7

- CRAN submission.
- Additional documentation.
- Moved some plan public fields into private.

# Version 2022.5.27

- Added a new vignette that explains how to add analyses to a plan.

# Version 2022.4.6

- Added hash functions to `get_data()`.

# Version 2021.6.9

- Added `easy_split()`.

# Version 2020.5.11

- `fn_name` can now take `package::function_name` arguments.

# Version 2020.5.4

- Created the `is_run_directly()` function. It shows the user whether their code
  runs directly, or from within a function.

# Version 2020.4.3

- Created the `set_opts()` function. It sets `force_verbose` package wide.

# Version 2020.2.20

- Created the `create_rmarkdown()` skeleton.

# Version 2020.1.28

- Added the `parallel_possible` variable for a new Plan.
