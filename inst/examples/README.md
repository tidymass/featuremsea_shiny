# Example Data

This directory can contain example datasets for testing the featureMSEA application.

## Expected Format

### Feature Table Format

Your feature table should be in CSV or RDA format with the following columns:

- **variable_id**: Unique identifier for each feature
- **mz**: Mass-to-charge ratio
- **rt**: Retention time (in seconds)
- **ranking_statistic**: Phenotype-associated ranking statistic, i.e., an effect-size measure such as signal-to-noise ratio (SNR), fold change (log2FC) or correlation coefficient (r). It can be signed or absolute; features are ranked in descending order by its absolute value, and the sign, if provided, is only used to indicate direction in the enrichment plots. A column named `condition` (the name used in earlier versions) is still accepted.
- **polarity**: Ionization mode, either `"positive"` or `"negative"`
- **mean_intensity**: Average feature intensity across all samples

### Example CSV Structure

```csv
variable_id,mz,rt,ranking_statistic,polarity,mean_intensity
M71T824_POS,70.98033666,823.5647888,0.013196571,positive,188792051.4
M72T823_POS,71.98741136,823.2585144,0.042634569,positive,15481940.67
M72T34_POS,72.08081529,33.85064888,-0.086349183,positive,4751415.57
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
# Install CRAN packages
install.packages(c("shiny", "bslib", "DT", "shinyFiles", "bsicons", "ggplot2", "patchwork", "fs"))

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