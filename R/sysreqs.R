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
#' @param sudo if `TRUE` (default), the command runs as root
#' @param exclude packages to exclude from installation because they already
#'   exist on the system.
#' @return a vector of exectutible system calls to install the dependencies
#' @export
#' @examples
#' lock <- system.file("renv.lock", package = "vise")
#'
#' # The system requirements for a typical {knitr} installation
#' if (startsWith(tolower(R.version$os), "linux")) {
#'   print(vise::ci_sysreqs(lock, execute = FALSE))
#' }
ci_sysreqs <- function(lockfile, execute = TRUE, sudo = TRUE, exclude = c("git", "make", "pandoc")) {
  # convert the lockfile to a temporary DESCRIPTION file
  if (!requireNamespace("remotes", quietly = TRUE)) {
    stop("The {remotes} package is required for this function.")
  }
  desc <- lock2desc(lockfile)
  ver  <- tolower(system("lsb_release -irs", intern = TRUE))
  print(ver)

  if (!requireNamespace("pak", quietly = TRUE)) {
    install.packages("pak")
  }

  cat("::group::Register Repositories\n")
  on_linux <- Sys.info()[["sysname"]] == "Linux"
  if (on_linux) {
    if (Sys.getenv("RSPM") == "") {
      release <- system("lsb_release -c | awk '{print $2}'", intern = TRUE)
      Sys.setenv("RSPM" =
      paste0("https://packagemanager.posit.co/all/__linux__/", release, "/latest"))
    }
  }
  repos <- list(
    RSPM        = Sys.getenv("RSPM"),
    carpentries = "https://carpentries.r-universe.dev/",
    CRAN        = "https://cran.rstudio.com"
  )
  options(pak.no_extra_messages = TRUE, repos = repos)
  cat("Repositories Used\n")
  cat(paste(pak::repo_status()$name, " [", pak::repo_status()$url), "]\n")
  cat("::endgroup::\n")

  reqs <- pak::pkg_sysreqs(dirname(desc))
  # exclude packages that we already have on the system
  for (e in paste0("\\b", exclude, "\\b")) {
    reqs <- reqs[!grepl(e, reqs)]
  }

  if (length(reqs) == 0) {
    cat("No system dependencies to install\n")
    return(reqs)
  }

  cat("Installing system dependencies:", paste(reqs$packages$system_packages, collapse = ", "), "\n")
  if (execute) {
    system(reqs$pre_install)
    system(reqs$install_scripts)
  }

  #nocov end
  return(reqs)
}

ci_new_pkgs_sysreqs <- function(pkgs, ...) {
  d <- desc::description$new("!new")
  for (pkg in pkgs) {
    d$set_dep(pkg$package)
  }
  ci_sysreqs(d, ...)
}
