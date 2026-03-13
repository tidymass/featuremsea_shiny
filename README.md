# featuremseashiny

[![R](https://img.shields.io/badge/R-%3E%3D4.0.0-blue)](https://www.r-project.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A Shiny application for performing feature-based metabolite set enrichment analysis (fMSEA) on metabolomics data.

## Overview

`featuremseashiny` provides an interactive web interface for conducting comprehensive metabolomics pathway enrichment analysis. The application combines automated metabolite annotation, pathway enrichment analysis, and AI-powered pathway evaluation to deliver insights from untargeted metabolomics data.

## Features

- **Interactive Data Upload**: Support for CSV and RDA file formats
- **Multi-Database Support**: Integration with KEGG, HMDB, Reactome, and other pathway databases
- **Three-Step Analysis Workflow**:
  1. **Annotation**: Automated metabolite annotation with customizable parameters
  2. **Enrichment**: Pathway enrichment analysis using fMSEA algorithm
  3. **AI Evaluation**: Optional LLM-based pathway relevance assessment
- **Visualization**: Interactive plots and downloadable results
- **Flexible Parameters**: Customizable analysis parameters for different experimental setups

## Installation

You can install the development version from GitHub:

```r
# Install devtools if you haven't already
if (!requireNamespace("devtools", quietly = TRUE)) {
  install.packages("devtools")
}

# Install featuremseashiny
remotes::install_github("tidymass/featuremsea_shiny")
```

### Dependencies

The package requires the following core dependencies:

- `featuremsea`: Core fMSEA algorithm implementation
- `fmseadatabase`: Metabolite and pathway databases (install via GitHub)
- `shiny`: Web application framework
- `bslib`: Modern UI components
- `DT`: Interactive data tables

Install the required packages:

```r
# Install CRAN packages
install.packages(c("shiny", "bslib", "DT", "shinyFiles", "bsicons", "ggplot2", "patchwork", "fs"))

# Install GitHub packages
if (!requireNamespace("remotes", quietly = TRUE)) {
  install.packages("remotes")
}
remotes::install_github("tidymass/featuremsea")
remotes::install_github("tidymass/fmseadatabase")
```

## Usage

### Quick Start

Launch the application with a single command:

```r
library(featuremseashiny)

# Launch the Shiny app
run_featuremsea_app()
```

### Analysis Workflow

1. **Data Preparation**: Prepare your feature table in CSV or RDA format
2. **Upload Data**: Use the interface to upload your feature table
3. **Configure Parameters**: Set analysis parameters for your specific experiment
4. **Run Analysis**: Execute the three-step analysis workflow
5. **Explore Results**: Visualize and download analysis results

### Input Data Format

Your feature table should contain at least:

- Feature identifiers
- Mass-to-charge ratios (m/z)
- Retention times
- Intensity or abundance data

## Example

```r
# Load the package
library(featuremseashiny)

# Launch the application
run_featuremsea_app()

# The app will open in your default web browser
# Navigate through the tabs to perform your analysis
```

## Documentation

For detailed usage instructions and examples, visit the application and check the "Introduction" tab for a comprehensive guide.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Related Projects

- [tidymass](https://github.com/tidymass/tidymass): Comprehensive metabolomics data analysis
- [featuremsea](https://github.com/tidymass/featuremsea): Core fMSEA algorithm
- [fmseadatabase](https://github.com/tidymass/fmseadatabase): Metabolomics databases