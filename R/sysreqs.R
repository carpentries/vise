#' detect and execute system requirements from a lockfile
#'
#' This function converts a renv lockfile to a description file and then
#' determines the system requirements via [pak::pkg_sysreqs()] using
#' the RStudio online resource. This is intended to be run on continuous
#' integration, so will error on MacOS and Windows
#'
#' @param lockfile the path to a {renv} lockfile
#' @param execute if `TRUE` (default), the commands from [pak::pkg_sysreqs()]
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
  desc <- lock2desc(lockfile)
  ver  <- tolower(system("lsb_release -irs", intern = TRUE))
  print(ver)

  if (!requireNamespace("pak", quietly = TRUE)) {
    utils::install.packages("pak", repos = sprintf("https://r-lib.github.io/p/pak/stable/%s/%s/%s", .Platform$pkgType, R.Version()$os, R.Version()$arch))
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

  d <- desc::description$new(desc)
  imports <- d$get_deps()
  pkg_names <- imports$package[imports$type == "Imports"]
  reqs <- pak::pkg_sysreqs(pkg_names)

  # for each of the packages in exclude, drop it from reqs
  if (length(exclude) > 0 && length(reqs$packages$system_packages) > 0) {
    to_exclude <- intersect(reqs$packages$system_packages, exclude)
    if (length(to_exclude) > 0) {
      cat("Excluding system packages:", paste(to_exclude, collapse = ", "), "\n")

            # drop the excluded package rows from the system_packages
      for (ex in to_exclude) {
        to_remove <- which(reqs$packages$system_packages == ex)
        if (length(to_remove) > 0) {
          reqs$packages <- reqs$packages[-to_remove, , drop = FALSE]
        }
      }

      # remove the excluded packages from the reqs$install_scripts
      req_list <- unlist(
        strsplit(reqs$install_scripts, " ")
      )
      # drop the first three elements which are apt-get, -y, install
      req_list <- req_list[-c(1:3)]
      req_list <- req_list[!req_list %in% to_exclude]
      if (length(req_list) == 0) {
        reqs$install_scripts <- ""
      } else {
        reqs$install_scripts <- paste("apt-get -y install", paste(req_list, collapse = " "))
      }
    }
  }

  if (length(reqs$packages$system_packages) == 0) {
    cat("No system dependencies to install\n")
    return(reqs)
  }

  if (execute) {
    su <- if (sudo) "sudo" else ""
    system(trimws(paste(su, reqs$pre_install)))
    system(trimws(paste(su, reqs$install_scripts)))
  }

  #nocov end
  return(reqs)
}

#' convert a list of packages into a description file and detect system requirements
#'
#' This function converts a set of R package names to a description file and then
#' passes this to [ci_sysreqs()] for system requirements detection.
#'
#' @param pkgs the list of packages, each an element with a `package` field
#' @param ... extra options to be passed to ci_sysreqs()`
#' @export
#' @examples
#' Sys.setenv(R_USER_CACHE_DIR = tempfile())
#'
#' pkgs <- list(list(package = "knitr", package = "rmarkdown"))
#' if (startsWith(tolower(R.version$os), "linux")) {
#'   vise::ci_new_pkgs_sysreqs(pkgs, execute = FALSE)
#' }
ci_new_pkgs_sysreqs <- function(pkgs, ...) {
  d <- desc::description$new("!new")
  for (pkg in pkgs) {
    d$set_dep(pkg$package)
  }
  ci_sysreqs(d, ...)
}
