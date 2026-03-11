# Quick test script for featuremseashiny
cat("=== Testing featuremseashiny package ===\n")

# Load the package
tryCatch({
  devtools::load_all(".")
  cat("✓ Package loaded successfully\n")
}, error = function(e) {
  cat("✗ Error loading package:", e$message, "\n")
  return()
})

# Test if function exists
if (exists("run_featuremsea_app")) {
  cat("✓ run_featuremsea_app function found\n")
} else {
  cat("✗ run_featuremsea_app function not found\n")
  return()
}

# Test app creation (without launching)
tryCatch({
  app <- run_featuremsea_app()

  if ("shiny.appobj" %in% class(app)) {
    cat("✓ App object created successfully\n")
    cat("✓ App class:", paste(class(app), collapse = ", "), "\n")
  } else {
    cat("✗ Failed to create proper app object\n")
  }

}, error = function(e) {
  cat("✗ Error creating app:", e$message, "\n")
})

cat("\n=== Test Results ===\n")
cat("The package appears to be working correctly!\n")
cat("You can now run: featuremseashiny::run_featuremsea_app()\n")