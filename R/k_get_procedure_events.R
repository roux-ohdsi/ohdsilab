#' Get all procedure events for patients with specific procedure codes
#' Returns every occurrence, not just the first, enabling timing-based cohort logic
#'
#' @param connection Database connection
#' @param codes Character vector of procedure codes (supports % wildcards)
#' @param komodo_schema Schema containing Komodo tables
#' @return Lazy table with patient_id and procedure_date
#'
#' @examples
#' # Get all xray procedures within 5 days of a fracture
#' xray_codes <- c("71045", "71046", "73560", "73562")
#' xray_events <- k_get_procedure_events(con, codes = xray_codes)
#'
#' cohort <- k_get_condition_events(con, codes = c("S72.%", "S82.%")) |>
#'   inner_join(xray_events, by = "patient_id") |>
#'   filter(
#'     procedure_date >= diagnosis_date,
#'     procedure_date <= diagnosis_date + lubridate::days(5)
#'   ) |>
#'   distinct(patient_id)

k_get_procedure_events <- function(connection,
                                   codes,
                                   komodo_schema = "komodo_ext") {
  
  # --- Input validation ---
  if (length(codes) == 0) stop("codes must contain at least one procedure code")
  if (!is.character(codes)) stop("codes must be a character vector")
  
  # --- Helper: filter for single-value columns ---
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
  sql <- paste0("
    SELECT patient_id, admit_date AS procedure_date
    FROM ", komodo_schema, ".inpatient_events i
    WHERE ", create_code_filter(codes, "i", "icd_pcs_codes"), "
       OR ", create_code_filter(codes, "i", "cpt_hcpcs_codes"), "
    UNION ALL
    SELECT patient_id, service_date AS procedure_date
    FROM ", komodo_schema, ".non_inpatient_events n
    WHERE ", create_code_filter(codes, "n", "procedure_code"), "
       OR ", create_code_filter(codes, "n", "icd_pcs_codes"), "
  ")
  
  # Return as lazy table — no execution happens here
  dplyr::tbl(connection, dplyr::sql(sql))
}