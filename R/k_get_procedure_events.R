#' Get all procedure events for patients with specific procedure codes
#' Materializes results to a temp table for reliability on large databases
#'
#' @param con Database connection
#' @param codes Character vector of procedure codes (supports % wildcards)
#' @param komodo_schema Schema containing Komodo tables
#' @param write_schema Schema where the temp table will be written
#' @param table_name Name for the materialized temp table
#' @param overwrite Whether to drop and recreate if the table already exists (default TRUE)
#' @return Lazy table pointing at the materialized temp table
#'
#' @examples
#' # Get all xray procedures within 5 days of a fracture
#' xray_codes <- c("71045", "71046", "73560", "73562")
#' xray_events <- k_get_procedure_events(
#'   con,
#'   codes = xray_codes,
#'   write_schema = write_schema,
#'   table_name = "xray_events"
#' )
#'
#' cohort <- k_get_condition_events(
#'   con,
#'   codes = c("S72%", "S82%"),
#'   write_schema = write_schema,
#'   table_name = "fracture_events"
#' ) |>
#'   inner_join(xray_events, by = "patient_id") |>
#'   filter(
#'     procedure_date >= diagnosis_date,
#'     procedure_date <= diagnosis_date + lubridate::days(5)
#'   ) |>
#'   distinct(patient_id)
#'
#' @export
k_get_procedure_events <- function(con,
																	 codes,
																	 komodo_schema,
																	 write_schema,
																	 table_name,
																	 overwrite = TRUE) {
	# --- Input validation ---
	if (length(codes) == 0) stop("codes must contain at least one procedure code")
	if (!is.character(codes)) stop("codes must be a character vector")
	if (missing(write_schema)) stop("write_schema is required for materialization")
	if (missing(table_name))   stop("table_name is required for materialization")

	# --- Helper: single-value columns ---
	create_single_col_filter <- function(codes, alias, column) {
		exact <- codes[!grepl("%", codes)]
		like  <- codes[grepl("%", codes)]
		filters <- c()
		if (length(exact) > 0) {
			filters <- c(filters,
									 paste0(alias, ".", column, " IN ('", paste(exact, collapse = "','"), "')")
			)
		}
		for (code in like) {
			filters <- c(filters, paste0(alias, ".", column, " LIKE '", code, "'"))
		}
		paste(filters, collapse = " OR ")
	}

	# --- Helper: delimited string columns ---
	create_string_col_filter <- function(codes, alias, column) {
		core_codes <- gsub("%", "", codes)
		filters <- sapply(core_codes, function(code) {
			paste0(alias, ".", column, " LIKE '%", code, "%'")
		})
		paste(filters, collapse = " OR ")
	}

	full_table <- paste0(write_schema, ".", table_name)

	# --- Drop if overwrite ---
	if (overwrite) {
		DatabaseConnector::executeSql(
			con,
			paste0("DROP TABLE IF EXISTS ", full_table, ";"),
			progressBar = FALSE
		)
	}

	# --- Materialize ---
	DatabaseConnector::executeSql(con, paste0("
    CREATE TABLE ", full_table, " AS
    SELECT patient_id, admit_date AS procedure_date
    FROM ", komodo_schema, ".inpatient_events i
    WHERE ", create_string_col_filter(codes, "i", "cpt_hcpcs_codes"), "
       OR ", create_string_col_filter(codes, "i", "icd_pcs_codes"), "
    UNION ALL
    SELECT patient_id, service_date AS procedure_date
    FROM ", komodo_schema, ".non_inpatient_events n
    WHERE ", create_single_col_filter(codes, "n", "procedure_code"), "
       OR ", create_string_col_filter(codes, "n", "icd_pcs_codes"), "
  "))

	# Return lazy table pointing at the materialized result
	dplyr::tbl(con, dplyr::sql(paste0("SELECT * FROM ", full_table)))
}
