# Generate Table 1 for Veradigm Data

Creates a baseline characteristics table (Table 1) from a cohort in
Veradigm data

## Usage

``` r
veradigm_table1(
  con,
  cohort_table,
  write_schema = paste0("work_", keyring::key_get("db_username")),
  veradigm_schema = "veradigm",
  min_count = NULL
)
```

## Arguments

- con:

  Database connection object

- cohort_table:

  Name of the cohort table

- write_schema:

  Schema where the cohort table is located

- veradigm_schema:

  Schema containing Veradigm tables

- min_count:

  Minimum count threshold for filtering results (optional)

## Value

A data frame with baseline characteristics

## Examples

``` r
if (FALSE) { # \dontrun{
my_table1 <- veradigm_table1(con, "cohort", min_count = 5)
} # }
```
