#' detect and execute system requirements from a lockfile
#'
#' This function converts a renv lockfile to a description file and then 
#' determines the system requirements via [remotes::system_requirements()] using
#' the RStudio online resource. This is intended to be run on continuous
#' integration, so will probably error on macos and windows
#'
#' @param lockfile the path to a {renv} lockfile
#' @param execute if `TRUE` (default), the commands from [remotes::system_requirements()]
#'   will be executed via [base::system()].
#' @param exclude packages to exclude from installation because they already
#'   exist on the system.
#' @return a vector of exectutible system calls to install the dependencies
#' @export
#' @examples
#' lock <- system.file("renv.lock", package = "vise")
#'
#' # The system requirements for a typical {knitr} installation
#' ci_sysreqs(lock, execute = FALSE)
ci_sysreqs <- function(lockfile, execute = TRUE, exclude = c("git", "make", "pandoc")) {
  # convert the lockfile to a temporary DESCRIPTION file
  desc <- lock2desc(lockfile)
  ver  <- tolower(system("lsb_release -irs", intern = TRUE))
  reqs <- remotes::system_requirements(ver[1], ver[2], path = dirname(desc))

  # exclude packages that we already have on the system
  for (e in paste0("\\b", exclude, "\\b")) {
    reqs <- reqs[!grepl(e, reqs)]
  }

  # on ubuntu, we can assume apt, so we can compress this to a single call
  if (ver[1] == "ubuntu") {
    nz <- nzchar(reqs)
    deps <- paste(substring(reqs[nz], 20, nchar(reqs[nz])), collapse = " ")
    reqs <- paste("apt-get install -y", deps)
  }

  if (execute) {
    for (r in reqs) {
      system(r)
    }
  }
  return(reqs)
}
