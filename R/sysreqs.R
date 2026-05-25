detect_linux_distro <- function() {
  if (Sys.info()[["sysname"]] == "Linux") {
    os_release <- readLines("/etc/os-release")
    distro <- sub("ID=(.*)$", "\\1", os_release[grepl("^ID=", os_release)])
    release <- sub("VERSION_ID=(.*)$", "\\1", os_release[grepl("^VERSION_ID=", os_release)])
    codename <- ""
    if (distro == "ubuntu") {
      codename <- sub("UBUNTU_CODENAME=(.*)$", "\\1", os_release[grepl("^UBUNTU_CODENAME=", os_release)])
    }
    return(list(distro = distro, version = release, codename = codename))
  }
  return(NULL)
}

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
#' @param use_pak if `TRUE`, use the `pak` package to determine system requirements. Else, remotes.
#' @return a vector of exectutible system calls to install the dependencies
#' @export
#' @examples
#' lock <- system.file("renv.lock", package = "vise")
#'
#' # The system requirements for a typical {knitr} installation
#' if (startsWith(tolower(R.version$os), "linux")) {
#'   print(vise::ci_sysreqs(lock, execute = FALSE))
#' }
ci_sysreqs <- function(lockfile, execute = TRUE, sudo = TRUE, exclude = c("git", "make", "pandoc"), use_pak = FALSE) {
  # convert the lockfile to a temporary DESCRIPTION file
  desc <- lock2desc(lockfile)
  on_linux <- Sys.info()[["sysname"]] == "Linux"
  release <- detect_linux_distro()
  distro <- release$distro
  ver <- release$version
  print(distro, ver)

  if (Sys.getenv("RSPM") == "") {
    if (distro == "ubuntu") {
      codename <- release$codename
      Sys.setenv("RSPM" =
        paste0("https://packagemanager.posit.co/all/__linux__/", codename, "/latest")
      )
    } else if (distro == "alpine") {
      Sys.setenv("RSPM" =
        paste0("https://packagemanager.posit.co/cran/latest")
      )
    }
  }

  if (use_pak) {
    if (!requireNamespace("pak", quietly = TRUE)) {
        # install binary pak
        utils::install.packages("pak", repos = sprintf("https://r-lib.github.io/p/pak/stable/%s/%s/%s", .Platform$pkgType, R.Version()$os, R.Version()$arch))
    }

    cat("::group::Register Repositories\n")
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
          reqs$install_scripts <- paste("apt-get install -y", paste(req_list, collapse = " "))
        }
      }
    }

    if (length(reqs$packages$system_packages) == 0) {
      cat("No system dependencies to install\n")
      return(reqs)
    }

    # nocov start
    if (execute) {
      su <- if (sudo) "sudo" else ""
      system(trimws(paste(su, reqs$pre_install)))
      system(trimws(paste(su, reqs$install_scripts)))
    }
    # nocov end
    return(reqs)
  }
  else {
    reqs <- new.env()
    reqs$pre_install     <- c()
    reqs$install_scripts <- c()

    # convert the lockfile to a temporary DESCRIPTION file
    if (!requireNamespace("remotes", quietly = TRUE)) {
      stop("The {remotes} package is required for this function.")
    }

    pkg_manager <- if (distro == "ubuntu") "apt-get" else if (distro == "alpine") "apk" else stop("Unsupported Linux distribution: ", distro)
    pkg_install_cmd <- if (distro == "ubuntu") paste(pkg_manager, "-y install") else if (distro == "alpine") paste(pkg_manager, "add --no-cache") else stop("Unsupported Linux distribution: ", distro)

    if (distro == "ubuntu") {
      sys_reqs <- remotes::system_requirements(distro, ver, path = dirname(desc))
      # get the apt installable packages
      apt_reqs <- sys_reqs[grepl("^apt-get.*install", sys_reqs)]

      # on ubuntu, we can assume apt
      nz <- nzchar(apt_reqs)
      deps_list <- substring(apt_reqs[nz], 20, nchar(apt_reqs[nz]))
      to_install <- setdiff(deps_list, exclude)
      if (length(to_install) == 0) {
        cat("No system dependencies to install\n")
        return(reqs)
      }
      reqs$install_scripts <- paste("apt-get -y install", to_install)

      # compress down to a single call for efficiency
      deps <- paste(to_install, collapse = " ")
      pkg_reqs <- paste("apt-get -y install", deps)

      # get any ppa requirements
      ppa_reqs <- sys_reqs[grepl("add-apt-repository|ppa:", sys_reqs)]
      reqs$pre_install <- ppa_reqs

      # get any other requirements
      other_reqs <- setdiff(sys_reqs, c(apt_reqs, ppa_reqs))
      reqs$pre_install <- c(reqs$pre_install, other_reqs)

      #nocov start
      if (execute) {
        su <- if (sudo) "sudo" else ""
        system(trimws(paste(su, "apt-get update")))
        system(trimws(paste(su, "apt-get -y install software-properties-common")))

        for (ppa_r in ppa_reqs) {
          system(trimws(paste(su, ppa_r)))
        }

        for (oth_r in other_reqs) {
          system(trimws(paste(su, oth_r)))
        }

        for (pkg_r in pkg_reqs) {
          system(trimws(paste(su, pkg_r)))
        }
      }
      #nocov end
    }

    return(reqs)
  }
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
