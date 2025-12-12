# icd2omop2

this function will only find exact ICD matches. It is faster than
icd2omop() because it does not need to use a join to find wildcards. It
also does not return a match with the beginning icd codes however. It is
important to check that all codes searched have found a match

## Usage

``` r
icd2omop2(
  db_con,
  codes,
  cdm_schema = NULL,
  icd_wildcard = "x",
  dbms_wildcard = "%",
  translate_from = "ICD9CM",
  translate_to = "SNOMED"
)
```

## Arguments

- db_con:

  database connection object

- codes:

  vector of ICD codes with or without wildcards

- cdm_schema:

  name of CDM schema

- icd_wildcard:

  wordcard indicator in icd codes. for example if code is R47.x, put "x"

- dbms_wildcard:

  wildcard indicator for dbms SIMILAR TO function.

- translate_from:

  ICD codes to start

- translate_to:

  codes to transfer to to get to omop. usually SNOMED

## Value

a dataframe of icd, SNOMED, and OMOP concept codes
