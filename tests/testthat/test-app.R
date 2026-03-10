test_that("run_featuremsea_app returns a shiny app", {
  skip_if_not_installed("shiny")

  # Test that the function exists and returns something
  expect_true(exists("run_featuremsea_app"))

  # Test that it returns a shiny app object (basic check)
  app <- run_featuremsea_app()
  expect_true("shiny.appobj" %in% class(app))
})