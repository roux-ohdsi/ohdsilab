#' Get occurrences of of a concept set from ATLAS for a given cohort
#'
#'
#' @param cohort tbl; reference to a table created in a user schema with a column called "person_id", and columns for start_date and end_date
#' @param concept_set_id num; the number associated with the concept_set_id in ATLAS
#' @param concept_set_name chr; Name to describe the concept set, used to create an indicator variable
#' @param start_date the name of the start_date column in the cohort table (unquoted)
#' @param end_date the name of the end_date column in the cohort table (unquoted)
#' @param min_n dbl; the minimum number of occurrences per person to consider the indicator true
#' @param n dbl; count the number of occurrences per person (will not include zeros)
#' @param keep_all lgl; keep columns with information about the concept (e.g., concept name, id, etc.)
#' @param con the connection object to ohdsilab
#' @param atlas_url chr; the base url for ATLAS (not ohdsilab)
#' @param write_schema chr; schema for the user
#'
#' @return a dataframe
#' @export
#'
#' @examples
#' \dontrun{
#' tobacco <- pull_concepts(cohort, concept_set_id = 1157, start_date = covariate_start_date,
#'  end_date = cohort_start_date, name = "tobacco"
#'  )}
#'
pull_concept_set <- function(cohort,
                             concept_set_id,
                             start_date,
                             end_date,
                             concept_set_name = NULL,
                             min_n = NULL,
                             n = FALSE,
                             keep_all = FALSE,
                             con = getOption("con.default.value"),
                             atlas_url = getOption("atlas_url.default.value"),
                             write_schema = getOption("write_schema.default.value"), ...){

  if (is.null(concept_set_name)) concept_set_name <- paste0("concept_set_", concept_set_id)
  if (!is.null(min_n) & !is.numeric(min_n)) stop("Provide a number to `min_n` to restrict to observations with at least that number of rows")
  if (n && keep_all) warning("The `keep_all` argument takes precedence; all data will be returned instead of counts.")

  if (is.null(con)) stop("Provide `con` as an argument or default with `options(con.default.value = ...)`")
  if (is.null(atlas_url)) stop("Provide `atlas_url` as an argument or default with `options(atlas_url.default.value = ...)`")
  if (is.null(write_schema)) stop("Provide `write_schema` as an argument or default with `options(write_schema.default.value = ...)`")

  # consider abstracting into own function
  concept_table_local <- getConceptSetDefinition(concept_set_id, baseUrl = atlas_url) |>
    convertConceptSetDefinitionToTable() |>
    select(conceptId, conceptName, domainId) |>
    filter(domainId %in% c("Condition", "Drug", "Measurement", "Observation", "Procedure"))

  # insertTable_chunk()

  if (nrow(concept_table_local) > 100) {
    insertTable_chunk(concept_table_local, n = 100, table_name = "temp_covs",
                      con = con, write_schema = write_schema)
  } else {
    DatabaseConnector::insertTable(connection = con, databaseSchema = write_schema, tableName = "temp_covs",
                                   data = concept_table_local, dropTableIfExists = TRUE, tempTable = FALSE, createTable = TRUE)
  }

  all_concepts <- map(
    unique(concept_table_local$domainId),
    ~ get_concepts(cohort,
                   {{ start_date }}, {{ end_date }},
                   write_schema = write_schema,
                   domain = tolower(.x))
  ) |>
    reduce(union_all) |>
    mutate(concept_set = concept_set_name) |>
    distinct()

  if (!is.null(min_n)) {
    all_concepts <- all_concepts |>
      group_by(person_id) |>
      filter(n() >= min_n) |>
      ungroup()
  }

  if (keep_all) {
    return(dbi_collect(all_concepts))
  }

  if (n) {
    return(dbi_collect(count(all_concepts, concept_set, person_id)))
  }

  all_concepts |>
    distinct(person_id) |>
    mutate(!!concept_set_name := 1) |>
    dbi_collect()
  # must collect within function since next time it runs it will write over the temp_covs table...
}


get_condition_concepts <- function(cohort, start_date, end_date, write_schema, ...) {
  cohort |>
    omop_join("condition_occurrence", type = "left", by = "person_id") |>
    select(-c(
      condition_start_datetime, condition_end_date, condition_end_datetime,
      condition_type_concept_id, stop_reason, provider_id, visit_occurrence_id,
      visit_detail_id, condition_source_value, condition_source_concept_id,
      condition_status_source_value, condition_status_concept_id
    )) |>
    omop_join(table = "temp_covs", type = "inner", schema = write_schema,
              by = join_by(condition_concept_id == conceptid)
    ) |>
    filter(between(condition_start_date, {{ start_date }}, {{ end_date }})) |>
    select(person_id,
           date = condition_start_date, concept_id = condition_concept_id,
           concept_name = conceptname, domain = domainid
    )
}

