# Case study, part 1: a contract for each registry

Each registry delivers its data in its own format. This article defines
one data contract. It then gives each registry an R package that
converts the raw data to a table that follows the contract. The methods
and the pipeline read only such tables.

[The overview](https://www.rwhite.no/plnr/articles/case-study.md)
explains the three layers. This article covers the first layer.

## Three registries with three raw formats

The case study uses three synthetic registries. They cover the ISO weeks
from 2018-35 to 2024-03. That is five complete winter seasons and the
start of a sixth.

- **General practice** sends one file a week, with one row for each
  district and week. It has no reporting date: a week is complete when
  it arrives.
- **Hospitals** send one row for each admission, with its reporting
  date. Some admissions of the most recent weeks are not reported yet.
- **The laboratory** sends one row for each test, with the results for
  influenza and RSV and the reporting date of the result. It is national
  only.

``` r
library(data.table)

calendar <- cstime::dates_by_isoyearweek[, .(
  isoyearweek,
  isoweek = cstime::isoyearweek_to_isoweek_n(isoyearweek),
  monday = as.Date(mon)
)]
calendar <- calendar[isoyearweek >= "2018-35" & isoyearweek <= "2024-03"]
today <- max(calendar$monday) + 6L
districts <- c("district_a", "district_b", "district_c")
season <- function(isoweek, peak) cos(2 * pi * (isoweek - peak) / 52)

set.seed(4)

# General practice: one file a week, one row for each district and week, one
# column for each diagnosis group.
raw_gp <- CJ(district = districts, isoyearweek = calendar$isoyearweek)
raw_gp[calendar, on = "isoyearweek", isoweek := i.isoweek]
raw_gp[, all_n := rpois(.N, 2000)]
raw_gp[, ili_n := rbinom(.N, all_n, plogis(-4 + 1.2 * season(isoweek, 5)))]
raw_gp[, isoweek := NULL]

# Hospitals: one row for each admission, with the date it reached the registry.
raw_hosp <- calendar[,
  .(
    admission_date = monday +
      sample(0:6, rpois(1, 20 * exp(1.1 * season(isoweek, 6))), TRUE)
  ),
  by = .(isoyearweek, isoweek)
]
raw_hosp[, district := sample(districts, .N, TRUE)]
raw_hosp[,
  diagnosis := sample(c("SARI", "other"), .N, TRUE, prob = c(0.8, 0.2))
]
raw_hosp[, registered_date := admission_date + rgeom(.N, 0.25)]
raw_hosp <- raw_hosp[
  registered_date <= today,
  .(admission_date, registered_date, district, diagnosis)
]

# The laboratory: one row for each test, with the results for two pathogens and
# the date the result was reported. National only.
raw_lab <- calendar[,
  .(
    sample_date = monday +
      sample(0:6, rpois(1, 400 + 120 * season(isoweek, 3)), TRUE)
  ),
  by = .(isoyearweek, isoweek)
]
raw_lab[, influenza := rbinom(.N, 1, plogis(-2.6 + 1.6 * season(isoweek, 5)))]
raw_lab[, rsv := rbinom(.N, 1, plogis(-3.0 + 1.4 * season(isoweek, 50)))]
raw_lab[,
  reported_date := sample_date + sample(0:20, .N, TRUE, prob = 0.8^(0:20))
]
raw_lab <- raw_lab[
  reported_date <= today,
  .(sample_date, reported_date, influenza, rsv)
]
```

``` r
head(raw_gp, 3)
#> Key: <district, isoyearweek>
#>      district isoyearweek all_n ili_n
#>        <char>      <char> <int> <int>
#> 1: district_a     2018-35  2009    15
#> 2: district_a     2018-36  1975    14
#> 3: district_a     2018-37  1971     7
head(raw_hosp, 3)
#>    admission_date registered_date   district diagnosis
#>            <Date>          <Date>     <char>    <char>
#> 1:     2018-09-01      2018-09-02 district_b      SARI
#> 2:     2018-09-02      2018-09-07 district_b      SARI
#> 3:     2018-09-01      2018-09-02 district_b     other
head(raw_lab, 3)
#>    sample_date reported_date influenza   rsv
#>         <Date>        <Date>     <int> <int>
#> 1:  2018-08-28    2018-09-03         0     0
#> 2:  2018-09-01    2018-09-12         0     0
#> 3:  2018-08-31    2018-08-31         0     0
```

## The contract

A registry package MUST return a `data.table` that follows these 9
rules. The table below lists the columns. Rule 1 requires them, and
rules 2 to 9 constrain their values.

| Column | Meaning |
|----|----|
| `indicator_tag` | The indicator, prefixed with the registry, for example `hosp_sari`. |
| `location_code` | The location, for example `national` or `district_a`. |
| `age`, `sex` | The stratum. `total` where the registry does not split by it. |
| `isoyearweek_reference` | The ISO week the count belongs to, for example `2024-03`. |
| `reporting_date` | The reporting date: the date the count reached the registry. |
| `numerator` | The count. |
| `denominator` | The count that the numerator is a share of, for example all tests. `NA` where none exists. |

1.  The table MUST have the 8 columns above. It MAY have more, and the
    methods ignore them.
2.  The key columns `indicator_tag`, `location_code`, `age`, `sex` and
    `isoyearweek_reference` MUST be character. `reporting_date` MUST be
    a `Date`.
3.  The key columns, `reporting_date` and `numerator` MUST NOT be
    missing.
4.  `isoyearweek_reference` MUST be an ISO week of the form `YYYY-WW`,
    for example `2024-03`.
5.  Two rows MUST NOT share all of `indicator_tag`, `location_code`,
    `age`, `sex`, `isoyearweek_reference` and `reporting_date`.
6.  `reporting_date` MUST NOT be before the Monday of the reference
    week. A registry without reporting dates MUST use that Monday, so
    each count has a reporting delay of 0 days.
7.  `numerator` and `denominator` MUST be finite and non-negative, and
    `numerator` MUST be a whole number.
8.  Where `denominator` exists, `numerator` MUST NOT be above it.
9.  The table MUST have rows with `location_code` equal to `national`.

Each row is one cell of a reporting triangle: the count of one reference
week that arrived on one reporting date. The sum over the reporting
dates is the count of the reference week as known today. The methods
need the reporting dates to nowcast the most recent weeks, as [part
2](https://www.rwhite.no/plnr/articles/case-study-methods.md) shows. A
nowcast estimates the final count of a week from the counts reported so
far.

Under rule 6, the counts of a registry without reporting dates are
complete on arrival. The methods do not nowcast them.

## One function for each registry package

Each function below is the exported `get_data()` of one registry
package. In production it reads the raw data from the registry. Here it
takes the raw data as an argument, so the article runs without a
database.

``` r
monday_of <- function(isoyearweek) {
  weeks <- cstime::dates_by_isoyearweek
  as.Date(weeks$mon[match(isoyearweek, weeks$isoyearweek)])
}
week_of <- function(date) cstime::date_to_isoyearweek_c(date)
add_national <- function(d) {
  national <- d[,
    .(
      location_code = "national",
      numerator = sum(numerator),
      denominator = sum(denominator)
    ),
    keyby = .(indicator_tag, age, sex, isoyearweek_reference, reporting_date)
  ]
  rbindlist(list(d, national), use.names = TRUE)
}

get_data_gp <- function(raw = raw_gp) {
  # no reporting date: each week is complete when it arrives, so it counts as
  # reported on the Monday of its reference week (rule 6)
  d <- raw[, .(
    indicator_tag = "gp_ili",
    location_code = district,
    age = "total",
    sex = "total",
    isoyearweek_reference = isoyearweek,
    reporting_date = monday_of(isoyearweek),
    numerator = ili_n,
    denominator = all_n
  )]
  add_national(d)
}

get_data_hosp <- function(raw = raw_hosp) {
  d <- raw[
    diagnosis == "SARI",
    .(numerator = .N),
    keyby = .(
      location_code = district,
      isoyearweek_reference = week_of(admission_date),
      reporting_date = registered_date
    )
  ]
  d[, `:=`(
    indicator_tag = "hosp_sari",
    age = "total",
    sex = "total",
    denominator = NA_integer_
  )]
  add_national(d)
}

get_data_lab <- function(raw = raw_lab) {
  d <- melt(
    raw,
    id.vars = c("sample_date", "reported_date"),
    variable.name = "pathogen",
    value.name = "positive"
  )
  d <- d[,
    .(numerator = sum(positive), denominator = .N),
    keyby = .(
      indicator_tag = paste0("lab_", pathogen),
      isoyearweek_reference = week_of(sample_date),
      reporting_date = reported_date
    )
  ]
  d[, `:=`(location_code = "national", age = "total", sex = "total")]
  setcolorder(d, contract_cols)
}
```

The three functions differ because the raw formats differ. All three
return a table that follows the contract.

## The pipeline checks the contract on every load

A registry package can have a bug, and a raw format can change without
notice. The pipeline therefore checks the output of each registry
package when it loads it. The check is in one shared package. Every
registry package also calls it in its own tests.

``` r
contract_cols <- c(
  "indicator_tag",
  "location_code",
  "age",
  "sex",
  "isoyearweek_reference",
  "reporting_date",
  "numerator",
  "denominator"
)
contract_key <- setdiff(contract_cols, c("numerator", "denominator"))

check_contract <- function(d, registry) {
  if (!is.data.table(d)) {
    stop("registry ", registry, " breaks rule 1: not a data.table", call. = FALSE)
  }
  missing <- setdiff(contract_cols, names(d))
  if (length(missing) > 0) {
    stop(
      "registry ",
      registry,
      " breaks rule 1: no column ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }
  broken <- c(
    "2: a key column is not character" = !all(sapply(
      d[, setdiff(contract_key, "reporting_date"), with = FALSE],
      is.character
    )),
    "2: reporting_date is not a Date" = !inherits(d$reporting_date, "Date"),
    "3: a key value or a numerator is missing" = anyNA(d[,
      c(contract_key, "numerator"),
      with = FALSE
    ]),
    "4: isoyearweek_reference is not an ISO week YYYY-WW" = anyNA(monday_of(
      d$isoyearweek_reference
    )),
    "5: two rows share a key" = anyDuplicated(d, by = contract_key) > 0,
    "6: a count is reported before its reference week" = any(
      d$reporting_date < monday_of(d$isoyearweek_reference),
      na.rm = TRUE
    ),
    "7: a count is negative, infinite or not whole" = any(
      d$numerator < 0 | is.infinite(d$numerator) | d$numerator %% 1 != 0,
      d$denominator < 0 | is.infinite(d$denominator),
      na.rm = TRUE
    ),
    "8: a numerator is above its denominator" = any(
      d$numerator > d$denominator,
      na.rm = TRUE
    ),
    "9: no location_code national" = !"national" %in% d$location_code
  )
  if (any(broken)) {
    stop(
      "registry ",
      registry,
      " breaks rule ",
      paste(names(broken)[broken], collapse = "; rule "),
      call. = FALSE
    )
  }
  invisible(d)
}
```

`check_contract()` returns the data unchanged when the data meets the
contract:

``` r
d_gp <- check_contract(get_data_gp(), "gp")
d_hosp <- check_contract(get_data_hosp(), "hosp")
d_lab <- check_contract(get_data_lab(), "lab")
rbindlist(lapply(list(gp = d_gp, hosp = d_hosp, lab = d_lab), function(d) {
  data.table(rows = nrow(d), indicators = uniqueN(d$indicator_tag), locations = uniqueN(d$location_code))
}), idcol = "registry")
#>    registry  rows indicators locations
#>      <char> <int>      <int>     <int>
#> 1:       gp  1128          1         4
#> 2:     hosp  6780          1         4
#> 3:      lab 13140          2         1
```

It stops when the data breaks a rule, and the error names the registry
and every rule that it breaks. Here the hospital registry starts to send
its location as a factor. One admission also has a reporting date before
the Monday of its reference week:

``` r
broken <- get_data_hosp()
broken[, location_code := factor(location_code)]
broken[1, reporting_date := reporting_date - 30L]
check_contract(broken, "hosp")
#> Error:
#> ! registry hosp breaks rule 2: a key column is not character; rule 6: a count is reported before its reference week
```

## What a registry package holds

A registry package holds three things:

- `get_data()`, which reads the raw data and returns a table that
  follows the contract.
- A function that makes fake raw data in the format of the registry,
  such as the code that makes `raw_hosp` in this article.
- A test that runs `get_data()` on the fake data and passes the result
  to `check_contract()`.

The fake data lets the registry team and the methods team test their
code without access to the real data. The registry team owns the package
and changes it when the raw format changes.

[Part 2](https://www.rwhite.no/plnr/articles/case-study-methods.md) runs
the surveillance methods on one indicator. [Part
3](https://www.rwhite.no/plnr/articles/case-study-pipeline.md) runs them
on every indicator of every registry.
