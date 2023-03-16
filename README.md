
# ohdsilab

<!-- badges: start -->
<!-- badges: end -->

R package with useful functions for Roux OHDSI center ohdsi-lab database

## Installation

You can install the development version of ohdsilab from [GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("roux-ohdsi/ohdsilab")
```

## Functions

- connecting to the ohdsilab CDM (lab.R/lab_project.R)
- mapping icd codes to OMOP concepts
  - `icd2omop()` for wildcard matching
  - `icd2omop2()` for exact matching (a bit faster)
- adding periods to medicare ICD codes (str_insert.R)


## Other

- There is a snippets text file to give quick access to common code chunks
for connecting to the ohdsilab cdm. See snippets/snippets.txt for instructions and
the snippets. 
