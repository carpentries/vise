test_that("unsimple vectors will throw errors", {

  skip_on_ci()
  expect_error(vise::verify_simple_vector(inputs = c(print("a"))), "repository settings should be an R vector")
  expect_error(vise::verify_simple_vector(inputs = c(stop("a"))), "repository settings should be an R vector")
  expect_error(vise::verify_simple_vector(inputs = c(system("lsb_release -a", intern = TRUE))), "repository settings should be an R vector")

})


test_that("nested vectors are okay", {
  expect_null(vise::verify_simple_vector(inputs = c("a", "b", c("c"))))
  expect_null(vise::verify_simple_vector(inputs = c(TRUE, FALSE, c(TRUE))))
  expect_null(vise::verify_simple_vector(inputs = c(1, 2, c(3))))
})

test_that("named vectors are okay", {
  expect_null(vise::verify_simple_vector(inputs = c("a", "b", c(a = "c"))))
  expect_null(vise::verify_simple_vector(inputs = c(TRUE, FALSE, c(a = TRUE))))
  expect_null(vise::verify_simple_vector(inputs = c(1, 2, c(a = 3))))
})

