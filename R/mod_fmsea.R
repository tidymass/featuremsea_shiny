#' Feature-based Metabolite Set Enrichment Analysis (featureMSEA) Module
#' @import shiny
#' @importFrom DT dataTableOutput renderDataTable datatable formatStyle
# Removed shinyFiles imports - using fileInput instead for web deployment
#' @importFrom bsicons bs_icon
#' @importFrom ggplot2 ggsave
#' @importFrom magrittr %>%
#' @noRd
fmsea_ui <- function(id) {
  ns <- NS(id)
  bslib::nav_panel(
    title = 'featureMSEA Analysis',
    icon = bsicons::bs_icon("diagram-3"),
    tags$script(HTML("
      Shiny.addCustomMessageHandler('fillPasswordInput', function(data) {
        var el = document.getElementById(data.id);
        if (el) {
          var setter = Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype, 'value').set;
          setter.call(el, data.value);
          el.dispatchEvent(new Event('input', { bubbles: true }));
        }
      });
    ")),
    bslib::layout_sidebar(
      sidebar = bslib::accordion(
        open = "Data Upload & Download",

        # --- 1. Data Upload & Download ---
        bslib::accordion_panel(
          title = "Data Upload & Download",
          icon = bsicons::bs_icon("upload"),

          # Feature Table Upload (支持 CSV/RDA)
          h6("Feature Table", style = "font-weight: bold; color: #333; margin-bottom: 8px;"),
          fileInput(ns('feature_table_file'),
                    label = '',
                    accept = c(".csv", ".rda", ".RData"),
                    placeholder = "Select Feature Table (CSV/RDA)"),
          div(textOutput(ns("feature_table_path")),
              style = "font-size: 0.75em; color: #666; margin-top: 5px; margin-bottom: 10px; padding: 5px; background-color: #f8f9fa; border-radius: 3px;"),

          # Demo Data Section
          div(style = "margin-bottom: 15px;",
              p("Or use demo data:", style = "font-size: 0.9em; font-weight: bold; margin-bottom: 8px; color: #6c757d;"),
              div(style = "display: flex; gap: 5px; flex-wrap: wrap; align-items: center;",
                  actionButton(ns("load_demo_data"),
                              HTML(paste(as.character(bsicons::bs_icon("database")), "Load Demo Data")),
                              class = "btn-info btn-sm",
                              style = "font-size: 0.8rem; padding: 0.3rem 0.6rem;"),
                  downloadButton(ns("download_demo_csv"), "CSV",
                               class = "btn-outline-secondary btn-sm",
                               style = "font-size: 0.8rem; padding: 0.3rem 0.6rem;"),
                  downloadButton(ns("download_demo_rda"), "RDA",
                               class = "btn-outline-secondary btn-sm",
                               style = "font-size: 0.8rem; padding: 0.3rem 0.6rem;")
              )
          ),

          # MS1 Database Selection
          h6("MS1 Database", style = "font-weight: bold; color: #333; margin-bottom: 8px;"),
          selectInput(ns("ms1_database"), "",
                      choices = c(
                        "KEGG MS1 Database" = "kegg_compound_ms1",
                        "HMDB MS1 Database" = "hmdb_compound_ms1"
                      ),
                      selected = "kegg_compound_ms1"),

          # Pathway Database Selection (动态更新)
          h6("Pathway Database", style = "font-weight: bold; color: #333; margin-bottom: 8px;"),
          uiOutput(ns("pathway_database_ui")),

          hr(),

          p("Result Management:", style = "font-size: 1.1em; font-weight: bold; margin-bottom: 5px;"),
          div(style = "margin-bottom: 10px;",
              fileInput(ns('results_rda_file'),
                        label = 'Load Result (RDA)',
                        accept = c(".rda", ".RData"),
                        width = "100%")),

          # Demo Result Section
          div(style = "margin-bottom: 15px;",
              p("Or use demo result:", style = "font-size: 0.9em; font-weight: bold; margin-bottom: 8px; color: #6c757d;"),
              actionButton(ns("load_demo_result"),
                          HTML(paste(as.character(bsicons::bs_icon("clipboard-data")), "Load Demo Result")),
                          class = "btn-info btn-sm",
                          style = "font-size: 0.8rem; padding: 0.3rem 0.6rem;")
          ),

          div(style = "display: flex; gap: 5px; margin-bottom: 10px; flex-wrap: wrap;",
              downloadButton(ns("download_current_results"), "Save Result",
                            class = "btn-success",
                            style = "font-size: 0.875rem; padding: 0.375rem 0.75rem; width: 140px;"),
              downloadButton(ns("download_all_data"),
                            HTML(paste(as.character(bsicons::bs_icon("archive")), "Save All Data")),
                            style = "background-color: #ff8c42; border-color: #ff8c42; color: white; font-size: 0.875rem; padding: 0.375rem 0.75rem; width: 140px;")
          ),
          div(textOutput(ns("results_rda_path")),
              style = "font-size: 0.75em; color: #666; margin-top: 5px; margin-bottom: 10px; padding: 5px; background-color: #f8f9fa; border-radius: 3px;"),
          div(textOutput(ns("current_results_status")),
              style = "font-size: 0.75em; color: #666; padding: 5px; background-color: #e8f5e8; border-radius: 3px;")
        ),

        # --- 2. Step 1 Parameters ---
        bslib::accordion_panel(
          title = "Step 1: Annotation and Filtering",
          icon = bsicons::bs_icon("1-circle"),

          selectInput(ns("column"), "Chromatographic Column",
                      choices = c("Reverse Phase (RP)" = "rp",
                                 "Hydrophilic Interaction (HILIC)" = "hilic"),
                      selected = "rp"),

          numericInput(ns("ms1_match_ppm"), "MS1 Mass Tolerance (PPM)", value = 15),
          numericInput(ns("mfc_rt_tol"), "Retention Time Tolerance (seconds)", value = 10),
          numericInput(ns("isotope_number"), "Maximum Isotope Number", value = 3),

          actionButton(ns("run_step1"), "Run Step 1",
                       class = "btn-primary",
                       style = "width: 100%;"),

          # 改用 uiOutput 来显示状态信息
          div(style = "margin-top: 10px;",
              uiOutput(ns("step1_status")))
        ),

        # --- 3. Step 2 Parameters ---
        bslib::accordion_panel(
          title = "Step 2: featureMSEA Analysis",
          icon = bsicons::bs_icon("2-circle"),

          numericInput(ns("threads"), "Number of Threads", value = 3, min = 1),
          numericInput(ns("min_compounds"), "Min Compounds per Pathway", value = 15),
          numericInput(ns("max_compounds"), "Max Compounds per Pathway", value = 300),
          numericInput(ns("perm_num"), "Number of Permutations", value = 1000),
          numericInput(ns("max_iter_num"), "Maximum Iterations", value = 1, min = 1, max = 20),
          numericInput(ns("fdr_thr"), "FDR Threshold", value = 0.05),

          actionButton(ns("run_step2"), "Run Step 2",
                       class = "btn-primary",
                       style = "width: 100%;")
        ),

        # --- 4. Step 3 LLM Evaluation ---
        bslib::accordion_panel(
          title = "Step 3: LLM Evaluation (optional)",
          icon = bsicons::bs_icon("3-circle"),

          div(
            style = "margin-bottom: 15px;",
            h6("Matrix Relevance Analysis", style = "color: #0066cc; margin-bottom: 8px;"),
            textInput(ns("sample_source"), "Sample Source",
                      value = "", placeholder = "e.g., urine, plasma, serum, tissue"),
            tags$small("Analyze pathway reliability in specific sample matrix",
                       style = "color: #666; font-style: italic;")
          ),

          div(
            style = "margin-bottom: 15px;",
            h6("Topic Relevance Analysis", style = "color: #0066cc; margin-bottom: 8px;"),
            textInput(ns("research_topic"), "Research Topic",
                      value = "", placeholder = "e.g., cancer, diabetes, metabolism, aging"),
            tags$small("Analyze pathway relevance to research topic",
                       style = "color: #666; font-style: italic;")
          ),

          div(
            style = "margin-bottom: 15px;",
            h6("API Configuration", style = "color: #0066cc; margin-bottom: 8px;"),
            selectInput(ns("api_provider"), "API Provider",
                        choices = c("siliconflow" = "siliconflow", "openai" = "openai"),
                        selected = "siliconflow"),
            passwordInput(ns("api_key"), "API Key",
                         placeholder = "Enter your API key"),
            uiOutput(ns("trial_key_ui")),
            tags$small("Your API key will be used securely and not stored",
                       style = "color: #666; font-style: italic;"),
            br(), br(),
            uiOutput(ns("model_selection_ui"))
          ),

          div(
            style = "margin-bottom: 10px;",
            checkboxInput(ns("run_matrix_analysis"), "Run Matrix Relevance Analysis", value = TRUE),
            checkboxInput(ns("run_literature_analysis"), "Run Topic Relevance Analysis", value = TRUE)
          ),

          actionButton(ns("run_step3"), "Run LLM Evaluation",
                       class = "btn-primary",
                       style = "width: 100%;"),

          # 状态显示
          div(style = "margin-top: 10px;",
              uiOutput(ns("step3_status")))
        )
      ),

      bslib::card(
        full_screen = TRUE,
        bslib::card_header(
          div(class = "d-flex justify-content-between align-items-center",
              "Analysis Results",
              downloadButton(ns("download_table"), "Download Table (CSV)",
                             class = "btn-sm"))
        ),
        bslib::card_body(
          padding = 0,
          div(
            style = "padding: 10px; border-bottom: 1px solid #eee;",
            h6("Significant Modules"),
            DT::dataTableOutput(ns("sig_modules_table"))
          ),
          div(
            style = "padding: 10px;",
            h6("Enrichment Plot (Click significant module to visualize)"),
            div(
              style = "display: flex; justify-content: center;",
              plotOutput(ns("fmsea_plot"), width = "1000px", height = "600px")
            ),
            div(
              style = "display: flex; gap: 10px; margin-top: 5px;",
              downloadButton(ns("download_png"), "PNG", class = "btn-sm"),
              downloadButton(ns("download_pdf"), "PDF", class = "btn-sm")
            )
          ),

          div(
            style = "padding: 10px; border-top: 1px solid #eee;",
            h6("Annotation Table"),
            div(
              style = "margin-top: 10px;",
              DT::dataTableOutput(ns("leading_edge_annotation_table"))
            ),
            div(
              style = "display: flex; gap: 10px; margin-top: 5px;",
              downloadButton(ns("download_annotation_table"), "Download Table (CSV)", class = "btn-sm")
            )
          ),

          # 动态渲染的 Pathway LLM Evaluation 部分
          uiOutput(ns("pathway_llm_evaluation_ui"))
        )
      )
    )
  )
}

#' featureMSEA Server
#' @noRd
fmsea_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    vals <- reactiveValues(
      feature_table = NULL,
      ms1_db = NULL,
      pathway_db = NULL,
      final_result = NULL,
      ranking_table = NULL,
      annotation_table = NULL,
      leading_edge_table = NULL,
      feature_table_file_path = NULL,
      results_rda_file_path = NULL,
      llm_evaluated_result = NULL,
      matrix_analysis_done = FALSE,
      literature_analysis_done = FALSE
    )

    # --- Trial API Key ---
    trial_key <- Sys.getenv("FEATUREMSEA_TRIAL_API_KEY")
    trial_provider <- Sys.getenv("FEATUREMSEA_TRIAL_PROVIDER", unset = "siliconflow")

    output$trial_key_ui <- renderUI({
      if (nzchar(trial_key)) {
        div(
          style = "margin-top: 6px;",
          actionButton(
            ns("use_trial_key"),
            tagList(bsicons::bs_icon("key"), " Use temporary API key"),
            class = "btn-outline-info btn-sm",
            style = "font-size: 0.8rem;"
          )
        )
      } else {
        NULL
      }
    })

    observeEvent(input$use_trial_key, {
      session$sendCustomMessage("fillPasswordInput",
        list(id = ns("api_key"), value = trial_key))
      shiny::updateSelectInput(session, "api_provider", selected = trial_provider)
      showNotification("Trial key loaded. Usage may be limited.", type = "message", duration = 4)
    })

    # 支持 CSV 和 RDA 格式的数据加载
    load_feature_table <- function(path) {
      if (is.null(path) || length(path) == 0 || path == "") return(NULL)

      file_ext <- tools::file_ext(path)

      if (file_ext == "csv") {
        # 读取 CSV 文件
        return(utils::read.csv(path, stringsAsFactors = FALSE))

      } else if (file_ext %in% c("rda", "RData")) {
        # 读取 RDA 文件
        env <- new.env()
        name <- load(path, envir = env)
        return(get(name, envir = env))

      } else {
        stop("Unsupported file format. Please use CSV or RDA files.")
      }
    }

    load_rda_data <- function(path) {
      if (is.null(path) || length(path) == 0 || path == "") return(NULL)
      env <- new.env()
      name <- load(path, envir = env)
      return(get(name, envir = env))
    }

    # --- 文件路径显示函数 ---
    get_relative_path <- function(full_path) {
      if (is.null(full_path) || length(full_path) == 0) return("")
      # 获取相对路径（从最后两级目录开始）
      path_parts <- strsplit(full_path, "/")[[1]]
      if (length(path_parts) >= 2) {
        paste0(".../ ", paste(tail(path_parts, 2), collapse = "/"))
      } else {
        basename(full_path)
      }
    }

    # --- Feature Table File Handler ---
    observe({
      req(input$feature_table_file)

      file_info <- input$feature_table_file
      if (!is.null(file_info)) {
        # Use the temporary file path provided by fileInput
        full_path <- file_info$datapath
        vals$feature_table_file_path <- file_info$name  # Store original filename for display
        vals$feature_table <- load_feature_table(full_path)

        if (!is.null(vals$feature_table)) {
          showNotification("Feature table loaded successfully!",
                           type = "message", duration = 3)
        }
      }
    })

    output$feature_table_path <- renderText({
      if (!is.null(vals$feature_table_file_path)) {
        paste0("✓ ", get_relative_path(vals$feature_table_file_path))
      } else {
        "No file selected"
      }
    })

    # --- Demo Data Handlers ---
    observeEvent(input$load_demo_data, {
      # 显示模态对话框
      showModal(modalDialog(
        title = "Loading Demo Data",
        div(
          style = "text-align: center; padding: 20px;",
          div(class = "spinner-border text-primary", role = "status", style = "margin-bottom: 15px;"),
          p("Please wait while demo data is being loaded...", style = "margin: 0;")
        ),
        footer = NULL,
        easyClose = FALSE,
        fade = FALSE
      ))

      withProgress(message = 'Loading Demo Data', value = 0, {
        tryCatch({
          incProgress(0.2, detail = "Locating demo data file...")

          demo_path <- system.file("demo_data", "feature_table.rda", package = "featuremseashiny")

          # Fallback to local path if package install path doesn't work
          if (!file.exists(demo_path)) {
            demo_path <- file.path("demo_data", "feature_table.rda")
          }

          incProgress(0.3, detail = "Verifying file exists...")

          if (file.exists(demo_path)) {
            incProgress(0.3, detail = "Loading feature table...")
            vals$feature_table <- load_feature_table(demo_path)
            vals$feature_table_file_path <- "demo_data/feature_table.rda"

            incProgress(0.2, detail = "Complete!")

            # 移除模态对话框
            removeModal()

            if (!is.null(vals$feature_table)) {
              showNotification("Demo data loaded successfully!",
                               type = "message", duration = 3)
            } else {
              showNotification("Failed to load demo data",
                               type = "error", duration = 3)
            }
          } else {
            # 移除模态对话框
            removeModal()

            showNotification("Demo data file not found",
                             type = "error", duration = 3)
          }

        }, error = function(e) {
          # 移除模态对话框
          removeModal()

          showNotification(paste("Error loading demo data:", e$message),
                           type = "error", duration = 5)
        })
      })
    })

    output$download_demo_csv <- downloadHandler(
      filename = "demo_feature_table.csv",
      content = function(file) {
        demo_path <- system.file("demo_data", "feature_table.csv", package = "featuremseashiny")

        # Fallback to local path
        if (!file.exists(demo_path)) {
          demo_path <- file.path("demo_data", "feature_table.csv")
        }

        if (file.exists(demo_path)) {
          file.copy(demo_path, file)
        } else {
          stop("Demo CSV file not found")
        }
      }
    )

    output$download_demo_rda <- downloadHandler(
      filename = "demo_feature_table.rda",
      content = function(file) {
        demo_path <- system.file("demo_data", "feature_table.rda", package = "featuremseashiny")

        # Fallback to local path
        if (!file.exists(demo_path)) {
          demo_path <- file.path("demo_data", "feature_table.rda")
        }

        if (file.exists(demo_path)) {
          file.copy(demo_path, file)
        } else {
          stop("Demo RDA file not found")
        }
      }
    )

    # --- 动态 Model Selection UI ---
    output$model_selection_ui <- renderUI({
      provider <- input$api_provider

      if (is.null(provider)) {
        return(NULL)
      }

      if (provider == "openai") {
        default_model <- "gpt-4o"
        examples <- "e.g., gpt-4o, gpt-4o-mini, gpt-4-turbo"
      } else if (provider == "siliconflow") {
        default_model <- "Qwen/Qwen3-32B"
        examples <- "e.g., Qwen/Qwen3-32B, Qwen/Qwen2.5-32B-Instruct"
      } else {
        return(NULL)
      }

      div(
        textInput(ns("model_name"), "Model for Confidence Scoring",
                  value = default_model,
                  placeholder = paste("Enter model name (", examples, ")")),
        tags$small(
          paste("Examples:", examples),
          style = "color: #666; font-style: italic;"
        )
      )
    })

    # --- 动态 Pathway Database UI ---
    output$pathway_database_ui <- renderUI({
      # 根据 MS1 database 选择来确定可用的 pathway database
      ms1_choice <- input$ms1_database

      if (is.null(ms1_choice)) {
        return(selectInput(ns("pathway_database"), "",
                          choices = c("Please select MS1 database first" = "")))
      }

      # 确定数据库类型
      if (grepl("kegg", ms1_choice, ignore.case = TRUE)) {
        # KEGG MS1: 不能选择 HMDB pathway
        choices <- c(
          "KEGG Pathways" = "kegg_pathway",
          "Reactome Pathways" = "reactome_pathway",
          "IMetPD Pathways" = "imetpd_pathway",
          "WikiPathways" = "wiki_pathway"
        )
        selected <- "kegg_pathway"
      } else if (grepl("hmdb", ms1_choice, ignore.case = TRUE)) {
        # HMDB MS1: 不能选择 KEGG pathway
        choices <- c(
          "HMDB Pathways" = "hmdb_pathway",
          "Reactome Pathways" = "reactome_pathway",
          "IMetPD Pathways" = "imetpd_pathway",
          "WikiPathways" = "wiki_pathway"
        )
        selected <- "hmdb_pathway"
      } else {
        # 默认选择
        choices <- c(
          "KEGG Pathways" = "kegg_pathway",
          "Reactome Pathways" = "reactome_pathway",
          "HMDB Pathways" = "hmdb_pathway",
          "IMetPD Pathways" = "imetpd_pathway",
          "WikiPathways" = "wiki_pathway"
        )
        selected <- "kegg_pathway"
      }

      selectInput(ns("pathway_database"), "",
                  choices = choices,
                  selected = selected)
    })

    # --- Results RDA File Handler ---
    observe({
      req(input$results_rda_file)

      file_info <- input$results_rda_file
      if (!is.null(file_info)) {
        # Use the temporary file path provided by fileInput
        full_path <- file_info$datapath
        vals$results_rda_file_path <- file_info$name  # Store original filename for display
        loaded_result <- load_rda_data(full_path)

        if (!is.null(loaded_result)) {
          vals$final_result <- loaded_result
          # Generate leading edge scores table
          tryCatch({
            # 检查函数是否存在
            if (!exists("get_leading_edge_scores", where = asNamespace("featuremsea"))) {
              stop("Function get_leading_edge_scores not found in featuremsea package")
            }

            # 检查result对象
            if (!inherits(loaded_result, "featuremsea_object")) {
              stop(paste("Invalid result object type:", class(loaded_result)))
            }

            # 尝试检测数据库类型，优先尝试KEGG，然后尝试HMDB
            leading_edge_result <- NULL

            # 先尝试KEGG_ID
            tryCatch({
              leading_edge_result <- featuremsea::get_leading_edge_scores(loaded_result, id_col = "KEGG_ID")
            }, error = function(e_kegg) {
              # 如果KEGG失败，尝试HMDB_ID
              tryCatch({
                leading_edge_result <<- featuremsea::get_leading_edge_scores(loaded_result, id_col = "HMDB_ID")
              }, error = function(e_hmdb) {
                stop(paste("Failed with both KEGG_ID and HMDB_ID:", e_kegg$message, "; ", e_hmdb$message))
              })
            })

            vals$leading_edge_table <- leading_edge_result
          }, error = function(e) {
            vals$leading_edge_table <- data.frame(
              Error = "Generation Failed",
              Details = as.character(e$message),
              stringsAsFactors = FALSE
            )
            showNotification(paste("Warning: Could not generate annotation table:", e$message),
                           type = "warning", duration = 5)
          })
          showNotification("Results loaded successfully!",
                           type = "message", duration = 3)
        }
      }
    })

    output$results_rda_path <- renderText({
      if (!is.null(vals$results_rda_file_path)) {
        paste0("✓ Loaded: ", get_relative_path(vals$results_rda_file_path))
      } else {
        "No file loaded"
      }
    })

    # --- Demo Result Handlers ---
    observeEvent(input$load_demo_result, {
      demo_path <- system.file("demo_result", "results.rda", package = "featuremseashiny")

      # Fallback to local path if package install path doesn't work
      if (!file.exists(demo_path)) {
        demo_path <- file.path("demo_result", "results.rda")
      }

      if (file.exists(demo_path)) {
        loaded_result <- load_rda_data(demo_path)
        vals$results_rda_file_path <- "demo_result/results.rda"

        if (!is.null(loaded_result)) {
          vals$final_result <- loaded_result
          # Generate leading edge scores table
          tryCatch({
            # 检查函数是否存在
            if (!exists("get_leading_edge_scores", where = asNamespace("featuremsea"))) {
              stop("Function get_leading_edge_scores not found in featuremsea package")
            }

            # 检查result对象
            if (!inherits(loaded_result, "featuremsea_object")) {
              stop(paste("Invalid result object type:", class(loaded_result)))
            }

            # 尝试检测数据库类型，优先尝试KEGG，然后尝试HMDB
            leading_edge_result <- NULL

            # 先尝试KEGG_ID
            tryCatch({
              leading_edge_result <- featuremsea::get_leading_edge_scores(loaded_result, id_col = "KEGG_ID")
            }, error = function(e_kegg) {
              # 如果KEGG失败，尝试HMDB_ID
              tryCatch({
                leading_edge_result <<- featuremsea::get_leading_edge_scores(loaded_result, id_col = "HMDB_ID")
              }, error = function(e_hmdb) {
                stop(paste("Failed with both KEGG_ID and HMDB_ID:", e_kegg$message, "; ", e_hmdb$message))
              })
            })

            vals$leading_edge_table <- leading_edge_result
          }, error = function(e) {
            vals$leading_edge_table <- data.frame(
              Error = "Generation Failed",
              Details = as.character(e$message),
              stringsAsFactors = FALSE
            )
            showNotification(paste("Warning: Could not generate annotation table:", e$message),
                           type = "warning", duration = 5)
          })
          showNotification("Demo result loaded successfully!",
                           type = "message", duration = 3)
        } else {
          showNotification("Failed to load demo result",
                           type = "error", duration = 3)
        }
      } else {
        showNotification("Demo result file not found",
                         type = "error", duration = 3)
      }
    })


    # --- Current Results Status ---
    output$current_results_status <- renderText({
      # 确定当前最新的结果对象
      current_result <- NULL
      if (!is.null(vals$llm_evaluated_result)) {
        current_result <- vals$llm_evaluated_result
        status_text <- "✓ Current: LLM-evaluated results"
      } else if (!is.null(vals$final_result)) {
        current_result <- vals$final_result
        status_text <- "✓ Current: featureMSEA results"
      } else {
        return("No analysis results available")
      }

      # 添加分析状态信息
      analysis_info <- character()
      if (vals$matrix_analysis_done) {
        analysis_info <- c(analysis_info, "Matrix")
      }
      if (vals$literature_analysis_done) {
        analysis_info <- c(analysis_info, "Topic")
      }

      if (length(analysis_info) > 0) {
        status_text <- paste0(status_text, " (", paste(analysis_info, collapse = ", "), " analysis)")
      }

      # 添加pathway数量信息
      if (!is.null(current_result) && !is.null(current_result@significant_modules)) {
        n_pathways <- nrow(current_result@significant_modules)
        status_text <- paste0(status_text, " - ", n_pathways, " pathways")
      }

      status_text
    })

    # --- Step 1 状态显示 ---
    output$step1_status <- renderUI({
      if (!is.null(vals$ranking_table) && !is.null(vals$annotation_table)) {
        div(
          style = "padding: 10px; background-color: #d4edda; border: 1px solid #c3e6cb; border-radius: 4px; color: #155724;",
          icon("check-circle"),
          " Step 1 completed successfully!"
        )
      } else {
        NULL
      }
    })

    # --- Step 3 状态显示 ---
    output$step3_status <- renderUI({
      if (!is.null(vals$llm_evaluated_result)) {
        status_text <- character()
        if (vals$matrix_analysis_done) {
          status_text <- c(status_text, "Matrix relevance analysis completed")
        }
        if (vals$literature_analysis_done) {
          status_text <- c(status_text, "Topic relevance analysis completed")
        }

        if (length(status_text) > 0) {
          div(
            style = "padding: 10px; background-color: #fff3cd; border: 1px solid #ffeaa7; border-radius: 4px; color: #856404;",
            icon("check-circle"),
            " ", paste(status_text, collapse = ", "), "!"
          )
        }
      } else {
        NULL
      }
    })


    # --- Analysis: Step 1 (带模态对话框) ---
    observeEvent(input$run_step1, {
      req(vals$feature_table, input$ms1_database)

      # 显示模态对话框
      showModal(modalDialog(
        title = "Running Step 1: Annotation and Filtering",
        div(
          style = "text-align: center; padding: 20px;",
          div(
            class = "spinner-border text-primary",
            role = "status",
            style = "width: 3rem; height: 3rem;",
            span(class = "sr-only", "Loading...")
          ),
          br(), br(),
          h5("Processing annotation..."),
          p("This may take several minutes. Please do not close the browser or navigate away."),
          div(id = ns("step1_progress"), "Initializing...")
        ),
        footer = NULL,
        easyClose = FALSE,
        fade = FALSE
      ))

      # 参数快照
      local_column <- as.character(input$column)
      local_ms1_db <- input$ms1_database
      local_ppm <- as.numeric(input$ms1_match_ppm)
      local_rt_tol <- as.numeric(input$mfc_rt_tol)
      local_isotope <- as.numeric(input$isotope_number)

      # 根据选择的 MS1 数据库确定数据库类型
      if (grepl("kegg", local_ms1_db, ignore.case = TRUE)) {
        local_db_type <- "KEGG"
      } else if (grepl("hmdb", local_ms1_db, ignore.case = TRUE)) {
        local_db_type <- "HMDB"
      } else {
        local_db_type <- "KEGG"  # 默认值
      }

      # 使用 withProgress 显示进度条 + 模态对话框
      withProgress(message = 'Step 1 Progress', value = 0, {

        tryCatch({
          # 步骤 0: 从数据包加载 MS1 数据库
          incProgress(0.05, detail = "Loading MS1 database...")
          utils::data(list = local_ms1_db, package = "fmseadatabase", envir = environment())
          vals$ms1_db <- get(local_ms1_db)

          # 步骤 1: 注释特征表
          incProgress(0.1, detail = "Annotating feature table...")
          annotation_table_final <- featuremsea::annotate_feature_table(
            feature_table = vals$feature_table,
            column = local_column,
            metabolite_database = vals$ms1_db,
            database_type = local_db_type,
            ms1_match_ppm = local_ppm,
            mfc_rt_tol = local_rt_tol,
            isotope_number = local_isotope
          )

          # 步骤 2: 去除冗余
          incProgress(0.4, detail = "Removing redundancy...")
          annotation_table_final2 <- featuremsea::remove_redundancy(
            annotation_table = annotation_table_final
          )

          # 步骤 3: 处理注释表
          incProgress(0.3, detail = "Processing annotation table...")
          results_step1 <- featuremsea::process_annotation_table(
            annotation_table_final2 = annotation_table_final2,
            database_type = local_db_type
          )

          vals$ranking_table <- results_step1$ranking_table
          vals$annotation_table <- results_step1$original_score_annotation

          incProgress(0.2, detail = "Complete!")

          # 移除模态对话框
          removeModal()

          # 成功提示
          showNotification(
            "Step 1 completed successfully! Ready for featureMSEA analysis.",
            type = "message",
            duration = 5
          )

        }, error = function(e) {
          # 移除模态对话框
          removeModal()

          showNotification(
            paste("Step 1 Error:", e$message),
            type = "error",
            duration = 10
          )
        })
      })
    })

    # --- Analysis: Step 2 ---
    observeEvent(input$run_step2, {
      req(vals$ranking_table, vals$annotation_table, input$pathway_database)

      # 显示模态对话框
      showModal(modalDialog(
        title = "Running Step 2: featureMSEA Analysis",
        div(
          style = "text-align: center; padding: 20px;",
          div(
            class = "spinner-border text-success",
            role = "status",
            style = "width: 3rem; height: 3rem;",
            span(class = "sr-only", "Loading...")
          ),
          br(), br(),
          h5("Performing featureMSEA analysis..."),
          p("This analysis may take several minutes depending on the dataset size and parameters."),
          p("Please do not close the browser or navigate away."),
          div(id = ns("step2_progress"), "Loading pathway database...")
        ),
        footer = NULL,
        easyClose = FALSE,
        fade = FALSE
      ))

      # 关键修复：在 withProgress 之前将所有响应式值保存到本地变量
      # 这样避免在多线程环境中访问响应式上下文
      l_pathway_db <- input$pathway_database
      l_ms1_db <- input$ms1_database
      l_anno <- vals$annotation_table
      l_rank <- vals$ranking_table
      l_threads <- as.numeric(input$threads)
      l_min_compounds <- as.numeric(input$min_compounds)
      l_max_compounds <- as.numeric(input$max_compounds)
      l_perm_num <- as.numeric(input$perm_num)
      l_max_iter_num <- as.numeric(input$max_iter_num)
      l_fdr_thr <- as.numeric(input$fdr_thr)

      # 根据选择的 MS1 数据库确定数据库类型
      if (grepl("kegg", l_ms1_db, ignore.case = TRUE)) {
        l_db_type <- "KEGG"
      } else if (grepl("hmdb", l_ms1_db, ignore.case = TRUE)) {
        l_db_type <- "HMDB"
      } else {
        l_db_type <- "KEGG"  # 默认值
      }

      withProgress(message = 'Step 2 Progress', value = 0, {
        tryCatch({
          # 步骤 0: 从数据包加载 Pathway 数据库
          incProgress(0.1, detail = "Loading pathway database...")
          utils::data(list = l_pathway_db, package = "fmseadatabase", envir = environment())

          # 处理对象名称映射（kegg_pathway 加载后实际对象名为 kegg_pathway_database）
          actual_object_name <- if (l_pathway_db == "kegg_pathway") "kegg_pathway_database" else l_pathway_db
          vals$pathway_db <- get(actual_object_name)

          incProgress(0.1, detail = "Initializing analysis...")

          vals$final_result <- featuremsea::perform_fmsea_analysis(
            pathway_database = vals$pathway_db,
            annotation_table = l_anno,
            ranking_table = l_rank,
            threads = l_threads,
            min.compounds.num = l_min_compounds,
            max.compounds.num = l_max_compounds,
            id.col = ifelse(l_db_type == "KEGG", "KEGG_ID", "HMDB_ID"),
            perm.num = l_perm_num,
            max.iter.num = l_max_iter_num,
            fdr.thr = l_fdr_thr
          )

          # Generate leading edge scores table
          tryCatch({
            # 检查函数是否存在
            if (!exists("get_leading_edge_scores", where = asNamespace("featuremsea"))) {
              stop("Function get_leading_edge_scores not found in featuremsea package")
            }

            # 检查result对象
            if (!inherits(vals$final_result, "featuremsea_object")) {
              stop(paste("Invalid result object type:", class(vals$final_result)))
            }

            # 使用分析时确定的数据库类型
            id_col_to_use <- ifelse(l_db_type == "KEGG", "KEGG_ID", "HMDB_ID")
            vals$leading_edge_table <- featuremsea::get_leading_edge_scores(vals$final_result, id_col = id_col_to_use)
          }, error = function(e) {
            vals$leading_edge_table <- data.frame(
              Error = "Generation Failed",
              Details = as.character(e$message),
              stringsAsFactors = FALSE
            )
            showNotification(paste("Warning: Could not generate annotation table:", e$message),
                           type = "warning", duration = 5)
          })

          incProgress(0.8, detail = "Analysis complete!")

          # 移除模态对话框
          removeModal()

          showNotification(
            "featureMSEA analysis completed successfully!",
            type = "message",
            duration = 5
          )

        }, error = function(e) {
          # 移除模态对话框
          removeModal()

          showNotification(
            paste("Step 2 Error:", e$message),
            type = "error",
            duration = 10
          )
        })
      })
    })

    # --- Analysis: Step 3 (LLM Evaluation) ---
    observeEvent(input$run_step3, {
      # 检查是否有可用的结果数据
      if (is.null(vals$final_result) || is.null(vals$final_result@significant_modules)) {
        showNotification("Please run Step 2 first or load existing results.rda file",
                         type = "warning", duration = 5)
        return()
      }

      # 检查 API key
      if (is.null(input$api_key) || trimws(input$api_key) == "") {
        showNotification("Please enter your API key", type = "warning", duration = 5)
        return()
      }

      # 检查是否至少选择了一种分析
      if (!input$run_matrix_analysis && !input$run_literature_analysis) {
        showNotification("Please select at least one analysis type", type = "warning", duration = 5)
        return()
      }

      # 验证Matrix Analysis输入
      if (input$run_matrix_analysis) {
        if (is.null(input$sample_source) || trimws(input$sample_source) == "") {
          showNotification("Please enter a valid sample source for matrix relevance analysis",
                           type = "warning", duration = 5)
          return()
        }
      }

      # 验证Topic Analysis输入
      if (input$run_literature_analysis) {
        if (is.null(input$research_topic) || trimws(input$research_topic) == "") {
          showNotification("Please enter a valid research topic for topic relevance analysis",
                           type = "warning", duration = 5)
          return()
        }
      }

      # 保存参数
      local_api_key <- input$api_key
      local_provider <- input$api_provider
      local_sample_source <- input$sample_source
      local_research_topic <- input$research_topic
      local_run_matrix <- input$run_matrix_analysis
      local_run_literature <- input$run_literature_analysis

      # 确定使用的模型
      local_model <- trimws(input$model_name)
      if (is.null(local_model) || local_model == "") {
        showNotification("Please enter a model name", type = "warning", duration = 5)
        return()
      }

      # 显示模态对话框
      showModal(modalDialog(
        title = "Running LLM Evaluation",
        div(
          style = "text-align: center; padding: 20px;",
          div(
            class = "spinner-border text-warning",
            role = "status",
            style = "width: 3rem; height: 3rem;",
            span(class = "sr-only", "Loading...")
          ),
          br(), br(),
          h5("Performing LLM evaluation..."),
          p("Analyzing pathway relevance using AI models."),
          p("This may take several minutes depending on the number of pathways and API response time."),
          p("Please do not close the browser or navigate away."),
          div(id = ns("step3_progress"), "Initializing...")
        ),
        footer = NULL,
        easyClose = FALSE,
        fade = FALSE
      ))

      # 确保有基础结果对象
      if (is.null(vals$llm_evaluated_result)) {
        vals$llm_evaluated_result <- vals$final_result
      }

      # 确定需要运行的分析
      need_matrix <- local_run_matrix && !vals$matrix_analysis_done
      need_literature <- local_run_literature && !vals$literature_analysis_done

      # 确定需要移除的分析结果
      remove_matrix <- !local_run_matrix && vals$matrix_analysis_done
      remove_literature <- !local_run_literature && vals$literature_analysis_done

      # 计算实际需要执行的步骤数
      total_steps <- sum(c(need_matrix, need_literature))

      # 如果有需要移除的列，直接处理
      if (remove_matrix || remove_literature) {
        current_modules <- vals$llm_evaluated_result@significant_modules

        if (remove_matrix) {
          # 移除Matrix相关列
          matrix_cols <- c("matrix_relevance_score", "sample_source")
          current_modules <- current_modules[, !names(current_modules) %in% matrix_cols, drop = FALSE]
          vals$matrix_analysis_done <- FALSE
          showNotification("Matrix relevance analysis results removed", type = "message", duration = 3)
        }

        if (remove_literature) {
          # 移除Topic相关列
          literature_cols <- c("literature_pmids_exact", "literature_pmids_fuzzy",
                             "topic_confidence_score", "research_topic")
          current_modules <- current_modules[, !names(current_modules) %in% literature_cols, drop = FALSE]
          vals$literature_analysis_done <- FALSE
          showNotification("Topic relevance analysis results removed", type = "message", duration = 3)
        }

        vals$llm_evaluated_result@significant_modules <- current_modules
      }

      # 如果没有新分析需要运行，直接完成
      if (total_steps == 0) {
        # 移除模态对话框
        removeModal()

        showNotification("Analysis configuration updated", type = "message", duration = 3)
        return()
      }

      withProgress(message = 'LLM Evaluation Progress', value = 0, {

        tryCatch({
          current_step <- 0

          # Matrix Relevance Analysis
          if (need_matrix) {
            current_step <- current_step + 1
            incProgress(0.4, detail = paste("Matrix relevance analysis with", local_model, "... (", current_step, "/", total_steps, ")"))

            tryCatch({
              vals$llm_evaluated_result <- featuremsea::analyze_matrix_relevance(
                results = vals$llm_evaluated_result,
                sample_source = local_sample_source,
                api_key = local_api_key,
                provider = local_provider,
                model = local_model
              )
              vals$matrix_analysis_done <- TRUE

              showNotification(
                paste("Matrix relevance analysis completed for", local_sample_source, "using", local_model),
                type = "message", duration = 3
              )

            }, error = function(e) {
              error_msg <- e$message

              # 检查是否是模型相关错误
              if (grepl("model|Model|404|not found|not supported|invalid", error_msg, ignore.case = TRUE)) {
                model_error <- paste("Model '", local_model, "' is not supported by", local_provider, ". Error:", error_msg)
                showNotification(model_error, type = "error", duration = 10)
              } else {
                showNotification(paste("Matrix relevance analysis failed:", error_msg), type = "error", duration = 10)
              }

              # 不设置matrix_analysis_done为TRUE，让用户可以修改参数重试
            })
          }

          # Topic Relevance Analysis
          if (need_literature) {
            current_step <- current_step + 1
            incProgress(0.4, detail = paste("Topic relevance analysis with", local_model, "... (", current_step, "/", total_steps, ")"))

            tryCatch({
              vals$llm_evaluated_result <- featuremsea::analyze_topic_relevance(
                results = vals$llm_evaluated_result,
                research_topic = local_research_topic,
                api_key = local_api_key,
                provider = local_provider,
                model = local_model
              )
              vals$literature_analysis_done <- TRUE

              showNotification(
                paste("Topic relevance analysis completed for", local_research_topic, "using", local_model),
                type = "message", duration = 3
              )

            }, error = function(e) {
              error_msg <- e$message

              # 检查是否是模型相关错误
              if (grepl("model|Model|404|not found|not supported|invalid", error_msg, ignore.case = TRUE)) {
                model_error <- paste("Model '", local_model, "' is not supported by", local_provider, ". Error:", error_msg)
                showNotification(model_error, type = "error", duration = 10)
              } else {
                showNotification(paste("Topic relevance analysis failed:", error_msg), type = "error", duration = 10)
              }

              # 不设置literature_analysis_done为TRUE，让用户可以修改模型重试
            })
          }

          # 重新排序列，确保Matrix相关列在前面
          if (vals$matrix_analysis_done || vals$literature_analysis_done) {
            current_modules <- vals$llm_evaluated_result@significant_modules

            # 定义列的优先级顺序
            priority_cols <- c("pathway_id", "pathway_name", "pathway_description")
            matrix_cols <- c("matrix_relevance_score", "sample_source")
            literature_cols <- c("literature_pmids_exact", "literature_pmids_fuzzy",
                                "topic_confidence_score", "research_topic")

            # 获取所有其他列
            other_cols <- setdiff(names(current_modules),
                                 c(priority_cols, matrix_cols, literature_cols))

            # 重新排序列：所有原始列 + Matrix列 + Literature列
            original_cols <- c(priority_cols, other_cols)
            new_order <- c(
              intersect(original_cols, names(current_modules)),
              intersect(matrix_cols, names(current_modules)),
              intersect(literature_cols, names(current_modules))
            )

            vals$llm_evaluated_result@significant_modules <- current_modules[, new_order, drop = FALSE]
          }

          incProgress(0.2, detail = "Complete!")

          # 移除模态对话框
          removeModal()

          showNotification(
            "LLM evaluation completed successfully!",
            type = "message", duration = 5
          )

        }, error = function(e) {
          # 移除模态对话框
          removeModal()

          showNotification(
            paste("LLM Evaluation Error:", e$message),
            type = "error", duration = 10
          )
        })
      })
    })

    # --- Table & Plot Interaction ---
    output$sig_modules_table <- DT::renderDataTable({
      # 优先显示LLM评估后的结果，否则显示基础结果
      current_result <- NULL
      if (!is.null(vals$llm_evaluated_result)) {
        current_result <- vals$llm_evaluated_result
      } else if (!is.null(vals$final_result)) {
        current_result <- vals$final_result
      } else {
        return(NULL)
      }

      req(current_result)
      df <- current_result@significant_modules

      DT::datatable(
        df,
        selection = 'single',
        rownames = FALSE,
        options = list(
          scrollX = TRUE,
          scrollY = "200px",
          pageLength = 5,
          dom = 'tp',
          columnDefs = list(
            list(
              targets = "_all",
              render = DT::JS(
                "function(data, type, row, meta) {
                  return type === 'display' && data !== null && data.length > 20 ?
                    '' + data.substr(0, 20) + '...' : data;
                }"
              )
            )
          )
        )
      )
    })

    # --- Leading Edge Annotation Table Output ---
    output$leading_edge_annotation_table <- DT::renderDataTable({
      # 如果没有数据，返回NULL（不显示任何内容）
      if (is.null(vals$leading_edge_table) ||
          !is.data.frame(vals$leading_edge_table) ||
          nrow(vals$leading_edge_table) == 0) {
        return(NULL)
      }

      tryCatch({
        # 正常渲染表格
        dt_table <- DT::datatable(
          vals$leading_edge_table,
          rownames = FALSE,
          options = list(
            scrollX = TRUE,
            scrollY = "400px",
            pageLength = 10,
            dom = 'frtip',
            columnDefs = list(
              list(
                targets = "_all",
                render = DT::JS(
                  "function(data, type, row, meta) {
                    return type === 'display' && data !== null && data.length > 50 ?
                      '' + data.substr(0, 50) + '...' : data;
                  }"
                )
              )
            )
          )
        )

        DT::formatStyle(dt_table, columns = colnames(vals$leading_edge_table), fontSize = '12px')

      }, error = function(e) {
        # 出现错误时也返回NULL，保持界面简洁
        return(NULL)
      })
    })

    current_plot <- reactive({
      # 直接依赖于数据变量，确保在数据加载后重新渲染
      vals$final_result
      vals$llm_evaluated_result

      # 使用当前最新的结果对象
      current_result <- NULL
      if (!is.null(vals$llm_evaluated_result)) {
        current_result <- vals$llm_evaluated_result
      } else if (!is.null(vals$final_result)) {
        current_result <- vals$final_result
      }

      req(current_result, input$sig_modules_table_rows_selected)

      idx <- input$sig_modules_table_rows_selected
      target_id <- current_result@significant_modules$pathway_id[idx]

      tryCatch({
        # Ensure patchwork is loaded for ggplot operations
        if (!requireNamespace("patchwork", quietly = TRUE)) {
          stop("patchwork package is required for plot generation. Please install it with: install.packages('patchwork')")
        }

        # Load patchwork functions
        library(patchwork)

        plot_result <- featuremsea::plot_fmsea_plot(current_result, target_id)
        return(plot_result)

      }, error = function(e) {
        # Create a simple error plot if plotting fails
        ggplot2::ggplot() +
          ggplot2::annotate("text", x = 0, y = 0,
                           label = paste("Plot Error:", e$message),
                           size = 5, color = "red") +
          ggplot2::theme_minimal() +
          ggplot2::theme(
            axis.text = ggplot2::element_blank(),
            axis.ticks = ggplot2::element_blank(),
            panel.grid = ggplot2::element_blank()
          ) +
          ggplot2::labs(title = "Enrichment Plot Error")
      })
    })

    output$fmsea_plot <- renderPlot({
      current_plot()
    }, res = 120, width = 1000, height = 600)

    # --- Download Current Results ---
    output$download_current_results <- downloadHandler(
      filename = function() {
        # 生成文件名
        timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")

        # 确定分析类型
        analysis_type <- "featureMSEA"
        if (vals$matrix_analysis_done || vals$literature_analysis_done) {
          analysis_components <- character()
          if (vals$matrix_analysis_done) analysis_components <- c(analysis_components, "Matrix")
          if (vals$literature_analysis_done) analysis_components <- c(analysis_components, "Topic")
          analysis_type <- paste0("featureMSEA_", paste(analysis_components, collapse = "_"))
        }

        paste0("results_", analysis_type, "_", timestamp, ".rda")
      },
      content = function(file) {
        # 确定要下载的结果对象
        results_to_save <- NULL
        if (!is.null(vals$llm_evaluated_result)) {
          results_to_save <- vals$llm_evaluated_result
        } else if (!is.null(vals$final_result)) {
          results_to_save <- vals$final_result
        }

        if (is.null(results_to_save)) {
          stop("No analysis results available for download")
        }

        # 保存结果对象
        final_result <- results_to_save
        save(final_result, file = file)

        showNotification("Results saved successfully!", type = "message", duration = 3)
      }
    )

    # --- Download Handlers ---
    output$download_table <- downloadHandler(
      filename = function() {
        # 根据结果类型生成文件名
        if (!is.null(vals$llm_evaluated_result)) {
          analysis_types <- character()
          if (vals$matrix_analysis_done) analysis_types <- c(analysis_types, "Matrix")
          if (vals$literature_analysis_done) analysis_types <- c(analysis_types, "Topic")

          if (length(analysis_types) > 0) {
            paste0("featureMSEA_LLM_", paste(analysis_types, collapse = "_"), "_Results_", Sys.Date(), ".csv")
          } else {
            paste0("featureMSEA_LLM_Results_", Sys.Date(), ".csv")
          }
        } else {
          paste0("featureMSEA_Results_", Sys.Date(), ".csv")
        }
      },
      content = function(file) {
        # 下载当前显示的表格
        current_result <- NULL
        if (!is.null(vals$llm_evaluated_result)) {
          current_result <- vals$llm_evaluated_result
        } else if (!is.null(vals$final_result)) {
          current_result <- vals$final_result
        }

        if (is.null(current_result)) {
          stop("No results available for download")
        }

        utils::write.csv(current_result@significant_modules, file, row.names = FALSE)
      }
    )

    output$download_annotation_table <- downloadHandler(
      filename = function() {
        paste0("featureMSEA_Annotation_Table_", Sys.Date(), ".csv")
      },
      content = function(file) {
        if (is.null(vals$leading_edge_table)) {
          stop("No annotation table available for download")
        }
        utils::write.csv(vals$leading_edge_table, file, row.names = FALSE)
      }
    )

    output$download_png <- downloadHandler(
      filename = function() {
        paste0("featureMSEA_Plot_", Sys.Date(), ".png")
      },
      content = function(file) {
        ggplot2::ggsave(file, plot = current_plot(),
                        device = "png", width = 8, height = 6)
      }
    )

    output$download_pdf <- downloadHandler(
      filename = function() {
        paste0("featureMSEA_Plot_", Sys.Date(), ".pdf")
      },
      content = function(file) {
        ggplot2::ggsave(file, plot = current_plot(),
                        device = "pdf", width = 8, height = 6)
      }
    )

    # --- Download All Data ---
    output$download_all_data <- downloadHandler(
      filename = function() {
        timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
        analysis_type <- "featureMSEA"
        if (vals$matrix_analysis_done || vals$literature_analysis_done) {
          analysis_components <- character()
          if (vals$matrix_analysis_done) analysis_components <- c(analysis_components, "Matrix")
          if (vals$literature_analysis_done) analysis_components <- c(analysis_components, "Topic")
          analysis_type <- paste0("featureMSEA_", paste(analysis_components, collapse = "_"))
        }
        paste0("featureMSEA_AllData_", analysis_type, "_", timestamp, ".zip")
      },
      content = function(file) {
        # 确定要保存的结果对象
        current_result <- NULL
        if (!is.null(vals$llm_evaluated_result)) {
          current_result <- vals$llm_evaluated_result
        } else if (!is.null(vals$final_result)) {
          current_result <- vals$final_result
        }

        if (is.null(current_result)) {
          stop("No analysis results available for download")
        }

        # 创建临时目录
        temp_dir <- tempdir()
        data_dir <- file.path(temp_dir, "featureMSEA_AllData")
        if (dir.exists(data_dir)) unlink(data_dir, recursive = TRUE)
        dir.create(data_dir, recursive = TRUE)

        # 创建 Enrichment Plots 子文件夹
        plots_dir <- file.path(data_dir, "Enrichment_Plots")
        dir.create(plots_dir, recursive = TRUE)

        tryCatch({
          # 1. 保存结果对象 (.rda文件)
          final_result <- current_result
          rda_file <- file.path(data_dir, "analysis_results.rda")
          save(final_result, file = rda_file)

          # 2. 保存显著模块表 (.csv文件)
          csv_file <- file.path(data_dir, "significant_modules.csv")
          utils::write.csv(current_result@significant_modules, csv_file, row.names = FALSE)

          # 3. 保存注释表 (.csv文件)
          if (!is.null(vals$leading_edge_table)) {
            annotation_csv_file <- file.path(data_dir, "annotation_table.csv")
            utils::write.csv(vals$leading_edge_table, annotation_csv_file, row.names = FALSE)
          }

          # 4. 生成所有显著通路的富集图 (PDF文件)
          pathway_ids <- current_result@significant_modules$pathway_id

          # 确保patchwork包可用
          if (!requireNamespace("patchwork", quietly = TRUE)) {
            stop("patchwork package is required for plot generation. Please install it with: install.packages('patchwork')")
          }
          library(patchwork)

          withProgress(message = "Generating enrichment plots...", value = 0, {
            for (i in seq_along(pathway_ids)) {
              pathway_id <- pathway_ids[i]
              pathway_name <- current_result@significant_modules$pathway_name[i]

              # 生成安全的文件名（移除特殊字符）
              safe_name <- gsub("[^A-Za-z0-9_-]", "_", pathway_name)
              if (nchar(safe_name) > 100) {
                safe_name <- substr(safe_name, 1, 100)
              }

              plot_file <- file.path(plots_dir, paste0(i, "_", safe_name, ".pdf"))

              tryCatch({
                plot_result <- featuremsea::plot_fmsea_plot(current_result, pathway_id)
                ggplot2::ggsave(plot_file, plot = plot_result,
                               device = "pdf", width = 10, height = 8)
              }, error = function(e) {
                # 如果单个图生成失败，创建一个错误信息图
                error_plot <- ggplot2::ggplot() +
                  ggplot2::annotate("text", x = 0, y = 0,
                                   label = paste("Plot generation failed for:", pathway_name, "\nError:", e$message),
                                   size = 4, color = "red") +
                  ggplot2::theme_minimal() +
                  ggplot2::labs(title = paste("Error:", pathway_name))
                ggplot2::ggsave(plot_file, plot = error_plot,
                               device = "pdf", width = 8, height = 6)
              })

              incProgress(1/length(pathway_ids))
            }
          })

          # 5. 创建zip文件
          current_dir <- getwd()
          setwd(temp_dir)
          utils::zip(file, "featureMSEA_AllData", flags = "-r")
          setwd(current_dir)

          showNotification("All data packaged successfully!", type = "message", duration = 3)

        }, error = function(e) {
          showNotification(paste("Error creating data package:", e$message), type = "error", duration = 10)
        }, finally = {
          # 清理临时文件
          if (dir.exists(data_dir)) {
            unlink(data_dir, recursive = TRUE)
          }
        })
      }
    )

    # --- Result Summary ---
    output$pathway_summary <- renderText({
      # 获取当前最新的结果对象
      current_result <- NULL
      has_llm_evaluation <- !is.null(vals$llm_evaluated_result)

      if (has_llm_evaluation) {
        current_result <- vals$llm_evaluated_result
      } else if (!is.null(vals$final_result)) {
        current_result <- vals$final_result
      }

      # 检查是否有选中的pathway
      if (is.null(current_result) || is.null(input$sig_modules_table_rows_selected)) {
        if (has_llm_evaluation) {
          return("Please select a pathway from the table above to view its LLM evaluation details.")
        } else {
          return("Please select a pathway from the table above to view its details.")
        }
      }

      idx <- input$sig_modules_table_rows_selected
      pathway_data <- current_result@significant_modules[idx, ]

      # 根据是否进行了LLM评估来定义要显示的字段
      if (has_llm_evaluation) {
        # 显示完整的LLM评估字段
        fields <- c(
          "pathway_name" = "Pathway Name",
          "matrix_source" = "Matrix Source",
          "matrix_confidence_score" = "Matrix Confidence Score",
          "matrix_confidence_reason" = "Matrix Confidence Reason",
          "research_topic" = "Research Topic",
          "literature_pmids_exact" = "Literature PMIDs (Exact)",
          "literature_pmids_fuzzy" = "Literature PMIDs (Fuzzy)",
          "topic_confidence_score" = "Topic Confidence Score"
        )
      } else {
        # 只显示基础字段，不包含LLM相关字段
        fields <- c(
          "pathway_name" = "Pathway Name",
          "NES" = "Normalized Enrichment Score",
          "pval" = "P-value",
          "padj" = "Adjusted P-value",
          "size" = "Pathway Size",
          "leadingEdge" = "Leading Edge"
        )
      }

      # 构建显示文本
      output_lines <- character()
      for (field_name in names(fields)) {
        field_label <- fields[[field_name]]
        if (field_name %in% names(pathway_data)) {
          field_value <- pathway_data[[field_name]]
          if (is.na(field_value) || is.null(field_value) || field_value == "") {
            field_value <- "NA"
          }
        } else {
          field_value <- "NA"
        }
        output_lines <- c(output_lines, paste0(field_label, ": ", field_value))
      }

      return(paste(output_lines, collapse = "\n"))
    })

    # --- 动态渲染 Pathway LLM Evaluation UI ---
    output$pathway_llm_evaluation_ui <- renderUI({
      # 检查是否有LLM评估结果
      has_llm_evaluation <- !is.null(vals$llm_evaluated_result)

      if (has_llm_evaluation) {
        # 如果有LLM评估，显示accordion并展开
        bslib::accordion(
          open = TRUE,
          bslib::accordion_panel(
            "Pathway LLM Evaluation",
            div(
              div(class = "d-flex justify-content-end mb-2",
                  actionButton(ns("copy_pathway_summary"), "Copy",
                               class = "btn-sm btn-outline-secondary",
                               onclick = "navigator.clipboard.writeText(document.getElementById('pathway_summary_text').innerText);")),
              div(id = "pathway_summary_text",
                  verbatimTextOutput(ns("pathway_summary")))
            )
          )
        )
      } else {
        # 如果没有LLM评估，返回NULL（不显示任何内容）
        NULL
      }
    })

  })
}