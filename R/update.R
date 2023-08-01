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
ci_update <- function(profile = 'lesson-requirements', update = 'true', repos = NULL) {

  n <- 0
  the_report <- character(0)
  cat("::group::Restoring package library\n")
  Sys.setenv("RENV_PROFILE" = profile)
  lib  <- renv::paths$library()
  lock <- renv::paths$lockfile()
  current_lock <- get_lockfile(lock)
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
  hydra <- renv::hydrate(library = lib, update = FALSE)
  # if there are errors here, it might be because we did not account for them
  # when enumerating the system requirements. This accounts for that by 
  # attempting the sysreqs installation and then re-trying the hydration
  if (length(hydra$missing) && on_linux) { 
    cat("Some packages failed installation... attempting to find system requirements\n")
    ci_new_pkgs_sysreqs(hydra$missing)
    hydra <- renv::hydrate(library = lib, update = FALSE)
  }
  # The first snapshot captures the packages that were added during hydrate and
  # it will also capture the packages that were removed in the prose
  snap_report <- utils::capture.output(new_lock <- renv::snapshot(library = lib, lockfile = lock))
  snap_report <- snap_report[startsWith(trimws(snap_report), "-")]

  sneaky_pkgs <- setdiff(names(new_lock$Packages), names(current_lock$Packages))
  have_new_pkgs <- length(sneaky_pkgs)
  removed_some_pkgs <- length(head(snap_report, -1L))
  # When we are on linux, we have to make sure to install the system
  # requirements for any new packages that come along
  if (on_linux && have_new_pkgs) {
    ci_sysreqs(lock, execute = TRUE)
  }
  if (have_new_pkgs || removed_some_pkgs) {
    n <- n + length(sneaky_pkgs)
    the_report <- c(the_report, 
      "# NEW OR REMOVED PACKAGES -------------------------------",
      head(snap_report, -1L), # to get rid of lockfile report
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
    # The update report has some noise from the snapshot, so we need to clean
    # it up by removing the header (that starts before the `# CRAN` signifier)
    # and the footer that starts with ` - Lockfile written to`
    update_report <- utils::capture.output(renv::snapshot(lockfile = lock))
    header <- which(startsWith(trimws(update_report), "#"))
    if (length(header)) {
      header <- seq(min(header) - 1L)
    }
    footer <- seq(which(startsWith(trimws(update_report), "- Lockfile")),
      length(update_report))
    update_report <- update_report[-c(header, footer)]

    # We can detect the number of updated packages via checking the number of
    # ticks the output has. This is crude, but the updates from 
    # renv::update(check = TRUE) no longer gives us an accurate count because
    # it also counts packages that were accidentally inserted.
    n_updates <- sum(startsWith(trimws(update_report), "-"))
    n <- n + n_updates
    the_report <- c(the_report, update_report)
    cat("Updating", n_updates, "packages", "\n")
    cat("::endgroup::\n")
  }
  cat("::group::Cleaning the cache\n")
  renv::clean(actions = c('package.locks', 'library.tempdirs', 'unused.packages'))
  cat("::endgroup::\n")
  # Construct the output -----------------------------------------------
  cat("::group::Creating the output\n")
  meow("report", the_report)
  meow("n", n)
  meow("date", as.character(Sys.Date()))
  cat("::endgroup::\n")
}
