#' Collect using the DBI package
#'
#' @param query the sql query built from dbplyr
#' @param connection connection to the db. can leave blank if set using options
#'
#' @return collected dataframe
#' @export
dbi_collect <- function(query, connection = getOption("con.default.value")){
  if(connection == getOption("con.default.value") & is.null(getOption("con.default.value"))){
    stop("Make sure to set the default connection using options or provide one explicitly")
  }
  sql = dbplyr::sql_render(query)
  DBI::dbGetQuery(connection, sql)
}
