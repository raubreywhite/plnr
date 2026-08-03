# Set package configuration options

This function allows users to configure package-wide options, such as
verbosity of output messages. It modifies the package's internal
configuration state.

## Usage

``` r
set_opts(force_verbose = FALSE)
```

## Arguments

- force_verbose:

  Logical, whether to force verbose output messages regardless of the
  interactive state. Defaults to `FALSE`

## Value

NULL, modifies the package's internal configuration

## See also

[Plan](https://www.rwhite.no/plnr/reference/Plan.md), whose `verbose`
argument is on by default when either the session is interactive or
`force_verbose` is `TRUE`, and
[`vignette("plnr")`](https://www.rwhite.no/plnr/articles/plnr.md) for an
introduction to the framework.

## Examples

``` r
# Enable verbose output
set_opts(force_verbose = TRUE)

# Disable verbose output
set_opts(force_verbose = FALSE)
```
