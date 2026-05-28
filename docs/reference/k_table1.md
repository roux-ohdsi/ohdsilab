# Generate Table 1 for Komodo Data

Creates a baseline characteristics table (Table 1) summarizing
demographics (age group, gender, race/ethnicity) for a cohort in Komodo
claims data.

## Usage

``` r
k_table1(
  con,
  cohort_table,
  write_schema = paste0("work_", keyring::key_get("db_username")),
  komodo_schema = "komodo",
  min_count = NULL
)
```

## Arguments

- con:

  A database connection object (e.g., from `DatabaseConnector`).

- cohort_table:

  Character. Name of the cohort table. Must contain columns `patient_id`
  and `index_date`.

- write_schema:

  Character. Schema where the cohort table is located. Defaults to
  `"work_<db_username>"` using keyring credentials.

- komodo_schema:

  Character. Schema containing Komodo source tables. Defaults to
  `"komodo"`.

- min_count:

  Integer or NULL. If provided, filters out rows where `n_persons` is
  below this threshold (e.g., for small-cell suppression).

## Value

A data frame with columns: `category`, `covariate`, `n_persons`, and
`percent`.

## Examples

``` r
if (FALSE) { # \dontrun{
my_table1 <- k_table1(
  con,
  cohort_table = "my_cohort",
  min_count = 5
)
} # }
```
