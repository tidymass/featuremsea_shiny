# Test script for featuremseashiny package
# This script tests basic functionality of the package

# Try to load and test the package
tryCatch({
  # Load the package from source
  devtools::load_all(".")

  cat("✓ Package loaded successfully\n")

  # Test if the main function exists
  if (exists("run_featuremsea_app")) {
    cat("✓ run_featuremsea_app function exists\n")
  } else {
    cat("✗ run_featuremsea_app function not found\n")
  }

  # Test if we can create the app object (without launching)
  app <- run_featuremsea_app()
  if ("shiny.appobj" %in% class(app)) {
    cat("✓ App object created successfully\n")
  } else {
    cat("✗ Failed to create app object\n")
  }

  cat("\n=== Package structure ===\n")
  list.files(".", recursive = TRUE, pattern = "\\.(R|Rd)$")

}, error = function(e) {
  cat("✗ Error loading package:", e$message, "\n")
})

cat("\n=== Next Steps ===\n")
cat("1. Install required dependencies:\n")
cat("   # Install remotes if not available\n")
cat("   if (!requireNamespace('remotes', quietly = TRUE)) {\n")
cat("     install.packages('remotes')\n")
cat("   }\n")
cat("   # Install GitHub packages\n")
cat("   remotes::install_github('tidymass/featuremsea')\n")
cat("   remotes::install_github('tidymass/fmseadatabase')\n")
cat("2. Build and install the package:\n")
cat("   devtools::install()\n")
cat("3. Test the app:\n")
cat("   featuremseashiny::run_featuremsea_app()\n")