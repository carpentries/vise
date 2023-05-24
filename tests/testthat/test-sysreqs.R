test_that("ci_sysreqs will detect the requirements for a knitr lockfile", {
  skip_if_offline()
  skip_on_os("windows")
  skip_on_os("mac")
  on_ubuntu <- grepl("ubuntu", system("lsb_release -irs", intern = TRUE)[[1]], ignore.case = TRUE)
  skip_if_not(on_ubuntu)
  lock <- system.file("renv.lock", package = "vise")
  # The system requirements for a typical {knitr} installation
  res <- vise::ci_sysreqs(lock, execute = FALSE)
  expect_match(res, "apt-get install")
  expect_match(res, "libicu-dev")
})


test_that("ci_sysreqs will skip reqs if requested", {
  skip_if_offline()
  on_ubuntu <- grepl("ubuntu", system("lsb_release -irs", intern = TRUE)[[1]], ignore.case = TRUE)
  skip_if_not(on_ubuntu)
  lock <- system.file("renv.lock", package = "vise")
  # The system requirements for a typical {knitr} installation
  res <- vise::ci_sysreqs(lock, execute = FALSE, exclude = c("git", "pandoc", "make", "libicu-dev"))
  expect_length(res, 0)
})
