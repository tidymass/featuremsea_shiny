# Test plotting functionality after fixes
cat("=== Testing featuremseashiny plotting fixes ===\n")

# Load the package
tryCatch({
  devtools::load_all(".")
  cat("✓ Package loaded successfully\n")
}, error = function(e) {
  cat("✗ Error loading package:", e$message, "\n")
  return()
})

# Check if patchwork is available
if (requireNamespace("patchwork", quietly = TRUE)) {
  cat("✓ patchwork package is available\n")
} else {
  cat("⚠ patchwork package is not installed\n")
  cat("  Install with: install.packages('patchwork')\n")
}

# Check if ggplot2 functions are available
required_ggplot_funcs <- c("ggplot", "annotate", "theme_minimal", "theme", "element_blank", "labs")
missing_funcs <- c()

for (func in required_ggplot_funcs) {
  if (!exists(func, where = asNamespace("ggplot2"))) {
    missing_funcs <- c(missing_funcs, func)
  }
}

if (length(missing_funcs) == 0) {
  cat("✓ All required ggplot2 functions are available\n")
} else {
  cat("⚠ Missing ggplot2 functions:", paste(missing_funcs, collapse = ", "), "\n")
}

# Test app creation
tryCatch({
  app <- run_featuremsea_app()
  cat("✓ App object created successfully\n")
}, error = function(e) {
  cat("✗ Error creating app:", e$message, "\n")
})

cat("\n=== Recommendations ===\n")
cat("1. Make sure to install patchwork: install.packages('patchwork')\n")
cat("2. The plotting error should now be handled gracefully\n")
cat("3. If plotting still fails, an error message will be displayed instead of crashing\n")

cat("\n=== Next Steps ===\n")
cat("Try running the app again and clicking on a significant module\n")
cat("featuremseashiny::run_featuremsea_app()\n")