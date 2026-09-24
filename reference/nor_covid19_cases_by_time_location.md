# Covid-19 cases confirmed by PCR in Norway, by nation and county

The data come from the Norwegian Surveillance System for Communicable
Diseases (MSIS). `date` is the date of the PCR test. The data were
extracted on 2022-05-04.

## Usage

``` r
nor_covid19_cases_by_time_location
```

## Format

A data.table with 11028 rows and 18 variables:

- granularity_time:

  `"day"` or `"isoweek"`.

- granularity_geo:

  `"nation"` or `"county"`.

- country_iso3:

  `"nor"`.

- location_code:

  `"nation_nor"`, or one of 11 county codes such as `"county_nor03"`.

- border:

  The year of the county borders, 2020.

- age:

  `"total"`.

- sex:

  `"total"`.

- isoyear:

  ISO year.

- isoweek:

  ISO week.

- isoyearweek:

  ISO year and week, such as `"2020-08"`.

- season:

  Season, such as `"2020/2021"`.

- seasonweek:

  Week within the season.

- calyear:

  Calendar year. `NA` in weekly rows.

- calmonth:

  Calendar month. `NA` in weekly rows.

- calyearmonth:

  Calendar year and month, such as `"2020-M02"`. `NA` in weekly rows.

- date:

  The date. In weekly rows, the Sunday that ends the ISO week.

- covid19_cases_testdate_n:

  Number of confirmed cases.

- covid19_cases_testdate_pr100000:

  Number of confirmed cases per 100 000 population.

## Source

<https://github.com/folkehelseinstituttet/surveillance_data/blob/master/covid19/_DOCUMENTATION_data_covid19_msis_by_time_location.txt>
