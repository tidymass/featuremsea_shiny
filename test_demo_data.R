# Test Demo Data Functionality
# This script tests the demo data feature in featureMSEA app

library(featuremseashiny)

cat("=== Testing Demo Data Functionality ===\n")

# Test 1: Check demo data files exist
demo_rda_path <- system.file('demo_data', 'feature_table.rda', package = 'featuremseashiny')
demo_csv_path <- system.file('demo_data', 'feature_table.csv', package = 'featuremseashiny')

cat("Demo RDA path:", demo_rda_path, "\n")
cat("Demo CSV path:", demo_csv_path, "\n")
cat("RDA exists:", file.exists(demo_rda_path), "\n")
cat("CSV exists:", file.exists(demo_csv_path), "\n")

# Test 2: Test loading demo data
if (file.exists(demo_rda_path)) {
  cat("\n=== Loading Demo RDA Data ===\n")
  env <- new.env()
  name <- load(demo_rda_path, envir = env)
  demo_data <- get(name, envir = env)
  cat("Demo data loaded successfully!\n")
  cat("Data dimensions:", nrow(demo_data), "x", ncol(demo_data), "\n")
  cat("Column names:", paste(head(colnames(demo_data), 5), collapse = ", "), "...\n")
}

# Test 3: Test app creation
cat("\n=== Testing App Creation ===\n")
app <- run_featuremsea_app()
cat("App object created successfully!\n")
cat("App class:", class(app), "\n")

cat("\n=== All Tests Completed Successfully! ===\n")
cat("You can now run run_featuremsea_app() to launch the app with demo data functionality.\n")