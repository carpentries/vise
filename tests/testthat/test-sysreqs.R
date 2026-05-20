test_that("ci_sysreqs will detect the requirements for a knitr lockfile", {
  skip_if_offline()
  skip_on_os("windows")
  skip_on_os("mac")
  on_ubuntu <- grepl("ubuntu", system("lsb_release -irs", intern = TRUE)[[1]], ignore.case = TRUE)
  skip_if_not(on_ubuntu)
  lock <- system.file("renv.lock", package = "vise")

  use_pak = FALSE

  # The system requirements for a typical {knitr} installation
  res <- vise::ci_sysreqs(lock, execute = FALSE, use_pak = use_pak)

  if (use_pak) {
    if (length(res$packages$system_packages) == 0) {
      skip("libicu-dev already installed")
    }
  }
  expect_length(res$install_scripts, 3)
  expect_match(res$install_scripts[3], "apt-get -y install libicu-dev")
})

test_that("test missing packages", {
  skip_if_offline()
  skip_on_os("windows")
  skip_on_os("mac")
  on_ubuntu <- grepl("ubuntu", system("lsb_release -irs", intern = TRUE)[[1]], ignore.case = TRUE)
  skip_if_not(on_ubuntu)
  lock <- system.file("renv.lock", package = "vise")

  use_pak = FALSE

  missing <- list(
    list(package = "knitr"),
    list(package = "rmarkdown")
  )
  res <- vise::ci_new_pkgs_sysreqs(missing, execute = FALSE, exclude = c("git", "libicu-dev"), use_pak = use_pak)

  if (use_pak) {
    expect_length(res$packages$system_packages, 4)
  } else {
    expect_length(res$install_scripts, 4)
  }
})

test_that("test exclude packages", {
  skip_if_offline()
  skip_on_os("windows")
  skip_on_os("mac")
  on_ubuntu <- grepl("ubuntu", system("lsb_release -irs", intern = TRUE)[[1]], ignore.case = TRUE)
  skip_if_not(on_ubuntu)
  lock <- system.file("renv.lock", package = "vise")

  use_pak = FALSE

  missing <- list(
    list(package = "knitr"),
    list(package = "rmarkdown")
  )
  res <- vise::ci_new_pkgs_sysreqs(missing, execute = FALSE, exclude = c("git", "make", "pandoc", "libicu-dev"), use_pak = use_pak)

  if (use_pak) {
    expect_length(res$packages$system_packages, 2)
  } else {
    expect_length(res$install_scripts, 2)
  }

  res <- vise::ci_new_pkgs_sysreqs(missing, execute = FALSE, exclude = c("git", "cmake","make", "pandoc", "libicu-dev", "libuv1-dev"), use_pak = use_pak)

  if (use_pak) {
    expect_length(res$packages$system_packages, 0)
  } else {
    expect_length(res$install_scripts, 0)
  }
})
