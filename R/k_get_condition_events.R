#' Get all diagnosis events for patients with specific condition codes
#' Materializes results to a temp table for reliability on large databases
#'
#' @param con Database connection
#' @param codes Character vector of ICD codes (supports % wildcards)
#' @param komodo_schema Schema containing Komodo tables
#' @param write_schema Schema where the temp table will be written
#' @param table_name Name for the materialized temp table
#' @param overwrite Whether to drop and recreate if the table already exists (default TRUE)
#' @return Lazy table pointing at the materialized temp table
#'
#' @export
k_get_condition_events <- function(con,
																	 codes,
																	 komodo_schema = "komodo_ext",
																	 write_schema,
																	 table_name,
																	 overwrite = TRUE) {
	# --- Input validation ---
	if (length(codes) == 0) stop("codes must contain at least one ICD code")
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

	# --- Helper: string/multi-value columns ---
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
    SELECT patient_id, admit_date AS diagnosis_date
    FROM ", komodo_schema, ".inpatient_events i
    WHERE ", create_single_col_filter(codes, "i", "admission_diagnosis_code"), "
       OR ", create_single_col_filter(codes, "i", "primary_diagnosis_code"), "
       OR ", create_string_col_filter(codes, "i", "secondary_diagnosis_codes"), "
    UNION ALL
    SELECT patient_id, service_date AS diagnosis_date
    FROM ", komodo_schema, ".non_inpatient_events n
    WHERE ", create_string_col_filter(codes, "n", "diagnosis_codes"), "
       OR ", create_string_col_filter(codes, "n", "primary_diagnosis_code_array"), "
  "))

	# Return lazy table pointing at the materialized result
	dplyr::tbl(con, dplyr::sql(paste0("SELECT * FROM ", full_table)))
}
