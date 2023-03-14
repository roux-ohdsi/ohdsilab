#' Insert string
#'
#'@description Useful for inserting periods in icd9 codes when they come without.
#'
#' @param x a character or character vector
#' @param pos what position in the string to insert
#' @param insert what to insert
#'
#' @return
#' @export
#'
#' @examples
str_insert <- function(x, pos, insert) {       # Create own function
  gsub(paste0("^(.{", pos, "})(.*)$"),
       paste0("\\1", insert, "\\2"),
       x)
}
