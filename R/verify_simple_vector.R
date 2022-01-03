#' Verify that an input is a simple vector
#'
#' In some GitHub actions, you can pass an arbitrary R vector in and we will
#' parse it. Unfortunately, this can lead to the insertion of malicious code,
#' so this function will thrown an error if the submitted R expression is 
#' anything but a vector created with `c()`,
#' @param inputs an R expression
#' @return nothing. this is called for its side-effect. if `inputs` is not a 
#'   simple vector, an error will be thrown.
#' @export
#' @examples
#' # simple vectors work. 
#' try(vise::verify_simple_vector(c(1, "a", c(TRUE, FALSE))))
#' 
#' # vectors using any other function fail, even if they are harmless
#' try(vise::verify_simple_vector(c(1, print("a"), c(TRUE, FALSE))))
verify_simple_vector <- function(inputs) {
  pd <- getParseData(parse(text = as.character(match.call()["inputs"])))
  funs <- pd$token == "SYMBOL_FUNCTION_CALL"
  if (any(funs) && any(pd$text[funs] != "c")) {
    stop("::error::repository settings should be an R vector. No functions other than `c()` are allowed")
  }
  invisible()
}
