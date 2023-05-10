# Aou helpers

#' Connect to big query database in All of Us
#'
#' @param bucket_name variable name for your bucket. Recommend leaving the default.
#' @param description To use, simply run the function without any arguments. It will
#' print a message if you connect successfully. It will also assign your bucket
#' to an object in your R environment.
#' @export
aou_connect <- function(bucket_name = "bucket"){
  dataset <- str_split_fixed(Sys.getenv('WORKSPACE_CDR'),'\\.',n=2)
  release <- dataset[2]
  prefix <- dataset[1]

  connection <- dbConnect(
    bigrquery::bigquery(),
    billing = Sys.getenv('GOOGLE_PROJECT'),
    project = prefix,
    dataset = release
  )

  assign("con", connection, envir = .GlobalEnv)
  assign(bucket_name, Sys.getenv('WORKSPACE_BUCKET'), envir = .GlobalEnv)

  cat("Connected Successfully")
}

#' Retrieve a file from a bucket to your workspace
#'
#' @param file_name The name of a file in your bucket or a vector of multiple files.
#' @param bucket_name Name of your bucket. Recommend leaving the default
#' @param description This step retrieves a file you have saved permanently in your bucket
#' into your  where you can read it into R using a function like write.csv().
#' @export
aou_retrieve_from_bucket <- function(file_name, bucket_name = "bucket"){
  # # Copy the file from current workspace to the bucket
  n = 0
  for(i in 1:length(file_name)){
    system(paste0("gsutil cp ", get(bucket_name), "/data/", file_name[i], " ."), intern=T)
    n = n + 1
  }

  cat("Retrieved ", n, " files")

}

#' Save a file from your workspace to your bucket.
#'
#' @param file_name name of file to save
#' @param bucket_name name of your bucket. Recommend leaving the default
#' @param description This step permanently saves a file you have saved in your workspace
#' to your bucket where you can always retrieve it. To use, first you need to save the desired
#' r object as a file (e.g., write.csv(object, filename.csv)) and then run this function
#' (e.g., aou_save_to_bucket(file_name = "filename.csv")).
#' @export
aou_save_to_bucket <- function(file_name, bucket_name = "bucket"){
  # Copy the file from current workspace to the bucket
  n = 0
  for(i in 1:length(file_name)){
    system(paste0("gsutil cp ./", filename, " ", get(bucket_name), "/data/"), intern=T)
    n = n + 1
  }

  cat("Saved ", n, " files")
}

#' List the current files in your bucket.
#'
#' @param description Quick function to list files matching a pattern in your bucket
#'
#' @param pattern pattern like *.csv or a single file name e.g., mydata.csv
#' @export
aou_ls <- function(pattern = "*.csv", bucket_name = "bucket"){
  # Check if file is in the bucket
  system(paste0("gsutil ls ", get(bucket_name), "/data/", pattern), intern=T)
}
