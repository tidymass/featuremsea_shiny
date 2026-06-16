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
  # Configure a parallel backend ONCE per R process. The annotation step
  # (featuremsea::annotate_feature_table) reuses whatever plan is active, so
  # setting it here means workers are persistent across requests instead of
  # being spawned on every call. Only set it when the deployer hasn't already
  # chosen a plan (default is sequential), so an explicit plan in app.R wins.
  # On a Linux/macOS Shiny server, multicore (fork) avoids the process-startup
  # and data-serialization overhead of multisession; supportsMulticore() is
  # FALSE on Windows/RStudio, where we fall back to multisession.
  if (inherits(future::plan(), "sequential")) {
    n_workers <- max(1, future::availableCores() - 1)
    if (future::supportsMulticore()) {
      future::plan(future::multicore, workers = n_workers)
    } else {
      future::plan(future::multisession, workers = n_workers)
    }
  }

  # File upload is now handled by fileInput() - no need for volumes

  # Serve static assets (logo, etc.) from inst/www
  www_path <- system.file("www", package = "featuremseashiny")
  if (!nzchar(www_path) || !dir.exists(www_path)) {
    www_path <- file.path(getwd(), "inst", "www")
  }
  if (dir.exists(www_path)) {
    shiny::addResourcePath("www", www_path)
  }

  # Create the UI
  ui <- bslib::page_navbar(
    header = tags$head(
      tags$link(rel = "icon", type = "image/png", href = "www/logo.png"),
      tags$style(HTML("
        .navbar { align-items: center; }
        .navbar-nav { align-self: center; }
        .navbar-nav .nav-link { display: flex; align-items: center; height: 100%; }
      "))
    ),
    title = tags$span(
      tags$img(
        src = "www/logo.png",
        height = "80px",
        style = "margin-right: 8px; vertical-align: middle;"
      ),
      "featureMSEA"
    ),
    theme = bslib::bs_theme(version = 5, bootswatch = "flatly"),

    # Introduction Tab
    bslib::nav_panel(
      title = "Introduction",
      icon = bsicons::bs_icon("info-circle"),

      tags$style(HTML("
        .intro-step-card {
          border: none;
          border-radius: 12px;
          box-shadow: 0 4px 16px rgba(44,62,80,0.09);
          height: 100%;
        }
        .intro-step-card .step-number {
          width: 40px; height: 40px;
          border-radius: 50%;
          display: flex; align-items: center; justify-content: center;
          font-size: 1.1rem; font-weight: 700; color: white;
          margin: 0 auto 14px auto;
        }
        .highlight-box {
          border-left: 4px solid #18BC9C;
          background: #f4fdf9;
          border-radius: 0 8px 8px 0;
          padding: 14px 18px;
        }
      ")),

      div(class = "container-fluid", style = "padding: 30px 40px;",

        # Hero
        div(
          style = "background: linear-gradient(135deg, #2C3E50 0%, #18BC9C 100%);
                   border-radius: 14px; padding: 40px 48px; margin-bottom: 32px; color: white;",
          div(class = "row align-items-center",
            div(class = "col-md-8",
              h1("featureMSEA", style = "font-weight: 800; font-size: 2.4rem; margin-bottom: 10px;"),
              h5("Feature-based Metabolite Set Enrichment Analysis",
                 style = "font-weight: 400; opacity: 0.9; margin-bottom: 16px;"),
              p("FeatureMSEA performs metabolite set enrichment directly from LC-MS metabolic
                features without requiring confident metabolite identification. By extracting
                metabolite set-level biological insights from the full untargeted feature space,
                featureMSEA enables mechanistic interpretation of complex biological phenotypes
                across diverse applications in disease biology, environmental exposure, drug
                response, and related research areas.",
                style = "opacity: 0.85; font-size: 1.0rem; margin-bottom: 24px;"),
              div(class = "d-flex gap-3 flex-wrap",
                shiny::actionButton(
                  "start_analysis",
                  shiny::tagList(bsicons::bs_icon("play-circle"), " Get Started"),
                  class = "btn-light btn-lg",
                  style = "font-weight: 600; color: #2C3E50;",
                  onclick = "$(\"a[data-value='featureMSEA Analysis']\").click();"
                ),
                tags$a(
                  shiny::tagList(bsicons::bs_icon("book"), " Help Documents"),
                  href = "https://www.tidymass.org/featuremsea_tutorial/",
                  target = "_blank",
                  class = "btn btn-outline-light btn-lg",
                  style = "font-weight: 600;"
                )
              )
            ),
            div(class = "col-md-4 text-center",
              tags$img(src = "www/logo.png",
                       style = "max-height: 130px; opacity: 0.92;")
            )
          )
        ),

        # Figure 1
        div(class = "row mb-4",
          div(class = "col-12",
            div(
              style = "background: #fff; border-radius: 14px;
                       box-shadow: 0 4px 18px rgba(44,62,80,0.09); padding: 28px 32px;",
              h5("Overview of featureMSEA",
                 style = "font-weight: 700; color: #2C3E50; margin-bottom: 6px;"),
              p("(a) Inputs: untargeted metabolomics data, annotation score table, feature
                ranking table, and a metabolite set database.
                (b) Core workflow: feature-level enrichment scoring with iterative
                leading-edge-guided annotation refinement, permutation-based statistical
                inference, and optional LLM-assisted interpretation.
                (c) Key outputs: enriched metabolite sets and a refined annotation score table.",
                style = "font-size: 0.9rem; color: #6c757d; margin-bottom: 20px;"),
              div(class = "text-center",
                tags$img(
                  src = "www/figure1.png",
                  style = "max-width: 100%; border-radius: 8px;"
                )
              )
            )
          )
        ),

        # Three workflow steps
        div(class = "row g-4 mb-4",
          div(class = "col-md-4",
            div(class = "intro-step-card",
              div(class = "card-body text-center p-4",
                div(class = "step-number", style = "background: #18BC9C;", "1"),
                h5("Annotation & Filtering",
                   style = "font-weight: 700; color: #2C3E50; margin-bottom: 10px;"),
                p(style = "font-size: 0.93rem; color: #6c757d;",
                  "Automatically annotate LC-MS features against KEGG or HMDB databases
                  with customizable MS1 mass tolerance and retention time windows.
                  Redundant annotations are removed to produce a clean feature ranking table.")
              )
            )
          ),
          div(class = "col-md-4",
            div(class = "intro-step-card",
              div(class = "card-body text-center p-4",
                div(class = "step-number", style = "background: #3498DB;", "2"),
                h5("featureMSEA Enrichment",
                   style = "font-weight: 700; color: #2C3E50; margin-bottom: 10px;"),
                p(style = "font-size: 0.93rem; color: #6c757d;",
                  "Perform feature-level enrichment scoring across KEGG, Reactome, HMDB,
                  IMetPD, or WikiPathways databases. An iterative leading-edge-guided
                  refinement loop improves annotation quality alongside enrichment scoring.")
              )
            )
          ),
          div(class = "col-md-4",
            div(class = "intro-step-card",
              div(class = "card-body text-center p-4",
                div(class = "step-number", style = "background: #F39C12;", "3"),
                h5("LLM-Assisted Interpretation",
                   style = "font-weight: 700; color: #2C3E50; margin-bottom: 10px;"),
                p(style = "font-size: 0.93rem; color: #6c757d;",
                  "Optionally evaluate enriched pathways using large language models.
                  Assess pathway relevance to the sample matrix and research topic,
                  with confidence scores to prioritize biologically meaningful results.")
              )
            )
          )
        ),

        # Getting started hint
        div(class = "highlight-box",
          div(class = "d-flex align-items-center gap-3",
            div(style = "font-size: 1.5rem; color: #18BC9C;", bsicons::bs_icon("lightbulb")),
            div(
              tags$strong("Getting Started: "),
              "Prepare your feature table in CSV or RDA format, then navigate to the ",
              tags$strong("featureMSEA Analysis"),
              " tab to begin."
            )
          )
        )
      )
    ),

    # featureMSEA Analysis Tab
    fmsea_ui("fmsea"),

    # Authors Tab
    bslib::nav_panel(
      title = "Authors",
      icon = bsicons::bs_icon("people"),

      tags$style(HTML("
        .author-card {
          border: none;
          border-radius: 12px;
          box-shadow: 0 4px 16px rgba(44,62,80,0.10);
          transition: transform 0.2s, box-shadow 0.2s;
          background: #fff;
        }
        .author-card:hover {
          transform: translateY(-4px);
          box-shadow: 0 8px 24px rgba(44,62,80,0.16);
        }
        .author-card .card-top-bar {
          height: 6px;
          border-radius: 12px 12px 0 0;
          background: linear-gradient(90deg, #18BC9C, #3498DB);
        }
        .contact-item {
          display: flex;
          align-items: center;
          gap: 12px;
          padding: 14px 18px;
          border-radius: 10px;
          background: #f8f9fa;
          border: 1px solid #e9ecef;
        }
        .contact-icon {
          font-size: 1.4rem;
          color: #18BC9C;
          flex-shrink: 0;
        }
      ")),

      div(class = "container-fluid",
        style = "padding: 30px 40px;",

        # Hero banner
        div(
          style = "background: linear-gradient(135deg, #2C3E50 0%, #18BC9C 100%);
                   border-radius: 14px; padding: 36px 40px; margin-bottom: 32px; color: white;",
          h2("Development Team", style = "margin: 0 0 10px 0; font-weight: 700;"),
          p("FeatureMSEA was developed by a multidisciplinary team combining analytical metabolomics and computational biology.",
            style = "margin: 0; opacity: 0.88; font-size: 1.05rem;")
        ),

        # Author cards
        div(class = "row g-4 mb-4",
          div(class = "col-md-3 d-flex",
            div(class = "author-card h-100 w-100",
              div(class = "card-top-bar"),
              div(class = "card-body text-center p-5",
                tags$img(
                  src = "www/yijiang.png",
                  style = "width: 130px; height: 130px; border-radius: 50%; object-fit: cover;
                           margin-bottom: 16px; border: 4px solid #18BC9C;"
                ),
                h4("Yijiang Liu", style = "color: #2C3E50; font-weight: 700; margin-bottom: 6px;"),
                tags$span("PhD Student",
                  style = "display: inline-block; background: #e8f8f5; color: #18BC9C;
                           font-size: 0.88rem; font-weight: 600; padding: 3px 14px;
                           border-radius: 20px; margin-bottom: 12px;"),
                p(style = "font-size: 0.92rem; color: #6c757d; margin-bottom: 0;",
                  "School of Chemistry, Chemical Engineering and Biotechnology,",
                  tags$br(),
                  "Nanyang Technological University")
              )
            )
          ),
          div(class = "col-md-3 d-flex",
            div(class = "author-card h-100 w-100",
              div(class = "card-top-bar"),
              div(class = "card-body text-center p-5",
                tags$img(
                  src = "www/yuting.png",
                  style = "width: 130px; height: 130px; border-radius: 50%; object-fit: cover;
                           margin-bottom: 16px; border: 4px solid #18BC9C;"
                ),
                h4("Yuting Wang", style = "color: #2C3E50; font-weight: 700; margin-bottom: 6px;"),
                tags$span("PhD Student",
                  style = "display: inline-block; background: #e8f8f5; color: #18BC9C;
                           font-size: 0.88rem; font-weight: 600; padding: 3px 14px;
                           border-radius: 20px; margin-bottom: 12px;"),
                p(style = "font-size: 0.92rem; color: #6c757d; margin-bottom: 0;",
                  "Lee Kong Chian School of Medicine,",
                  tags$br(),
                  "Nanyang Technological University")
              )
            )
          ),
          div(class = "col-md-3 d-flex",
            div(class = "author-card h-100 w-100",
              div(class = "card-top-bar"),
              div(class = "card-body text-center p-5",
                tags$img(
                  src = "www/huantao.png",
                  style = "width: 130px; height: 130px; border-radius: 50%; object-fit: cover;
                           margin-bottom: 16px; border: 4px solid #3498DB;"
                ),
                h4("Dr. Tao Huan", style = "color: #2C3E50; font-weight: 700; margin-bottom: 6px;"),
                tags$span("Associate Professor",
                  style = "display: inline-block; background: #eaf4fb; color: #3498DB;
                           font-size: 0.88rem; font-weight: 600; padding: 3px 14px;
                           border-radius: 20px; margin-bottom: 12px;"),
                p(style = "font-size: 0.92rem; color: #6c757d; margin-bottom: 0;",
                  "Department of Chemistry,",
                  tags$br(),
                  "University of British Columbia")
              )
            )
          ),
          div(class = "col-md-3 d-flex",
            div(class = "author-card h-100 w-100",
              div(class = "card-top-bar"),
              div(class = "card-body text-center p-5",
                tags$img(
                  src = "www/xiaotao.png",
                  style = "width: 130px; height: 130px; border-radius: 50%; object-fit: cover;
                           margin-bottom: 16px; border: 4px solid #3498DB;"
                ),
                h4("Dr. Xiaotao Shen", style = "color: #2C3E50; font-weight: 700; margin-bottom: 6px;"),
                tags$span("Assistant Professor",
                  style = "display: inline-block; background: #eaf4fb; color: #3498DB;
                           font-size: 0.88rem; font-weight: 600; padding: 3px 14px;
                           border-radius: 20px; margin-bottom: 12px;"),
                p(style = "font-size: 0.92rem; color: #6c757d; margin-bottom: 0;",
                  "Lee Kong Chian School of Medicine,",
                  tags$br(),
                  "Nanyang Technological University")
              )
            )
          )
        ),

        # Contact section
        h4("Contact & Support", style = "color: #2C3E50; font-weight: 700; margin-bottom: 16px;"),
        div(class = "row g-3",
          div(class = "col-md-4",
            div(class = "contact-item",
              div(class = "contact-icon", bsicons::bs_icon("github")),
              div(
                div(style = "font-size: 0.8rem; color: #888; font-weight: 600; text-transform: uppercase;", "GitHub"),
                tags$a("featuremsea_shiny",
                       href = "https://github.com/tidymass/featuremsea_shiny",
                       target = "_blank", style = "font-size: 0.9rem;")
              )
            )
          ),
          div(class = "col-md-4",
            div(class = "contact-item",
              div(class = "contact-icon", bsicons::bs_icon("globe")),
              div(
                div(style = "font-size: 0.8rem; color: #888; font-weight: 600; text-transform: uppercase;", "Shen-lab Website"),
                tags$a("www.shen-lab.org",
                       href = "https://www.shen-lab.org/",
                       target = "_blank", style = "font-size: 0.9rem;")
              )
            )
          ),
          div(class = "col-md-4",
            div(class = "contact-item",
              div(class = "contact-icon", bsicons::bs_icon("envelope")),
              div(
                div(style = "font-size: 0.8rem; color: #888; font-weight: 600; text-transform: uppercase;", "Email"),
                tags$a("xiaotao.shen@ntu.edu.sg",
                       href = "mailto:xiaotao.shen@ntu.edu.sg", style = "font-size: 0.9rem;")
              )
            )
          )
        )
      )
    ),

    bslib::nav_spacer(),
    bslib::nav_item(
      tags$img(
        src = "www/lab_logo.png",
        height = "60px",
        style = "vertical-align: middle; padding: 0 12px;"
      )
    )
  )

  # Create the server
  server <- function(input, output, session) {
    fmsea_server("fmsea")
  }

  # Create and run the app
  app <- shiny::shinyApp(ui = ui, server = server, ...)
  return(app)
}