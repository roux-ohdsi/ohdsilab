# Add periods to icd numbers

Useful for when icd9 numbers come without periods

## Usage

``` r
icd_periods(data, icd_column, overwrite = TRUE)
```

## Arguments

- data:

  dataframe or tibble

- icd_column:

  name of column to fix

- overwrite:

  whether to overwrite supplied column of add a new one

## Value

the same dataframe overwriting the column with icd9
