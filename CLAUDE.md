# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**plnr** is an R package that provides a framework for planning and executing analyses. The core concept is the `Plan` R6 class, which enables systematic execution of analyses with flexible data management, parameter sets (argsets), and parallel processing capabilities.

Key use cases:
- Run the same analysis function with different parameters across strata (locations, age groups, etc.)
- Execute multiple analysis functions on the same datasets
- Generate multiple tables/graphs systematically
- Create reproducible surveillance analyses

## Development Commands

### Standard R Package Operations

```r
# Load package functions during development
devtools::load_all(".")

# Generate roxygen2 documentation from R code comments
devtools::document()

# Basic package validation
devtools::check()

# REQUIRED: CRAN compliance check (always run before commits/PRs)
R CMD check . --as-cran

# Build package
devtools::build()

# Install package locally
devtools::install()
```

### Testing

```r
# Run all tests
devtools::test()

# Run specific test file
devtools::test_file("tests/testthat/test_InitialiseProject.R")

# Run tests with coverage
devtools::test_coverage()
```

### Documentation Website

```r
# Build pkgdown documentation site
pkgdown::build_site()

# Preview changes to vignettes before commit
pkgdown::build_articles()
```

## Architecture Overview

### Core Component: The Plan Class (R/plan.R)

The `Plan` R6 class (`~790 lines`) is the centerpiece of the framework. Key methods:

**Data Management:**
- `add_data(name, fn_name = NULL, direct = NULL, ...)` - Load data once, reuse across analyses
- `get_data(name)` - Retrieve loaded data with hash tracking

**Parameter Definition:**
- `add_argset(name, ...)` - Add single parameter set
- `add_argset_from_df()` - Batch add from dataframe
- `add_argset_from_list()` - Batch add from list

**Analysis Definition:**
- `add_analysis(name, fn_name, argset_name = NULL)` - Define single analysis
- `add_analysis_from_df()` - Batch from dataframe
- `add_analysis_from_list()` - Batch from list

**Execution:**
- `apply_action_fn_to_all_argsets(fn_name)` - Apply function to all parameter sets
- `apply_analysis_fn_to_all()` - Apply function to all analyses
- `run_one(name)` - Execute single analysis
- `run_all()` - Sequential execution
- `run_all_parallel()` - Parallel execution

**Debugging:**
- `get_analysis(name)` - Retrieve analysis object for inspection
- `get_argset(name)` - Retrieve parameter set for inspection

### Supporting Functions

- **R/create_rmarkdown.R** - Project template generation utilities
- **R/expand_list.R** - List expansion helpers
- **R/get_anything.R** - Generic getter utility
- **R/is_run_directly.R** - Debug utility to detect direct vs. function execution
- **R/try_again.R** - Retry logic with exponential backoff
- **R/set_opts.R** - Global configuration options
- **R/0_env.R, R/1_config.R, R/2_onLoad.R, R/3_onAttach.R** - Package initialization

### Data and Examples

