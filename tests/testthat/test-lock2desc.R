
lock <- system.file("renv.lock", package = "vise")

test_that("a DESCRIPTION file can be temporarily created", {

  res <- lock2desc(lock)
  expect_true(file.exists(res))
  expect_match(basename(res), "DESCRIPTION")
  expect_success(expect_s3_class(desc <- desc::description$new(res), "description"))
  this_lock <- asNamespace("renv")$lockfile(lock)
  expect_setequal(names(this_lock$data()$Packages), desc$get_deps()$package)

})

test_that("a new DESCRIPTION file can be created", {

  tmp <- withr::local_tempdir()
  expect_true(dir.exists(tmp))
  expect_false(file.exists(file.path(tmp, "DESCRIPTION")))
  res <- lock2desc(lock, file.path(tmp, "DESCRIPTION"))
  expect_true(file.exists(res))
  expect_match(basename(res), "DESCRIPTION")
  expect_success(expect_s3_class(desc <- desc::description$new(res), "description"))
  this_lock <- asNamespace("renv")$lockfile(lock)
  expect_setequal(names(this_lock$data()$Packages), desc$get_deps()$package)

})
