#' Create a new project
#'
#'
#' @name lab_project

lab_project <- function(path, ...) {

  dots <- list(...)
  dir.create(path, recursive = TRUE)
  if (dots$git) git2r::init(path)
  if (dots$renv) renv::init(path)

}
