#' Update Packages in a {renv} lockfile in GitHub Actions
#'
#' With actively developed projects, it can be beneficial to auto-update
#' packages used in the project with a failsafe to roll back versions in case
#' there are breaking changes that need to be fixed. This is noramlly
#' accomplished via the function [renv::update()], but that assumes that no new
#' packages have been introduced into your workflow. This function searches for
#' new packages, and updates existing packages.
#'
#' @param profile the profile of the renv project
#' @param update a character vector of `'true'` (default) or `'false'`, which 
#'   indicates whether or not the existing packages should be updated.
#' @param repos the repositories to use in the search.
#' @export
ci_update <- function(profile = 'lesson-requirments', update = 'true', repos = NULL) {

  n <- 0
  the_report <- character(0)
  cat("::group::Restoring package library\n")
  Sys.setenv("RENV_PROFILE" = profile)
  lib  <- renv::paths$library()
  lock <- renv::paths$lockfile()
  current_lock <- lockfile(lock)$data()
  on_linux <- Sys.info()[["sysname"]] == "Linux"
  if (!is.null(repos))
    options(repos = repos)
  if (on_linux)
    options(repos = c(RSPM = Sys.getenv("RSPM"), getOption("repos")))
  renv::load()
  shh <- utils::capture.output(renv::restore(library = lib, lockfile = lock))
  cat("::endgroup::\n")

  # Detect any new packages that entered the lesson --------------------
  cat("::group::Discovering new packages\n")
  hydra       <- renv::hydrate(library = lib, update = FALSE)
  new_lock    <- renv::snapshot(library = lib, lockfile = lock)
  sneaky_pkgs <- setdiff(names(new_lock$Packages), names(current_lock$Packages))
  if (length(sneaky_pkgs)) {
    these <- new_lock$Packages[sneaky_pkgs]
    pkg_info <- function(i) {
      lead <- "- "
      paste0(lead, i$Package, '\t[* -> ', i$Version, ']')
    }
    pkgs <- vapply(these, FUN = pkg_info, FUN.VALUE = character(1))
    if (on_linux) {
      ci_sysreqs(lock, execute = TRUE)
    }
    n <- n + length(sneaky_pkgs)
    the_report <- c(the_report, 
      "# NEW ================================",
      pkgs,
      ""
    )
    cat(n, "packages found", paste(sneaky_pkgs, collapse = ", "), "\n")
  }
  cat("::endgroup::\n")
  # Check for updates to packages --------------------------------------
  should_update <- as.logical(toupper(update))
  if (should_update) {
    cat("::group::Applying Updates\n")
    updates <- renv::update(library = lib, check = TRUE)
    updates_needed <- !identical(updates, TRUE)
  } else {
    updates_needed <- FALSE
  }
  if (updates_needed) {
    # apply the updates and run a snapshot if the dry run found updates
    renv::update(library = lib)
    renv::snapshot(lockfile = lock)
    n <- n + length(updates$diff)
    the_report <- c(the_report, 
      utils::capture.output(print(updates), type = "message"))
    cat("Updating", length(updates$diff), "packages", "\n")
    cat("::endgroup::\n")
  }
  cat("::group::Cleaning the cache\n")
  renv::clean(actions = c('package.locks', 'library.tempdirs', 'unused.packages'))
  cat("::endgroup::\n")
  # Construct the output -----------------------------------------------
  # https://github.community/t/set-output-truncates-multiline-strings/16852/3?u=zkamvar
  cat("::group::Creating the output\n")
  the_report <- paste0(the_report, collapse = "%0A")
  meow  <- function(...) cat(..., "\n", sep = "")
  meow(the_report)
  meow("::set-output name=report::", the_report)
  meow("::set-output name=n::", n)
  meow("::set-output name=date::", as.character(Sys.Date()))
  cat("::endgroup::\n")
}
