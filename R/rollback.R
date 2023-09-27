



#' Shortcut to rollback in the case of a redshift error
#'
#' @param con defaults to the default connection in the session. either set using options or supplied directly
#'
#' @return nothing
#' @export
#' @examples \dontrun{rb()}
rb <- function(con = getOption("con.default.value")){
    tryCatch(
      expr = {
        DatabaseConnector::executeSql(con, "ROLLBACK;", progressBar = FALSE, reportOverallTime = FALSE)
        cat(cli::col_green("Rollback Successful"))
      },
      error = function(e){
        #message('Caught an error!')
        cat(cli::col_red(paste("Error:", e[[1]])))

      },
      warning = function(w){
       # message('Caught an warning!')
        cat(cli::col_yellow(paste("Warning:", w[[1]])))

      },
      finally = {

      }
    )
}

