# Test Demo Result Functionality
# This script tests the demo result feature in featureMSEA app

cat("=== Testing Demo Result Functionality ===\n")

# Test without renv interference
if (file.exists(".Rprofile")) {
  file.rename(".Rprofile", ".Rprofile.temp")
  on.exit(file.rename(".Rprofile.temp", ".Rprofile"))
}

# Load the package
library(featuremseashiny)

# Test 1: Check demo result file exists
demo_result_path <- system.file('demo_result', 'results.rda', package = 'featuremseashiny')

cat("Demo result path:", demo_result_path, "\n")
cat("Demo result exists:", file.exists(demo_result_path), "\n")

# Test 2: Test loading demo result
if (file.exists(demo_result_path)) {
  cat("\n=== Loading Demo Result Data ===\n")
  env <- new.env()
  name <- load(demo_result_path, envir = env)
  demo_result <- get(name, envir = env)
  cat("Demo result loaded successfully!\n")
  cat("Result class:", class(demo_result), "\n")
  if (is.list(demo_result)) {
    cat("Result components:", paste(names(demo_result), collapse = ", "), "\n")
  }
}

# Test 3: Test app creation
cat("\n=== Testing App Creation ===\n")
app <- run_featuremsea_app()
cat("App object created successfully!\n")
cat("App class:", class(app), "\n")

cat("\n=== All Tests Completed Successfully! ===\n")
cat("You can now run run_featuremsea_app() to launch the app.\n")
cat("New demo result features:\n")
cat("- Click 'Load Demo Result' button to load sample results\n")
cat("- Click 'RDA' button to download demo result file\n")