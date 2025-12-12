# icd2omop

icd2omop

## Usage

``` r
icd2omop(
  codes,
  source_wildcard = "x",
  dbms_wildcard = "%",
  translate_from = "ICD9CM",
  collect = TRUE,
  overwrite = TRUE,
  con = getOption("con.default.value"),
  cdm_schema = getOption("cdm_schema.default.value"),
  ...
)
```

## Arguments

- codes:

  vector of source codes with or without wildcards

- source_wildcard:

  wildcard indicator in source codes. for example if code is R47.x, put
  "x"

- dbms_wildcard:

  wildcard indicator for dbms LIKE function.

- translate_from:

  source vocabulary, e.g., ICD9CM or ICD10CM. Make sure to enter the
  same way it is included in the concept table

- collect:

  whether to execute the query. defaults to TRUE

- overwrite:

  whether to overwrite the temp table created in the course of the query
  (#temp). defaults to TRUE

- con:

  the connection object to the database. defaults to option
  "con.default.value"

- cdm_schema:

  the schema containing the CDM. defaults to option
  "cdm_schema.default.value"

## Value

a dataframe of the target and source codes, and the original codes with
wildcard (\`orig_code\`). If collect = FALSE, a reference to the SQL
query.
