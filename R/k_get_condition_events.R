#' Get all diagnosis events for patients with specific condition codes
#' Returns every occurrence, not just the first, enabling timing-based cohort logic
#'
#' @param connection Database connection
#' @param codes Character vector of ICD codes (supports % wildcards)
#' @param komodo_schema Schema containing Komodo tables
#' @return Lazy table with patient_id and diagnosis_date
#'
#' @examples
#' # Get all fracture events, then filter relative to a prescription
#' fracture_events <- k_get_condition_events(
#'   con,
#'   codes = c("S72.%", "S82.%")
#' )
#'
#' cohort <- fracture_events |>
#'   inner_join(
#'     pharmacy |>
#'       filter(generic_name == "lisinopril") |>
#'       select(patient_id, prescription_date = service_date),
#'     by = "patient_id"
#'   ) |>
#'   filter(
#'     diagnosis_date >= prescription_date,
#'     diagnosis_date <= prescription_date + lubridate::days(5)
#'   ) |>
#'   distinct(patient_id)
#'
#' # Washout: no fracture in 365 days before prescription
#' clean_cohort <- lisinopril_patients |>
#'   anti_join(
#'     fracture_events |>
#'       inner_join(lisinopril_patients, by = "patient_id") |>
#'       filter(
#'         diagnosis_date >= prescription_date - 365,
#'         diagnosis_date < prescription_date
#'       ),
#'     by = "patient_id"
#'   )

k_get_condition_events <- function(connection,
                                   codes,
                                   komodo_schema = "komodo_ext") {
  
  # --- Input validation ---
  if (length(codes) == 0) stop("codes must contain at least one ICD code")
  if (!is.character(codes)) stop("codes must be a character vector")
  
  # --- Helper: conditions for single-value columns ---
  create_code_filter <- function(codes, alias, column) {
    exact <- codes[!grepl("%", codes)]
    like  <- codes[grepl("%", codes)]
    
    filters <- c()
    if (length(exact) > 0) {
      filters <- c(filters,
                   paste0(alias, ".", column, " IN ('", paste(exact, collapse = "','"), "')")
      )
    }
    if (length(like) > 0) {
      for (code in like) {
        filters <- c(filters, paste0(alias, ".", column, " LIKE '", code, "'"))
      }
    }
    paste(filters, collapse = " OR ")
  }
  
  # --- Build SQL ---
  # Note: no DROP/CREATE — this is a lazy query, not a materialized table
  sql <- paste0("
    SELECT patient_id, admit_date AS diagnosis_date
    FROM ", komodo_schema, ".inpatient_events i
    WHERE ", create_code_filter(codes, "i", "admission_diagnosis_code"), "
       OR ", create_code_filter(codes, "i", "primary_diagnosis_code"), "
       OR ", create_code_filter(codes, "i", "secondary_diagnosis_codes"), "
   
    UNION ALL
   
    SELECT patient_id, service_date AS diagnosis_date
    FROM ", komodo_schema, ".non_inpatient_events n
    WHERE ", create_code_filter(codes, "n", "diagnosis_codes"), "
       OR ", create_code_filter(codes, "n", "primary_diagnosis_code_array"), "
  ")
  
  # Return as lazy table — no execution happens here
  dplyr::tbl(connection, dplyr::sql(sql))
}