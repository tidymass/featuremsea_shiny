#' Run featureMSEA Shiny Application
#'
#' This function launches the featureMSEA Shiny application for interactive
#' metabolite set enrichment analysis.
#'
#' @param ... Additional arguments passed to shiny::shinyApp
#'
#' @return A Shiny app object
#' @export
#'
#' @examples
#' \dontrun{
#' run_featuremsea_app()
#' }
run_featuremsea_app <- function(...) {
  # Define available volumes for file selection
  volumes <- c(
    "Home" = fs::path_home(),
    "Working Directory" = getwd()
  )

  # Add additional common directories if they exist
  if (.Platform$OS.type == "unix") {
    if (dir.exists("/Users")) {
      volumes <- c(volumes, "Users" = "/Users")
    }
    if (dir.exists("/Volumes")) {
      volumes <- c(volumes, "Volumes" = "/Volumes")
    }
  } else if (.Platform$OS.type == "windows") {
    drives <- paste0(LETTERS[1:6], ":")
    existing_drives <- drives[file.exists(drives)]
    names(existing_drives) <- paste("Drive", existing_drives)
    volumes <- c(volumes, existing_drives)
  }

  # Create the UI
  ui <- bslib::page_navbar(
    title = "featureMSEA",
    theme = bslib::bs_theme(version = 5, bootswatch = "flatly"),

    # Introduction Tab
    bslib::nav_panel(
      title = "Introduction",
      icon = bsicons::bs_icon("info-circle"),

      div(class = "container-fluid",
        style = "padding-top: 20px;",

        div(class = "row",
          div(class = "col-12",
            bslib::card(
              bslib::card_header(
                h2("Welcome to featureMSEA", class = "text-primary")
              ),
              bslib::card_body(
                div(
                  h4("Feature-based Metabolite Set Enrichment Analysis"),

                  p("featureMSEA is a powerful tool for performing feature-based metabolite set
                    enrichment analysis on untargeted metabolomics data. This application provides
                    an intuitive interface for:"),

                  tags$ul(
                    tags$li("Automated metabolite annotation using MS1 databases"),
                    tags$li("Pathway enrichment analysis using multiple pathway databases"),
                    tags$li("LLM-based pathway relevance evaluation"),
                    tags$li("Interactive visualization and result exploration")
                  ),

                  br(),

                  h5("Key Features:", class = "text-info"),

                  div(class = "row",
                    div(class = "col-md-4",
                      bslib::card(
                        bslib::card_header("Step 1: Annotation", class = "bg-light"),
                        bslib::card_body(
                          p("Automatically annotate metabolic features using KEGG or HMDB databases
                            with customizable mass and retention time tolerances.")
                        )
                      )
                    ),
                    div(class = "col-md-4",
                      bslib::card(
                        bslib::card_header("Step 2: Enrichment", class = "bg-light"),
                        bslib::card_body(
                          p("Perform pathway enrichment analysis using various pathway databases
                            including KEGG, Reactome, HMDB, and WikiPathways.")
                        )
                      )
                    ),
                    div(class = "col-md-4",
                      bslib::card(
                        bslib::card_header("Step 3: AI Evaluation", class = "bg-light"),
                        bslib::card_body(
                          p("Leverage large language models to evaluate pathway relevance
                            based on sample matrix and research context.")
                        )
                      )
                    )
                  ),

                  br(),

                  div(class = "alert alert-info",
                    h6("Getting Started:", class = "alert-heading"),
                    p("Navigate to the 'fMSEA Analysis' tab to begin your analysis.
                      Make sure you have prepared your feature table (CSV or RDA format)
                      before starting the analysis.", class = "mb-0")
                  ),

                  br(),

                  div(class = "text-center",
                    bslib::input_action_button(
                      "start_analysis",
                      "Start Analysis",
                      class = "btn-primary btn-lg",
                      onclick = "$(\"a[data-value='fMSEA Analysis']\").click();"
                    )
                  )
                )
              )
            )
          )
        )
      )
    ),

    # fMSEA Analysis Tab
    fmsea_ui("fmsea"),

    # About Tab
    bslib::nav_panel(
      title = "About",
      icon = bsicons::bs_icon("people"),

      div(class = "container-fluid",
        style = "padding-top: 20px;",

        div(class = "row",
          div(class = "col-md-8 offset-md-2",
            bslib::card(
              bslib::card_header(
                h2("About featureMSEA", class = "text-primary")
              ),
              bslib::card_body(

                h4("Development Team", class = "text-info"),

                div(class = "row mb-4",
                  div(class = "col-md-6",
                    bslib::card(
                      bslib::card_body(
                        div(class = "text-center",
                          # Placeholder avatar
                          div(
                            style = "width: 120px; height: 120px; background-color: #007bff;
                                   border-radius: 50%; margin: 0 auto 15px auto;
                                   display: flex; align-items: center; justify-content: center;",
                            h1("YL", style = "color: white; margin: 0;")
                          ),
                          h5("Yijiang Liu", class = "text-primary"),
                          p(class = "text-muted", "Lead Developer"),
                          p("Lead developer of this Shiny application. Yijiang specializes in
                            bioinformatics and interactive data visualization for metabolomics analysis.")
                        )
                      )
                    )
                  ),
                  div(class = "col-md-6",
                    bslib::card(
                      bslib::card_body(
                        div(class = "text-center",
                          # Placeholder avatar
                          div(
                            style = "width: 120px; height: 120px; background-color: #28a745;
                                   border-radius: 50%; margin: 0 auto 15px auto;
                                   display: flex; align-items: center; justify-content: center;",
                            h1("XS", style = "color: white; margin: 0;")
                          ),
                          h5("Dr. Xiaotao Shen", class = "text-success"),
                          p(class = "text-muted", "Algorithm Developer"),
                          p("Developer of the featureMSEA algorithm. Dr. Shen specializes in
                            computational metabolomics and systems biology research.")
                        )
                      )
                    )
                  )
                ),

                br(),

                h4("Contact & Support", class = "text-info"),

                div(class = "row",
                  div(class = "col-md-6",
                    h6("GitHub Repository:"),
                    p(tags$a("https://github.com/tidymass/featuremsea_shiny",
                            href = "https://github.com/tidymass/featuremsea_shiny",
                            target = "_blank"))
                  ),
                  div(class = "col-md-6",
                    h6("Email Support:"),
                    p(tags$a("ejoliu@outlook.com",
                            href = "mailto:ejoliu@outlook.com"))
                  )
                ),

                br(),

                div(class = "alert alert-info",
                  h6("Acknowledgments:", class = "alert-heading"),
                  p("We thank the metabolomics community for their valuable feedback and
                    contributions to the development of this tool. Special thanks to all
                    beta testers who helped improve the user experience.", class = "mb-0")
                )
              )
            )
          )
        )
      )
    )
  )

  # Create the server
  server <- function(input, output, session) {
    fmsea_server("fmsea", volumes = volumes)
  }

  # Create and run the app
  app <- shiny::shinyApp(ui = ui, server = server, ...)
  return(app)
}