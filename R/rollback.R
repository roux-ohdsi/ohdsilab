



#' shortcut to rollback in teh case of a redshift error
#'
#' @param con defaults to the default connection in the session. either set using options or supplied directly
#'
#' @return
#' @export
rb <- function(con = getOption("con.default.value")){
    tryCatch(
      expr = {
        executeSql(con, "ROLLBACK;", progressBar = FALSE, reportOverallTime = FALSE)
        insight::print_color("Rollback Successful", color = "green")
      },
      error = function(e){
        #message('Caught an error!')
        insight::print_color(paste("Error:", e[[1]]), color = "red")
      },
      warning = function(w){
       # message('Caught an warning!')
        insight::print_color(paste("Warning:", w[[1]]), color = "orange")
      },
      finally = {

      }
    )
  }

