# Collect using the DBI package

Collect using the DBI package

## Usage

``` r
dbi_collect(query, connection = getOption("con.default.value"))
```

## Arguments

- query:

  the sql query built from dbplyr

- connection:

  connection to the db. can leave blank if set using options

## Value

collected dataframe
