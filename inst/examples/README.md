# Example Data

This directory can contain example datasets for testing the featureMSEA application.

## Expected Format

### Feature Table Format

Your feature table should be in CSV format with the following columns:

- **feature_id**: Unique identifier for each feature
- **mz**: Mass-to-charge ratio
- **rt**: Retention time (in seconds)
- **intensity**: Feature intensity or abundance
- Additional sample columns as needed

### Example CSV Structure

```csv
feature_id,mz,rt,intensity_sample1,intensity_sample2,intensity_sample3
M001,100.0523,120.5,15678.2,23456.8,19876.5
M002,150.0876,245.8,8765.1,12345.6,9876.4
M003,200.1234,380.2,45678.9,34567.8,39876.2
```

## Usage in Application

1. Prepare your data in the format described above
2. Launch the application with `featuremseashiny::run_featuremsea_app()`
3. Navigate to the "fMSEA Analysis" tab
4. Upload your CSV or RDA file using the file selector
5. Configure analysis parameters
6. Run the three-step analysis workflow

## Database Requirements

Make sure you have the required database packages installed:

```r
# Install required packages
if (!requireNamespace("remotes", quietly = TRUE)) {
  install.packages("remotes")
}

# Install from GitHub
remotes::install_github("tidymass/featuremsea")
remotes::install_github("tidymass/fmseadatabase")
```

The application supports multiple databases:
- KEGG compound MS1 database
- HMDB compound MS1 database
- Various pathway databases (KEGG, Reactome, HMDB, etc.)