- **data/** - Pre-built example dataset (Norwegian COVID-19 cases by time and location)
- **data-raw/** - Scripts to regenerate example data
- **inst/extdata/** - Additional data files for examples

## Design Principles

### Analysis Function Signature
All analysis functions must follow this standard signature:
```r
function(data, argset) {
  # data: list of loaded datasets
  # argset: list of analysis-specific parameters
  # Return: results (any format)
}
```

### Separation of Concerns
- **Data loading:** Happens once via `add_data()`
- **Parameters:** Defined separately via `add_argset()`
- **Analysis:** Function only receives data and argset
- **Execution:** Plan orchestrates sequential or parallel runs

### Hash-based Caching
Data changes are tracked via `digest::digest()` hashes. This enables:
- Reproducibility verification
- Optimization of analysis execution
- Debugging of data dependencies

## Package Dependencies

**Core Imports:**
- `data.table` - Efficient data manipulation
- `R6` - Object-oriented programming (Plan class)
- `foreach` - Parallel execution framework
- `digest` - Hash functions for data tracking
- `fs`, `glue`, `pbmcapply`, `tidyr`, `uuid`, `stats`, `utils`, `usethis`

**Suggests (optional):**
- `testthat` - Unit testing framework
- `knitr`, `rmarkdown` - Vignette compilation
- `ggplot2`, `readxl`, `magrittr` - Example dependencies

## Code Organization

- **roxygen2 documentation:** All .Rd files auto-generated from R code comments
- **Markdown support:** Uses `RoxygenNote: 7.3.2` with markdown = TRUE
- **Vignettes:** 2 comprehensive guides (plnr.Rmd, adding_analyses.Rmd)
- **Tests:** Single test file covering basic Plan initialization

### Documentation Standards

- Use roxygen2 markdown format (`#'` comments with `@family`, `@seealso`, `@examples`)
- Include runnable examples in `@examples` sections
- Document `@param`, `@return`, and side effects clearly
- Vignettes use sentence case titles ("Understanding concepts" not "Understanding Concepts")

## Pre-Commit Checklist

Before committing changes:

1. **Run CRAN compliance check** (non-negotiable):
   ```bash
   R CMD check . --as-cran
   ```

2. **Document code** if you modified any R functions:
   ```r
   devtools::document()
   ```

3. **Run tests**:
   ```r
   devtools::test()
   ```

4. **Remove non-portable files:**
   - Delete any `@eaDir/` directories (macOS metadata)
   - `.DS_Store` files should be in .gitignore

5. **Check version format** in DESCRIPTION:
   - Use YY.M.D format (e.g., 25.3.19 for March 19, 2025)
   - Remove leading zeroes from month/day

6. **Update NEWS.md** with version changes when updating DESCRIPTION version

## GitHub Actions CI/CD

The repository has GitHub Actions workflows that automatically:

1. **check-and-deploy.yml** - Runs on push to main/develop and PRs
   - Validates with `R CMD check --as-cran`
   - Builds pkgdown documentation
   - Deploys docs to GitHub Pages

2. **check-and-pkgdown.yml** - Additional CRAN check and docs build

3. **rhub.yaml** - Manual R-hub testing (dispatch via GitHub Actions UI)
   - Tests on multiple platforms (Linux, Windows, macOS)

These workflows ensure CRAN compliance automatically.

## Documentation Website

The package website (https://www.rwhite.no/plnr/) is auto-generated by pkgdown from:
- roxygen2 function documentation
- Vignette files (Rmarkdown)
- README.md
- Custom _pkgdown.yml configuration

After local changes, test with `pkgdown::build_site()` before pushing.

## Common Development Tasks

### Adding a New Analysis Function

1. Create function in `R/` directory following the standard signature:
   ```r
   #' Analysis function
   #' @param data list of datasets
   #' @param argset parameter set
   #' @examples
   #' \dontrun{
   #'   result <- analysis_fn(list(dataset=mtcars), list(param=1))
   #' }
   my_analysis_fn <- function(data, argset) {
     # implementation
   }
   ```

2. Document with roxygen2:
   ```r
   devtools::document()
   ```

3. Add test in `tests/testthat/`:
   ```r
   test_that("my_analysis_fn works", {
     # test code
   })
   ```

4. Update vignettes if adding user-facing functionality

### Running the example workflow

See `README.md` for the quick example, or check vignettes:
- `vignettes/plnr.Rmd` - Introduction
- `vignettes/adding_analyses.Rmd` - How to add analyses to a plan

### Parallel execution considerations

- `run_all_parallel()` uses `foreach` and `pbmcapply` packages
- Requires `doParallel` or similar foreach backend to be registered
- Progress reporting available via `progressr` package
- Test both sequential and parallel execution for new features

## Version Management

**Version Format:** YY.M.D (e.g., 25.3.19 for March 19, 2025)

When updating version in DESCRIPTION:
1. Update `Version:` field with YY.M.D format
2. Add entry to NEWS.md with:
   - Version number
   - Bug fixes (if any)
   - New features (if any)
   - Documentation updates (if any)

Example NEWS.md entry:
```markdown
# Version 25.3.19

## New Features
* Added support for custom analysis naming conventions

## Bug Fixes
* Fixed hash caching issue with complex data structures
```

## CRAN Publishing Notes

This package is published on CRAN. Pre-submission requirements:

1. Pass `R CMD check . --as-cran` with 0 errors, 0 warnings
2. Remove platform-specific files (@eaDir/, .DS_Store)
3. Verify LICENSE year is current
4. All vignettes must be runnable (no `\dontrun{}` for examples)
5. Test across multiple platforms via R-hub if major changes
6. Update version and NEWS.md before submission

## Testing Notes

Current test coverage is limited to basic Plan initialization. When adding significant features:
- Add comprehensive tests in `tests/testthat/test_*.R`
- Test both single and parallel execution modes
- Test with both data loading methods (`fn_name` and `direct`)

## Additional Resources

- Repository: https://github.com/raubreywhite/plnr
- Documentation: https://www.rwhite.no/plnr/
- CRAN: https://cran.r-project.org/package=plnr
