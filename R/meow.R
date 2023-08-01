#' `cat()` for GitHub output variables 
#'
#' @param the name of the output variable to write to
#' @param thing a vector that can be passed to `cat()`
#'
#' @details
#' This is a way to print output for GitHub that requires you to pipe output into 
#' the `GITHUB_OUTPUT` environment variable. This will write single-line
#' variables as `var=value` and multiline variables using a random key
#' according to this guidance from GitHub to avoid injection:
#' <https://docs.github.com/en/actions/using-workflows/workflow-commands-for-github-actions#multiline-strings>
#'
#' @keywords internal
#' @return nothing. This is used to write output for GitHub
#' @examples
#' tmp <- tempfile()
#' env <- Sys.getenv("GITHUB_OUTPUT", unset = "")
#' on.exit(Sys.setenv("GITHUB_OUTPUT" = env)
#' Sys.setenv("GITHUB_OUTPUT" = tmp)
#' meow("single", "hello!")
#' meow("multi", c("This information", "exists on", "multiple lines"))
#' writeLines(readLines(tmp))
meow  <- function(name, thing) {
  out <- Sys.getenv("GITHUB_OUTPUT")
  if (length(thing) > 1L) {
    # generating random delimiter for the output to avoid injection
    # https://docs.github.com/en/actions/using-workflows/workflow-commands-for-github-actions#multiline-strings
    EOF <- paste(sample(c(letters, LETTERS, 0:9), 20, replace = TRUE), collapse = "")
    cat(name, "<<", EOF, "\n", file = out, sep = "", append = TRUE)
    cat(thing, EOF, file = out, sep = "\n", append = TRUE)
  } else {
    cat(name, "=", thing, "\n", file = out, sep = "", append = TRUE)
  }
}
