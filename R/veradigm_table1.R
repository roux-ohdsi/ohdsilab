#' Generate Table 1 for Veradigm Data
#'
#' Creates a baseline characteristics table (Table 1) from a cohort in Veradigm data
#'
#' @param con Database connection object
#' @param cohort_table Name of the cohort table
#' @param write_schema Schema where the cohort table is located
#' @param veradigm_schema Schema containing Veradigm tables
#' @param min_count Minimum count threshold for filtering results (optional)
#' @return A data frame with baseline characteristics
#' @export
#' @examples
#' \dontrun{
#' my_table1 <- veradigm_table1(con, "cohort", min_count = 5)
#' }
veradigm_table1 <- function(
    con,
    cohort_table,
    write_schema = paste0(
      "work_",
      keyring::key_get("db_username")),
    veradigm_schema = "veradigm",
    min_count = NULL) {

  #from here down within the function (excluding the if and return statements) can be run to generate table 1 manually
  cohort <- dplyr::tbl(
    con,
    inDatabaseSchema(write_schema, cohort_table))

  patient <- dplyr::tbl(
    con,
    inDatabaseSchema(veradigm_schema, "Patient"))

  demographics <- cohort |>
    inner_join(patient, by = "hi_patient_id") |>
    select(
      hi_patient_id,
      cohort_start_date,
      birth_year,
      gender,
      race,
      ethnicity) |>
    mutate(
      age_at_entry = year(cohort_start_date) - year(birth_year),
      age_group = case_when(
        age_at_entry < 5 ~ "0-4",
        age_at_entry >= 5 & age_at_entry < 10 ~ "5-9",
        age_at_entry >= 10 & age_at_entry < 15 ~ "10-14",
        age_at_entry >= 15 & age_at_entry < 20 ~ "15-19",
        age_at_entry >= 20 & age_at_entry < 25 ~ "20-24",
        age_at_entry >= 25 & age_at_entry < 30 ~ "25-29",
        age_at_entry >= 30 & age_at_entry < 35 ~ "30-34",
        age_at_entry >= 35 & age_at_entry < 40 ~ "35-39",
        age_at_entry >= 40 & age_at_entry < 45 ~ "40-44",
        age_at_entry >= 45 & age_at_entry < 50 ~ "45-49",
        age_at_entry >= 50 & age_at_entry < 55 ~ "50-54",
        age_at_entry >= 55 & age_at_entry < 60 ~ "55-59",
        age_at_entry >= 60 & age_at_entry < 65 ~ "60-64",
        age_at_entry >= 65 & age_at_entry < 70 ~ "65-69",
        age_at_entry >= 70 & age_at_entry < 75 ~ "70-74",
        age_at_entry >= 75 & age_at_entry < 80 ~ "75-79",
        age_at_entry >= 80 & age_at_entry < 85 ~ "80-84",
        age_at_entry >= 85 & age_at_entry < 90 ~ "85-89",
        age_at_entry >= 90 ~ "> 89"))

  problem <- dplyr::tbl(
    con,
    inDatabaseSchema(veradigm_schema, "Problem"))

  problem_code <- dplyr::tbl(
    con,
    inDatabaseSchema(veradigm_schema, "Problem_Code")
  )

  medication <- dplyr::tbl(
    con,
    inDatabaseSchema(veradigm_schema, "Medication"))

  procedure <- dplyr::tbl(
    con,
    inDatabaseSchema(veradigm_schema, "Procedure"))

  observation <- dplyr::tbl(
    con,
    inDatabaseSchema(veradigm_schema, "Observations"))

  total_patients <- cohort |>
    summarise(n = n_distinct(hi_patient_id)) |>
    collect() |>
    pull(n)

  gender_summary <- demographics |>
    group_by(gender) |>
    summarise(n_persons = n()) |>
    collect() |>
    mutate(
      category = "Demographics",
      covariate = paste0("Gender: ", gender),
      percent = round(100 * n_persons / total_patients, 1)) |>
    select(category, covariate, n_persons, percent) |>
    arrange(desc(n_persons))

  race_summary <- demographics |>
    group_by(race) |>
    summarise(n_persons = n()) |>
    collect() |>
    mutate(
      category = "Demographics",
      covariate = paste0("Race: ", race),
      percent = round(100 * n_persons / total_patients, 1)) |>
    select(category, covariate, n_persons, percent) |>
    arrange(desc(n_persons))

  ethnicity_summary <- demographics |>
    group_by(ethnicity) |>
    summarise(n_persons = n()) |>
    collect() |>
    mutate(
      category = "Demographics",
      covariate = paste0("Ethnicity: ", ethnicity),
      percent = round(100 * n_persons / total_patients, 1)) |>
    select(category, covariate, n_persons, percent) |>
    arrange(desc(n_persons))

  age_summary <- demographics |>
    group_by(age_group) |>
    summarise(n_persons = n()) |>
    collect() |>
    mutate(
      category = "Demographics",
      covariate = paste0("Age Group: ", age_group),
      percent = round(100 * n_persons / total_patients, 1)) |>
    select(category, covariate, n_persons, percent) |>
    arrange(desc(n_persons))

  problem_summary <- cohort |>
    inner_join(problem, by = "hi_patient_id") |>
    inner_join(problem_code, by = "problem_id") |>
    group_by(code, problem_name) |>
    summarise(n_persons = n_distinct(hi_patient_id), .groups = "drop") |>
    collect() |>
    mutate(
      category = "Problems",
      covariate = problem_name,
      percent = round(100 * n_persons / total_patients, 1)) |>
    select(category, covariate, n_persons, percent) |>
    arrange(desc(n_persons))

  if (!is.null(min_count)) {
    problem_summary <- problem_summary |>
      filter(n_persons >= min_count)
  }

  medication_summary <- cohort |>
    inner_join(medication, by = "hi_patient_id") |>
    group_by(medication_name) |>
    summarise(n_persons = n_distinct(hi_patient_id), .groups = "drop") |>
    collect() |>
    mutate(
      category = "Medication",
      covariate = medication_name,
      percent = round(100 * n_persons / total_patients, 1)) |>
    select(category, covariate, n_persons, percent) |>
    arrange(desc(n_persons))

  if (!is.null(min_count)) {
    medication_summary <- medication_summary |>
      filter(n_persons >= min_count)
  }

  procedure_summary <- cohort |>
    inner_join(procedure, by = "hi_patient_id") |>
    group_by(procedure_name) |>
    summarise(n_persons = n_distinct(hi_patient_id), .groups = "drop") |>
    collect() |>
    mutate(
      category = "Procedure",
      covariate = procedure_name,
      percent = round(100 * n_persons / total_patients, 1)) |>
    select(category, covariate, n_persons, percent) |>
    arrange(desc(n_persons))

  if (!is.null(min_count)) {
    procedure_summary <- procedure_summary |>
      filter(n_persons >= min_count)
  }

  observation_summary <- cohort |>
    inner_join(observation, by = "hi_patient_id") |>
    group_by(observation_name) |>
    summarise(n_persons = n_distinct(hi_patient_id), .groups = "drop") |>
    collect() |>
    mutate(
      category = "Observation",
      covariate = observation_name,
      percent = round(100 * n_persons / total_patients, 1)) |>
    select(category, covariate, n_persons, percent) |>
    arrange(desc(n_persons))

  if (!is.null(min_count)) {
    observation_summary <- observation_summary |>
      filter(n_persons >= min_count)
  }

  result <- bind_rows(
    gender_summary,
    race_summary,
    ethnicity_summary,
    age_summary,
    problem_summary,
    medication_summary,
    procedure_summary,
    observation_summary)

  cat(
    sprintf(
      "Table1: Baseline Characteristics (N= %g)\n",
      total_patients))

  return(result)
}
