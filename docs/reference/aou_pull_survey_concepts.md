# Get survey questions from AoU for a given cohort

Get survey questions from AoU for a given cohort

## Usage

``` r
aou_pull_survey_concepts(
  cohort,
  concepts,
  collect = TRUE,
  reshape = FALSE,
  ...
)
```

## Arguments

- cohort:

  tbl; reference to a table with a column called "person_id"

- concepts:

  num; a vector of concept ids for questions in the survey table

- collect:

  lgl; whether to collect from the database

- reshape:

  lgl; whether to turn the long data into wide data with clean variable
  names

## Value

if reshape = FALSE, a dataframe or remote tbl with columns person_id,
date (survey_datetime), concept_id (question_concept_id), question,
answer. If reshape = TRUE, a dataframe with questions as columns. Those
with multiple answers per person ("checkbox" questions) are
list-columns.

## Examples

``` r
if (FALSE) { # \dontrun{
survey_data <- aou_pull_survey_concepts(cohort, concepts = c(1157, 124839), reshape = TRUE)
} # }
```