get_measurement_concepts <- function(cohort, start_date, end_date, write_schema, ...) {
  cohort |>
    omop_join("measurement", type = "left", by = "person_id") |>
    select(-c(
      measurement_datetime, measurement_time, measurement_type_concept_id, operator_concept_id,
      value_as_number, value_as_concept_id, unit_concept_id, range_low, range_high,
      provider_id, visit_occurrence_id, visit_detail_id, measurement_source_value,
      measurement_source_concept_id, unit_source_value, value_source_value
    )) |>
    omop_join(table = "temp_covs", type = "inner", schema = write_schema,
              by = join_by(measurement_concept_id == conceptid)
    ) |>
    filter(between(measurement_date, {{ start_date }}, {{ end_date }})) |>
    select(person_id,
           date = measurement_date, concept_id = measurement_concept_id,
           concept_name = conceptname, domain = domainid
    )
}

get_procedure_concepts <- function(cohort, start_date, end_date, write_schema, ...) {
  cohort |>
    omop_join("procedure_occurrence", type = "left", by = "person_id") |>
    select(-c(
      procedure_datetime, procedure_type_concept_id, modifier_concept_id,
      quantity, provider_id, visit_occurrence_id, visit_detail_id,
      procedure_source_value, procedure_source_concept_id, modifier_source_value
    )) |>
    omop_join(table = "temp_covs", type = "inner", schema = write_schema,
              by = join_by(procedure_concept_id == conceptid)
    ) |>
    filter(between(procedure_date, {{ start_date }}, {{ end_date }})) |>
    select(person_id,
           date = procedure_date, concept_id = procedure_concept_id,
           concept_name = conceptname, domain = domainid
    )
}

get_observation_concepts <- function(cohort, start_date, end_date, write_schema, ...) {
  cohort |>
    omop_join("observation", type = "left", by = "person_id") |>
    select(-c(
      observation_datetime, observation_type_concept_id, value_as_number,
      value_as_string, value_as_concept_id, qualifier_concept_id,
      unit_concept_id, provider_id, visit_occurrence_id, visit_detail_id,
      observation_source_value, observation_source_concept_id,
      unit_source_value, qualifier_source_value
    )) |>
    omop_join(table = "temp_covs", type = "inner", schema = write_schema,
              by = join_by(observation_concept_id == conceptid)
    ) |>
    filter(between(observation_date, {{ start_date }}, {{ end_date }})) |>
    select(person_id,
           date = observation_date, concept_id = observation_concept_id,
           concept_name = conceptname, domain = domainid
    )
}

get_drug_concepts <- function(cohort, start_date, end_date, write_schema, ...) {
  cohort |>
    omop_join("drug_exposure", type = "left", by = "person_id") |>
    select(-c(
      drug_exposure_start_datetime, drug_exposure_end_date,
      drug_exposure_end_datetime, verbatim_end_date, drug_type_concept_id,
      stop_reason, refills, quantity, days_supply, sig, route_concept_id,
      lot_number, provider_id, visit_occurrence_id, visit_detail_id,
      drug_source_value, drug_source_concept_id, route_source_value,
      dose_unit_source_value
    )) |>
    omop_join(table = "temp_covs", type = "inner", schema = write_schema,
              by = join_by(drug_concept_id == conceptid)
    ) |>
    filter(between(drug_exposure_start_date, {{ start_date }}, {{ end_date }})) |>
    select(person_id,
           date = drug_exposure_start_date, concept_id = drug_concept_id,
           concept_name = conceptname, domain = domainid
    )
}

get_device_concepts <- function(cohort, start_date, end_date, write_schema, ...) {
  cohort |>
    omop_join("device_exposure", type = "left", by = "person_id") |>
    select(-c(
      device_exposure_start_datetime, device_exposure_end_date,
      device_exposure_end_datetime, device_type_concept_id,
      unique_device_id, quantity, provider_id, visit_occurrence_id,
      visit_detail_id, device_source_value, device_source_concept_id
    )) |>
    omop_join(table = "temp_covs", type = "inner", schema = write_schema,
              by = join_by(device_concept_id == conceptid)
    ) |>
    filter(between(device_exposure_start_date, {{ start_date }}, {{ end_date }})) |>
    select(person_id,
           date = device_exposure_start_date, concept_id = device_concept_id,
           concept_name = conceptname, domain = domainid
    )
}

get_concepts <- function(..., domain = c("condition", "measurement", "observation", "procedure", "drug", "device")) {
  if (length(domain) != 1) stop("Provide one domain only")
  if (!domain %in% c("condition", "measurement", "observation", "procedure", "drug", "device")) {
    stop(
      '`domain` must be one of: "condition", "measurement", "observation", "procedure", "drug", "device"'
    )
  }
  get(paste("get", domain, "concepts", sep = "_"))(...)
}

