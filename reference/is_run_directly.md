# Check whether code runs at the top level of the console

`is_run_directly()` returns `TRUE` when you call it at the top level of
the R console or of an Rscript file. It returns `FALSE` inside a
function, and inside [`source()`](https://rdrr.io/r/base/source.html),
[`eval()`](https://rdrr.io/r/base/eval.html) and a knitr chunk.

## Usage

``` r
is_run_directly()
```

## Value

`TRUE` or `FALSE`.

## Details

Put it at the start of an action function to load `data` and `argset`
while you develop the function line by line. When the plan runs the
function, it returns `FALSE`, so the lines do nothing.

## See also

[`vignette("plnr")`](https://www.rwhite.no/plnr/articles/plnr.md), whose
"Debugging" section shows the pattern.

Other plan helpers:
[`Plan`](https://www.rwhite.no/plnr/reference/Plan.md),
[`expand_list()`](https://www.rwhite.no/plnr/reference/expand_list.md),
[`get_anything()`](https://www.rwhite.no/plnr/reference/get_anything.md),
[`set_opts()`](https://www.rwhite.no/plnr/reference/set_opts.md)

## Examples

``` r
f <- function() {
  is_run_directly()
}
f()
#> [1] FALSE
```
