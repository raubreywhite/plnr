## Summary

This release fixes `Plan$add_analysis_from_list()`, which read `names(df)` instead of the argset and failed with "object 'df' not found" when stats was not attached.

## Test environments

- Local: Windows 11 x64 (build 22631), R 4.5.2 (2025-10-31 ucrt).

## R CMD check results

`R CMD check --as-cran --no-manual`: 0 errors | 0 warnings | 0 notes.

- Some runs gave one more NOTE: "checking for future file timestamps ... unable to verify current time". The local network could not reach worldtimeapi.org or worldclockapi.com.
- The PDF manual was not checked, because this machine has no LaTeX.
- The HTML manual passed validation with HTML Tidy 5.8.0.

## Reverse dependencies

csalert 2024.6.24 lists plnr in Suggests. `R CMD check --no-manual` of csalert with plnr 2026.9.23 gave "Status: OK".
