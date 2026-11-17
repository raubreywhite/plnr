## Summary

This release moves plnr from the CRAN version 2026.9.23 to 2026.11.17. It includes the changes of versions 2026.9.24 and 2026.11.16, which were not sent to CRAN.

### New feature: data that depends on the argset

- The key fields of a data function are its arguments without a default, other than `...`.
- `run_all()` and `run_all_parallel()` call such a function once for each distinct set of values. Analyses with the same values share the dataset.
- A data function without key fields runs as before. A data function with a key field failed before if it used that argument. One that did not use it now needs the field in every argset.
- The local csalert source calls `add_data()` once, in `dev/`, which `.Rbuildignore` excludes. That data function has no arguments.
- `get_data()` gains the argument `index_analysis`.

### Removed functions

- This release removes `create_rmarkdown()` and `try_again()`.
- No known project calls either function.
- The project that `create_rmarkdown()` wrote did not run. Its `run.R` stopped with "object 'table_death' of mode 'function' was not found".
- Users who need either function can stay on plnr 2026.9.23, the current CRAN version.
- plnr no longer imports fs, glue, stats or usethis.

### Bug fixes

- `run_all()` with foreach returned a `gc()` matrix for every analysis. It now returns what each action function returns.
- `run_all()` with foreach on a PSOCK cluster failed with "object 'private' not found". The foreach call now exports what the workers need.
- A `fn_name` now resolves first in the local environment where you added it. Then it resolves in the global environment and on the search path, and last in plnr.
- A plnr function therefore no longer wins over your function of the same name.
- `progress` is now in Imports. The default verbose path of `run_all()` used it without a declaration.
- `.plnr.options = list(chunk_size = n)` now reaches foreach, and no longer reaches the action function.
- `add_argset()` and `add_analysis()` no longer copy the whole list of analyses on every call.
- The vignettes now knit with `rmarkdown::render(envir = new.env())`. They failed with "object 'fn_fig_1' not found".

### Behaviour changes

- `add_argset_from_df()` and `add_analysis_from_df()` with zero rows add nothing. They failed, and left an analysis named `NA`.
- `get_argsets_as_dt()` reads the element `argset` by exact name. An element named `argsets` no longer counts as the argset.
- With `use_foreach = NULL` and one registered worker, `run_all()` no longer loads the progressr namespace.
- Without progressr, `run_all()` with foreach and `verbose = TRUE` runs without a progress bar. It failed.
- Without progressr, `run_all_progress()` stops with a message that names the package.
- Errors that plnr raises itself carry no call. The messages are unchanged.
- `get_anything()` gains the arguments `envir` and `mode`.

## Test environments

- Local: Ubuntu 22.04.5 LTS, x86_64-pc-linux-gnu, R 4.6.0 (2026-04-24).

## R CMD check results

`devtools::check(args = c("--no-manual", "--as-cran"))` with `_R_CHECK_CRAN_INCOMING_=false`: 0 errors | 0 warnings | 0 notes.

- The check did not run the CRAN incoming checks, because `_R_CHECK_CRAN_INCOMING_` was `false`.
- The check did not build the PDF manual, because it used `--no-manual`.

## Reverse dependencies

`tools::package_dependencies("plnr", reverse = TRUE, which = "all")` against CRAN returns one package, csalert.

csalert 2024.6.24, the CRAN version, lists plnr in Suggests. Its source tarball names plnr only in that `DESCRIPTION` field. It does not call `create_rmarkdown()` or `try_again()`. We did not run `R CMD check` on csalert for this release.
