# Set package configuration options

`set_opts()` sets package-wide options, such as the verbosity of output
messages. It changes the internal configuration state of the package.

## Usage

``` r
set_opts(force_verbose = FALSE)
```

## Arguments

- force_verbose:

  Logical. Whether to force verbose output messages, whatever the
  interactive state is. The default is `FALSE`.

## Value

NULL. `set_opts()` changes the internal configuration of the package.

## See also

[Plan](https://www.rwhite.no/plnr/reference/Plan.md). Its `verbose`
argument is on by default when the session is interactive, or when
`force_verbose` is `TRUE`. See
[`vignette("plnr")`](https://www.rwhite.no/plnr/articles/plnr.md) for an
introduction to the framework.

## Examples

``` r
# Enable verbose output
set_opts(force_verbose = TRUE)

# Disable verbose output
set_opts(force_verbose = FALSE)
```
