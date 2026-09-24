# Version 2026.9.24

## Bug fixes

- `run_all()` with foreach returned a `gc()` matrix for every analysis. It now returns what each action function returns.
- A `fn_name` now resolves first in the local environment where it resolved when you added it, then in the global environment and on the search path, and last in plnr. A plnr function no longer wins over your function of the same name. The plan stores only that local environment. `get_anything()` gains `envir` and `mode`.
- The vignettes now knit with `rmarkdown::render(envir = new.env())`. They failed with `object 'fn_fig_1' not found`.
- `progress` is now in Imports. The default verbose path of `run_all()` called it without declaring it.
- `.plnr.options = list(chunk_size = n)` now reaches foreach. It no longer reaches the action function.
- `add_argset()` and `add_analysis()` no longer copy the whole list of analyses on every call.
- `create_rmarkdown()` now ends every file that it writes with a newline.

## Behaviour changes

- `add_argset_from_df()` and `add_analysis_from_df()` with zero rows add nothing. They failed, and left an analysis named `NA`.
- `get_argsets_as_dt()` reads the element `argset` exactly. An element named `argsets` no longer counts as the argset.
- With `use_foreach = NULL` and one registered worker, `run_all()` no longer loads the progressr namespace.
- Errors that plnr raises itself, such as "Both fn and fn_name are NULL", carry no call. The messages are unchanged.
- Without progressr, `run_all()` with foreach and `verbose = TRUE` runs without a progress bar. It failed. `run_all_progress()` without progressr now stops with a message that names the package.

## Checks

- The code passes the static-checks lint gate again. It had failed since 2026-08-26, so pkgdown had not deployed since 2026.8.21.
- `R/plan.R` is exempt from two lint rules, `cyclocomp_linter` and `vector_logic_linter`, because their fixes change behaviour.

## Documentation

- The help pages, both vignettes, `README.md`, `index.md` and the `DESCRIPTION` text follow ASD-STE100.
- No page claims hash-based caching. `get_data()` computes digests but plnr never reads them.
- The help pages now say that `...` goes to the action function, and give the true return values.


# Version 2026.9.23

- This CRAN release carries the `Plan$add_analysis_from_list()` fix from
  2026.8.3 (#1). CRAN version 2025.11.22 does not have it.
- `DESCRIPTION` now declares `R (>= 4.1.0)`, because the code uses the base pipe `|>`.


# Version 2026.8.21

- The package drops `magrittr`. Every `%>%` is now the base pipe `|>`, and
  `magrittr` is gone from `DESCRIPTION`.
- The rewrite is a relocation, not an edit. Each `%>%` call was transformed the
  way R's parser transforms `|>`, and the resulting tree was required to match
  the tree parsed from the rewritten file. A file whose trees disagreed was left
  untouched and converted by hand instead.


# Version 2026.8.6

## Licensing

- `DESCRIPTION` `Authors@R` now declares **Richard Aubrey White** as the
  copyright holder, with `role = "cph"`. It declared none at all, and
  neither did any other package in the fleet. Nothing in `R CMD check`
  reports that.
- The copyright year is now 2026. It read 2025.
- `CLAUDE.md` now carries a Licensing section, so the year gets checked
  rather than silently ageing.

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
