#' convert a lockfile to a description file
#'
#' @param lockfile the path to the renv lockfile
#' @param desc the path to the new description file
#' @return desc
#'
#' @export
#' @examples
#' lock <- system.file("renv.lock", package = "vise")
#' lock2desc(lock)
lock2desc <- function(lockfile, desc = tempfile()) {
  if (!requireNamespace("desc", quietly = TRUE)) {
    stop("The {desc} package is required for this function")
  }
  if (basename(desc) != "DESCRIPTION" && !file.exists(desc)) {
    # if we have a tempfile, we need to create it
    dir.create(desc)
    out <- file.path(desc, "DESCRIPTION")
  } else {
    out <- desc
  }
  lock <- asNamespace("renv")$lockfile(lockfile)
  dat <- lock$data()$Packages
  pkg <- names(dat)
  versions <- paste("==", vapply(dat, function(p) p$Version, character(1)))
  deps <- data.frame(type = "Imports", package = pkg, version = versions)
  d <- desc::description$new("!new")
  d$set_deps(deps)
  d$write(file = out)
  out
}
