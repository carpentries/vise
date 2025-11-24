test_that("ci_sysreqs will detect the requirements for a knitr lockfile", {
  skip_if_offline()
  skip_on_os("windows")
  skip_on_os("mac")
  on_ubuntu <- grepl("ubuntu", system("lsb_release -irs", intern = TRUE)[[1]], ignore.case = TRUE)
  skip_if_not(on_ubuntu)
  lock <- system.file("renv.lock", package = "vise")
  # The system requirements for a typical {knitr} installation
  res <- vise::ci_sysreqs(lock, execute = FALSE)
  if (length(res$packages$system_packages) == 0) {
    skip("libicu-dev already installed")
  }
  expect_match(res$install_scripts, "apt-get -y install libicu-dev")
})

test_that("test missing packages", {
  skip_if_offline()
  skip_on_os("windows")
  skip_on_os("mac")
  on_ubuntu <- grepl("ubuntu", system("lsb_release -irs", intern = TRUE)[[1]], ignore.case = TRUE)
  skip_if_not(on_ubuntu)
  lock <- system.file("renv.lock", package = "vise")

  missing <- list(
    list(package = "knitr"),
    list(package = "rmarkdown")
  )
  res <- vise::ci_new_pkgs_sysreqs(missing, execute = FALSE, exclude = c("git", "libicu-dev"))
  expect_length(res$packages$system_packages, 2)
})

test_that("test exclude packages", {
  skip_if_offline()
  skip_on_os("windows")
  skip_on_os("mac")
  on_ubuntu <- grepl("ubuntu", system("lsb_release -irs", intern = TRUE)[[1]], ignore.case = TRUE)
  skip_if_not(on_ubuntu)
  lock <- system.file("renv.lock", package = "vise")

  missing <- list(
    list(package = "knitr"),
    list(package = "rmarkdown")
  )
  res <- vise::ci_new_pkgs_sysreqs(missing, execute = FALSE, exclude = c("git", "make", "pandoc", "libicu-dev"))
  expect_length(res$packages$system_packages, 0)
})
