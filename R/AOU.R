# AoU helpers

#' Connect to big query database in All of Us
#'
#' @param bucket_name variable name for your bucket. Recommend leaving the default.
#' @description To use, simply run the function without any arguments. It will
#' print a message if you connect successfully. It will also assign your bucket
#' to an object in your R environment.
#' @export
aou_connect <- function(bucket_name = "bucket"){
	dataset <- stringr::str_split_fixed(Sys.getenv('WORKSPACE_CDR'),'\\.', n = 2)
	release <- dataset[2]
	prefix <- dataset[1]

	connection <- DBI::dbConnect(
		bigrquery::bigquery(),
		billing = Sys.getenv('GOOGLE_PROJECT'),
		project = prefix,
		dataset = release
	)

	assign("con", connection, envir = .GlobalEnv)
	assign(bucket_name, Sys.getenv('WORKSPACE_BUCKET'), envir = .GlobalEnv)
	options(con.default.value = con)

	cat(cli::col_green("Connected successfully!"),
			cli::col_blue("Use `con` to access the connection and `", bucket_name,
										"` to retrieve the name of your bucket"), sep = "\n")
}

#' Move files from a bucket to your workspace
#'
#' @param files The name of a file in your bucket or a vector of multiple files.
#' @param bucket_name Name of your bucket. Recommend leaving the default
#' @description This step retrieves a file you have saved permanently in your bucket
#' into your workspace where you can read it into R using a function like write.csv().
#' @export
aou_bucket_to_workspace <- function(files, bucket_name = Sys.getenv('WORKSPACE_BUCKET')){
	# # Copy the file from current workspace to the bucket
	bucket_files = aou_ls_bucket()

	missing_files = list()

	for (i in 1:length(files)) {
		if(!(files[i] %in% bucket_files)){
			cat(cli::col_red("Oops! ", files[i], " not found in bucket\n"))
			missing_files = append(missing_files, files[i])
		} else {
			system(paste0("gsutil cp ", bucket_name, "/data/", files[i], " ."), intern = TRUE)
			cat(cli::col_green("Retrieved ", files[i], " from bucket\n"))
		}
	}

	if(length(missing_files)>0){
		missing = paste0(unlist(missing_files), collapse = ", ")
		stop(paste0(missing, " not found in bucket\n"))
	}

}

#' Save a file from your workspace to your bucket.
#'
#' @param files name of file to save
#' @param bucket_name name of your bucket. Recommend leaving the default
#' @description This step permanently saves a file you have saved in your workspace
#' to your bucket where you can always retrieve it. To use, first you need to save the desired
#' r object as a file (e.g., write.csv(object, filename.csv)) and then run this function
#' (e.g., aou_workspace_to_bucket(files = "filename.csv")).
#' @export
aou_workspace_to_bucket <- function(files, bucket_name = Sys.getenv('WORKSPACE_BUCKET')){
	# Copy the file from current workspace to the bucket
	for(i in 1:length(files)){
		system(paste0("gsutil cp ./", files[i], " ", bucket_name, "/data/"), intern = TRUE)
		cat(cli::col_green("Saved ", files[i], " to bucket\n"))
	}

}

#' List the current files in your bucket.
#'
#' @param description Quick function to list files matching a pattern in your bucket
#'
#' @param pattern pattern like *.csv or a single file name e.g., mydata.csv
#' @param bucket_name name of your bucket. Recommend leaving the default
#' @export
aou_ls_bucket <- function(pattern = "*.csv", bucket_name = Sys.getenv('WORKSPACE_BUCKET')){
	# Check if file is in the bucket
	files <- system(paste0("gsutil ls ", bucket_name, "/data/", pattern), intern = TRUE)
	stringr::str_remove(files, paste0(bucket_name, "/data/"))
}

#' List the current files in your workspace.
#'
#' @param description Quick function to list files matching a pattern in your workspace
#'
#' @param pattern pattern like *.csv or a single file name e.g., mydata.csv
#' @export
aou_ls_workspace <- function(pattern = "*.csv"){
	files <- list.files(pattern = pattern)
	files[!grepl("*.ipynb", files)]
}

