#' Generate Table 1 for Komodo Data
#'
#' Creates a baseline characteristics table (Table 1) summarizing demographics
#' (age group, gender, race/ethnicity) for a cohort in Komodo claims data.
#'
#' @param con A database connection object (e.g., from \code{DatabaseConnector}).
#' @param cohort_table Character. Name of the cohort table. Must contain columns
#'   \code{patient_id} and \code{index_date}.
#' @param write_schema Character. Schema where the cohort table is located.
#'   Defaults to \code{"work_<db_username>"} using keyring credentials.
#' @param komodo_schema Character. Schema containing Komodo source tables.
#'   Defaults to \code{"komodo"}.
#' @param min_count Integer or NULL. If provided, filters out rows where
#'   \code{n_persons} is below this threshold (e.g., for small-cell suppression).
#'
#' @return A data frame with columns: \code{category}, \code{covariate},
#'   \code{n_persons}, and \code{percent}.
#' @export
#'
#' @examples
#' \dontrun{
#' my_table1 <- k_table1(
#'   con,
#'   cohort_table = "my_cohort",
#'   min_count = 5
#' )
#' }
k_table1 <- function(
    con,
    cohort_table,
    write_schema = paste0("work_", keyring::key_get("db_username")),
    komodo_schema = "komodo",
    min_count = NULL) {
  
  # Load cohort (requires columns: patient_id, index_date)
  cohort <- tbl(con, inDatabaseSchema(write_schema, cohort_table))
  
  # Calculate total patients
  total_patients <- cohort |>
    summarize(n = n_distinct(patient_id)) |>
    collect() |>
    pull(n)
  
  # Load demographic tables
  patient <- tbl(con, inDatabaseSchema(komodo_schema, "patient_demographics"))
  patient_race_ethnicity <- tbl(con, inDatabaseSchema(komodo_schema, "patient_race_ethnicity"))
  
  # Join and compute age groups
  demographics <- cohort |>
    inner_join(patient, by = "patient_id") |>
    inner_join(patient_race_ethnicity, by = "patient_id") |>
    select(patient_id, index_date, patient_dob, patient_gender, patient_race_ethnicity) |>
    mutate(
      age_at_entry = year(index_date) - year(patient_dob),
      age_group = case_when(
        age_at_entry <   5 ~ "0-4",
        age_at_entry <  10 ~ "5-9",
        age_at_entry <  15 ~ "10-14",
        age_at_entry <  20 ~ "15-19",
        age_at_entry <  25 ~ "20-24",
        age_at_entry <  30 ~ "25-29",
        age_at_entry <  35 ~ "30-34",
        age_at_entry <  40 ~ "35-39",
        age_at_entry <  45 ~ "40-44",
        age_at_entry <  50 ~ "45-49",
        age_at_entry <  55 ~ "50-54",
        age_at_entry <  60 ~ "55-59",
        age_at_entry <  65 ~ "60-64",
        age_at_entry <  70 ~ "65-69",
        age_at_entry <  75 ~ "70-74",
        age_at_entry <  80 ~ "75-79",
        age_at_entry <  85 ~ "80-84",
        age_at_entry <  90 ~ "85-89",
        TRUE               ~ "> 89"
      )
    )
  
  # Helper to build each summary block
  summarize_covariate <- function(data, group_var, label_prefix, category = "Demographics") {
    data |>
      group_by({{ group_var }}) |>
      summarize(n_persons = n()) |>
      collect() |>
      mutate(
        category = category,
        covariate = paste0(label_prefix, {{ group_var }}),
        percent = round(100 * n_persons / total_patients, 1)
      ) |>
      select(category, covariate, n_persons, percent) |>
      arrange(desc(n_persons))
  }
  
  result <- bind_rows(
    summarize_covariate(demographics, patient_gender,         "Gender: "),
    summarize_covariate(demographics, patient_race_ethnicity, "Race/Ethnicity: "),
    summarize_covariate(demographics, age_group,              "Age Group: ")
  )
  
  cat(sprintf("Table 1: Baseline Characteristics (N = %s)\n", format(total_patients, big.mark = ",")))
  
  if (!is.null(min_count)) {
    result <- result |> filter(n_persons >= min_count)
  }
  
  return(result)
}