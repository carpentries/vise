#nocov start
get_lockfile <- function(...) {
  if (packageVersion("renv") >= "1.0.0") {
    renv::lockfile_read(...)
  } else {
    asNamespace("renv")$lockfile(...)$data()
  }
}
#nocov enc
