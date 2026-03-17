# Quick test for the fixed demo data functionality
# Run this in RStudio or R console to test

cat("Testing featureMSEA app with demo data...\n")

# Load the package
library(featuremseashiny)

# Test demo data path
demo_path <- system.file('demo_data', 'feature_table.rda', package = 'featuremseashiny')
cat("Demo data available:", file.exists(demo_path), "\n")

# Create app object (don't run, just create)
app <- run_featuremsea_app()
cat("App object created successfully!\n")
cat("Class:", class(app), "\n")

cat("\n=== Instructions ===\n")
cat("1. The showNotification error has been fixed\n")
cat("2. Package conflicts should be resolved\n")
cat("3. You can now run: run_featuremsea_app()\n")
cat("4. Click 'Load Demo Data' button to test the new functionality\n")
cat("5. Click 'CSV' or 'RDA' buttons to download demo files\n")