#' Get occurrences of a concepts from AoU for a given cohort
#'
#'
#' @param cohort tbl; reference to a table with a column called "person_id", and columns for start_date and end_date
#' @param concepts num; a vector of concept ids
#' @param concept_set_name chr; Name to describe the concept set, used to create an indicator variable
#' @param start_date the name of the start_date column in the cohort table (unquoted)
#' @param end_date the name of the end_date column in the cohort table (unquoted)
#' @param min_n dbl; the minimum number of occurrences per person to consider the indicator true
#' @param n dbl; count the number of occurrences per person (will not include zeros)
#' @param keep_all lgl; keep columns with information about the concept (e.g., concept name, id, etc.)
#' @param con the connection object to AoU
#' @param collect lgl; whether to collect from the database
#'
#' @return a dataframe if collect = TRUE; a remote tbl if not
#' @export
#'
#' @examples
#' \dontrun{
#' tobacco <- pull_concepts(cohort, concepts = 1157, start_date = covariate_start_date,
#'  end_date = cohort_start_date, name = "tobacco"
#'  )}
#'
aou_pull_concepts <- function(cohort,
															concepts,
															start_date,
															end_date,
															concept_set_name = "concepts",
															domains = c("condition", "measurement", "observation", "procedure", "drug", "device"),
															min_n = NULL,
															n = FALSE,
															keep_all = FALSE,
															con = getOption("con.default.value"),
															collect = TRUE, ...){

	if (is.null(concept_set_name)) concept_set_name <- paste0("concept_set_", concept_set_id)
	if (!is.null(min_n) & !is.numeric(min_n)) stop("Provide a number to `min_n` to restrict to observations with at least that number of rows")
	if (n && keep_all) warning("The `keep_all` argument takes precedence; all data will be returned instead of counts.")

	if (is.null(con)) stop("Provide `con` as an argument or default with `options(con.default.value = ...)`")

	all_concepts <- map(
		domains,
		~ aou_get_concepts(cohort, concepts,
											 {{ start_date }}, {{ end_date }},
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
		if (collect) return(dbi_collect(all_concepts))
		return(all_concepts)
	}

	if (n) {
		if (collect) return(dbi_collect(count(all_concepts, concept_set, person_id)))
		return(count(all_concepts, concept_set, person_id))
	}

	res <- all_concepts |>
		distinct(person_id) |>
		mutate(!!concept_set_name := 1)

	if (collect) return(dbi_collect(res))

	res

}

aou_get_condition_concepts <- function(cohort, concepts, start_date, end_date, ...) {
	cohort |>
		omop_join("condition_occurrence", type = "left", by = "person_id") |>
		select(-c(
			condition_start_datetime, condition_end_date, condition_end_datetime,
			condition_type_concept_id, stop_reason, provider_id, visit_occurrence_id,
			visit_detail_id, condition_source_value, condition_source_concept_id,
			condition_status_source_value, condition_status_concept_id
		)) |>
		filter(condition_concept_id %in% concepts) |>
		filter(between(condition_start_date, {{ start_date }}, {{ end_date }})) |>
		omop_join("concept", type = "left", by = c("condition_concept_id" = "concept_id")) |>
		select(person_id,
					 date = condition_start_date, concept_id = condition_concept_id,
					 concept_name, domain = domain_id
		)
}

aou_get_measurement_concepts <- function(cohort, concepts, start_date, end_date, ...) {
	cohort |>
		omop_join("measurement", type = "left", by = "person_id") |>
		select(-c(
			measurement_datetime, measurement_time, measurement_type_concept_id, operator_concept_id,
			value_as_number, value_as_concept_id, unit_concept_id, range_low, range_high,
			provider_id, visit_occurrence_id, visit_detail_id, measurement_source_value,
			measurement_source_concept_id, unit_source_value, value_source_value
		)) |>
		filter(measurement_concept_id %in% concepts) |>
		filter(between(measurement_date, {{ start_date }}, {{ end_date }})) |>
		omop_join("concept", type = "left", by = c("measurement_concept_id" = "concept_id")) |>
		select(person_id,
					 date = measurement_date, concept_id = measurement_concept_id,
					 concept_name, domain = domain_id
		)
}

aou_get_procedure_concepts <- function(cohort, concepts, start_date, end_date, ...) {
	cohort |>
		omop_join("procedure_occurrence", type = "left", by = "person_id") |>
		select(-c(
			procedure_datetime, procedure_type_concept_id, modifier_concept_id,
			quantity, provider_id, visit_occurrence_id, visit_detail_id,
			procedure_source_value, procedure_source_concept_id, modifier_source_value
		)) |>
		filter(procedure_concept_id %in% concepts) |>
		filter(between(procedure_date, {{ start_date }}, {{ end_date }})) |>
		omop_join("concept", type = "left", by = c("procedure_concept_id" = "concept_id")) |>
		select(person_id,
					 date = procedure_date, concept_id = procedure_concept_id,
					 concept_name, domain = domain_id
		)
}

aou_get_observation_concepts <- function(cohort, concepts, start_date, end_date, ...) {
	cohort |>
		omop_join("observation", type = "left", by = "person_id") |>
		select(-c(
			observation_datetime, observation_type_concept_id, value_as_number,
			value_as_string, value_as_concept_id, qualifier_concept_id,
			unit_concept_id, provider_id, visit_occurrence_id, visit_detail_id,
			observation_source_value, observation_source_concept_id,
			unit_source_value, qualifier_source_value
		)) |>
		filter(observation_concept_id %in% concepts) |>
		filter(between(observation_date, {{ start_date }}, {{ end_date }})) |>
		omop_join("concept", type = "left", by = c("observation_concept_id" = "concept_id")) |>
		select(person_id,
					 date = observation_date, concept_id = observation_concept_id,
					 concept_name, domain = domain_id
		)
}

aou_get_drug_concepts <- function(cohort, concepts, start_date, end_date, ...) {
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
		filter(drug_concept_id %in% concepts) |>
		filter(between(drug_exposure_start_date, {{ start_date }}, {{ end_date }})) |>
		omop_join("concept", type = "left", by = c("drug_concept_id" = "concept_id")) |>
		select(person_id,
					 date = drug_exposure_start_date, concept_id = drug_concept_id,
					 concept_name, domain = domain_id
		)
}

aou_get_device_concepts <- function(cohort, concepts, start_date, end_date, ...) {
	cohort |>
		omop_join("device_exposure", type = "left", by = "person_id") |>
		select(-c(
			device_exposure_start_datetime, device_exposure_end_date,
			device_exposure_end_datetime, device_type_concept_id,
			unique_device_id, quantity, provider_id, visit_occurrence_id,
			visit_detail_id, device_source_value, device_source_concept_id
		)) |>
		filter(device_concept_id %in% concepts) |>
		filter(between(device_exposure_start_date, {{ start_date }}, {{ end_date }})) |>
		omop_join("concept", type = "left", by = c("device_concept_id" = "concept_id")) |>
		select(person_id,
					 date = device_exposure_start_date, concept_id = device_concept_id,
					 concept_name, domain = domain_id
		)
}


aou_get_concepts <- function(..., domain = c("condition", "measurement", "observation", "procedure", "drug", "device")) {
	if (length(domain) != 1) stop("Provide one domain only")
	if (!domain %in% c("condition", "measurement", "observation", "procedure", "drug", "device")) {
		stop(
			'`domain` must be one of: "condition", "measurement", "observation", "procedure", "drug", "device"'
		)
	}
	get(paste("aou_get", domain, "concepts", sep = "_"))(..., combine = FALSE)
}

#' Get survey questions from AoU for a given cohort
#'
#'
#' @param cohort tbl; reference to a table with a column called "person_id"
#' @param concepts num; a vector of concept ids for questions in the survey table
#' @param collect lgl; whether to collect from the database
#' @param reshape lgl; whether to turn the long data into wide data with clean variable names

#' @return a remote tbl with columns person_id, date (survey_datetime),
#'  concept_id (question_concept_id), question, answer.
#'
#' @examples
#' \dontrun{
#' survey_data <- aou_pull_survey_concepts(cohort, concepts = c(1157, 124839))
#'  )}
#'
aou_pull_survey_concepts <- function(cohort, concepts, collect = TRUE, reshape = FALSE, ...) {
	dat <- cohort |>
		omop_join("ds_survey", type = "left", by = "person_id") |>
		select(person_id, question, question_concept_id, answer, answer_concept_id, survey,
					 survey_datetime) |>
		filter(question_concept_id %in% concepts)


	if (reshape) {
		if (!collect) warning("survey data must be collected to be reshaped")
		# reshape the questions/answers so that there's one column for every question
		dat %>%
			select(person_id, question, answer) %>%
			# since there are multiple answers for some questions (the "conditions" questions), put all in a list
			pivot_wider(names_from = question, values_from = answer, values_fn = list) %>%
			janitor::clean_names() %>%
			# don't need answers in a list if there is only one per question
			# for some reason some people have multiple answers to the employment question too
			# unnest(c(where(is.list), -contains("condition"), -contains("employment")), keep_empty = TRUE)
			dbi_collect()
	}
	if (!collect) return(dat)
	dbi_collect(dat)
}
