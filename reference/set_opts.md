# Set plnr options

`set_opts()` sets options for the whole package.

## Usage

``` r
set_opts(force_verbose = FALSE)
```

## Arguments

- force_verbose:

  Logical. `TRUE` makes every
  [Plan](https://www.rwhite.no/plnr/reference/Plan.md) that you create
  afterwards verbose, even in a non-interactive session. The default is
  `FALSE`.

## Value

`force_verbose`, invisibly.

## See also

[`vignette("plnr")`](https://www.rwhite.no/plnr/articles/plnr.md) for
the concepts.

Other plan helpers:
[`Plan`](https://www.rwhite.no/plnr/reference/Plan.md),
[`expand_list()`](https://www.rwhite.no/plnr/reference/expand_list.md),
[`get_anything()`](https://www.rwhite.no/plnr/reference/get_anything.md),
[`is_run_directly()`](https://www.rwhite.no/plnr/reference/is_run_directly.md)

## Examples

``` r
set_opts(force_verbose = TRUE)
set_opts(force_verbose = FALSE)
```
