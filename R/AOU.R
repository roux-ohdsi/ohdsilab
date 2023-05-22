# Aou helpers

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
  		error_at_end = TRUE
  		missing_files = append(missing_files, files[i])
  	} else {
	    system(paste0("gsutil cp ", bucket_name, "/data/", files[i], " ."), intern = TRUE)
	    cat(cli::col_green("Retrieved ", files[i], " from bucket\n"))
  	}
  }

	if(isTRUE(error_at_end)){
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
