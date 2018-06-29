#' @export
#' This function runs the wetsisan app
#' 
run_wetsisan <- function() {
  appDir <- system.file("shiny-examples", "wetsisan", package = "wetsisan")
  if (appDir == "") {
    stop("Could not find example directory. Try re-installing `wetsisan`.", call. = FALSE)
  }
  
  shiny::runApp(appDir, display.mode = "normal")
}