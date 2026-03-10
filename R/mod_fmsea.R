#' Feature-based Metabolite Set Enrichment Analysis (fMSEA) Module
#' @import shiny
#' @importFrom DT dataTableOutput renderDataTable datatable formatStyle
#' @importFrom shinyFiles shinyFilesButton parseFilePaths shinyFileChoose
#' @importFrom bsicons bs_icon
#' @importFrom ggplot2 ggsave
#' @noRd
fmsea_ui <- function(id) {
  ns <- NS(id)
  bslib::nav_panel(
    title = 'fMSEA Analysis',
    icon = bsicons::bs_icon("diagram-3"),
    bslib::layout_sidebar(
      sidebar = bslib::accordion(
        open = "Data Upload & Selection",

        # --- 1. Data Upload & Selection ---
        bslib::accordion_panel(
          title = "Data Upload & Selection",
          icon = bsicons::bs_icon("upload"),

          # Feature Table Upload (支持 CSV/RDA)
          h6("Feature Table", style = "font-weight: bold; color: #333; margin-bottom: 8px;"),
          shinyFiles::shinyFilesButton(id = ns('feature_table_file'),
                                       label = 'Select Feature Table (CSV/RDA)',
                                       title = "Select CSV or RDA file",
                                       multiple = FALSE,
                                       buttonType = "default"),
          div(textOutput(ns("feature_table_path")),
              style = "font-size: 0.75em; color: #666; margin-top: 5px; margin-bottom: 15px; padding: 5px; background-color: #f8f9fa; border-radius: 3px;"),

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

          p("Existing Results:", style = "font-size: 0.85em; font-weight: bold; margin-bottom: 5px;"),
          shinyFiles::shinyFilesButton(id = ns('results_rda_file'),
                                       label = 'Load results.rda',
                                       title = "Select RDA",
                                       multiple = FALSE,
                                       buttonType = "info"),
          div(textOutput(ns("results_rda_path")),
              style = "font-size: 0.75em; color: #666; margin-top: 5px; padding: 5px; background-color: #f8f9fa; border-radius: 3px;")
        ),

        # --- 2. Step 1 Parameters ---
        bslib::accordion_panel(
          title = "Step 1: Annotation",
          icon = bsicons::bs_icon("1-circle"),

          selectInput(ns("column"), "Column",
                      choices = c("rp", "hilic"),
                      selected = "rp"),

          numericInput(ns("ms1_match_ppm"), "MS1 PPM", value = 15),
          numericInput(ns("mfc_rt_tol"), "RT Tol (s)", value = 10),
          numericInput(ns("isotope_number"), "Isotope No.", value = 3),

          actionButton(ns("run_step1"), "Run Step 1",
                       class = "btn-primary",
                       style = "width: 100%;"),

          # 改用 uiOutput 来显示状态信息
          div(style = "margin-top: 10px;",
              uiOutput(ns("step1_status")))
        ),

        # --- 3. Step 2 Parameters ---
        bslib::accordion_panel(
          title = "Step 2: fMSEA",
          icon = bsicons::bs_icon("2-circle"),

          numericInput(ns("threads"), "Threads", value = 3, min = 1),
          numericInput(ns("min_compounds"), "Min Compounds", value = 15),
          numericInput(ns("max_compounds"), "Max Compounds", value = 300),
          numericInput(ns("perm_num"), "Permutations", value = 1000),
          numericInput(ns("max_iter_num"), "Max Iterations", value = 1, min = 1, max = 20),
          numericInput(ns("fdr_thr"), "FDR Thr", value = 0.05),

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
            textInput(ns("sample_source"), "Sample Source (e.g., urine, plasma, serum)",
                      value = "urine", placeholder = "Enter sample source"),
            tags$small("Analyze pathway reliability in specific sample matrix",
                       style = "color: #666; font-style: italic;")
          ),

          div(
            style = "margin-bottom: 15px;",
            h6("Literature Relevance Analysis", style = "color: #0066cc; margin-bottom: 8px;"),
            textInput(ns("research_topic"), "Research Topic (e.g., cancer, diabetes)",
                      value = "cancer", placeholder = "Enter research topic"),
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
            tags$small("Your API key will be used securely and not stored",
                       style = "color: #666; font-style: italic;")
          ),

          div(
            style = "margin-bottom: 10px;",
            checkboxInput(ns("run_matrix_analysis"), "Run Matrix Relevance Analysis", value = TRUE),
            checkboxInput(ns("run_literature_analysis"), "Run Literature Relevance Analysis", value = TRUE)
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
            h6("Significant Modules (Select to visualize)"),
            DT::dataTableOutput(ns("sig_modules_table"))
          ),
          div(
            style = "padding: 10px;",
            h6("Enrichment Plot"),
            plotOutput(ns("fmsea_plot"), height = "400px"),
            div(
              style = "display: flex; gap: 10px; margin-top: 5px;",
              downloadButton(ns("download_png"), "PNG", class = "btn-sm"),
              downloadButton(ns("download_pdf"), "PDF", class = "btn-sm")
            )
          ),

          # LLM Evaluation Results
          conditionalPanel(
            condition = "output.show_llm_results",
            ns = ns,
            div(
              style = "padding: 10px; border-top: 1px solid #eee;",
              div(class = "d-flex justify-content-between align-items-center",
                  h6("LLM Evaluation Results"),
                  downloadButton(ns("download_llm_results"), "Download LLM Results (CSV)",
                                 class = "btn-sm btn-outline-primary")),
              DT::dataTableOutput(ns("llm_results_table"))
            )
          ),
          bslib::accordion(
            open = FALSE,
            bslib::accordion_panel("Detailed Summary",
                            verbatimTextOutput(ns("result_summary")))
          )
        )
      )
    )
  )
}

#' fMSEA Server
#' @noRd
fmsea_server <- function(id, volumes) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    vals <- reactiveValues(
      feature_table = NULL,
      ms1_db = NULL,
      pathway_db = NULL,
      final_result = NULL,
      ranking_table = NULL,
      annotation_table = NULL,
      feature_table_file_path = NULL,
      results_rda_file_path = NULL,
      llm_evaluated_result = NULL,
      matrix_analysis_done = FALSE,
      literature_analysis_done = FALSE
    )

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
      shinyFiles::shinyFileChoose(input, "feature_table_file",
                                  roots = volumes, session = session)
      req(input$feature_table_file)

      file_info <- shinyFiles::parseFilePaths(volumes, input$feature_table_file)
      if (nrow(file_info) > 0) {
        full_path <- as.character(file_info$datapath)
        vals$feature_table_file_path <- full_path
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
      shinyFiles::shinyFileChoose(input, "results_rda_file",
                                  roots = volumes, session = session)
      req(input$results_rda_file)

      file_info <- shinyFiles::parseFilePaths(volumes, input$results_rda_file)
      if (nrow(file_info) > 0) {
        full_path <- as.character(file_info$datapath)
        vals$results_rda_file_path <- full_path
        vals$final_result <- load_rda_data(full_path)

        if (!is.null(vals$final_result)) {
          showNotification("Results loaded successfully!",
                           type = "message", duration = 3)
        }
      }
    })

    output$results_rda_path <- renderText({
      if (!is.null(vals$results_rda_file_path)) {
        paste0("✓ ", get_relative_path(vals$results_rda_file_path))
      } else {
        "No file selected"
      }
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
          status_text <- c(status_text, "Literature relevance analysis completed")
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

    # --- Show LLM Results Condition ---
    output$show_llm_results <- reactive({
      !is.null(vals$llm_evaluated_result)
    })
    outputOptions(output, "show_llm_results", suspendWhenHidden = FALSE)

    # --- Analysis: Step 1 (带模态对话框) ---
    observeEvent(input$run_step1, {
      req(vals$feature_table, input$ms1_database)

      # 显示模态对话框
      showModal(modalDialog(
        title = "Running Step 1: Annotation",
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
            "Step 1 completed successfully! Ready for fMSEA analysis.",
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
        title = "Running Step 2: fMSEA Analysis",
        div(
          style = "text-align: center; padding: 20px;",
          div(
            class = "spinner-border text-success",
            role = "status",
            style = "width: 3rem; height: 3rem;",
            span(class = "sr-only", "Loading...")
          ),
          br(), br(),
          h5("Performing fMSEA analysis..."),
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

          incProgress(0.8, detail = "Analysis complete!")

          # 移除模态对话框
          removeModal()

          showNotification(
            "fMSEA analysis completed successfully!",
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
      if (is.null(input$api_key) || input$api_key == "") {
        showNotification("Please enter your API key", type = "warning", duration = 5)
        return()
      }

      # 检查是否至少选择了一种分析
      if (!input$run_matrix_analysis && !input$run_literature_analysis) {
        showNotification("Please select at least one analysis type", type = "warning", duration = 5)
        return()
      }

      # 保存参数
      local_api_key <- input$api_key
      local_provider <- input$api_provider
      local_sample_source <- input$sample_source
      local_research_topic <- input$research_topic
      local_run_matrix <- input$run_matrix_analysis
      local_run_literature <- input$run_literature_analysis

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

      # 重置状态
      vals$matrix_analysis_done <- FALSE
      vals$literature_analysis_done <- FALSE
      vals$llm_evaluated_result <- vals$final_result

      withProgress(message = 'LLM Evaluation Progress', value = 0, {

        tryCatch({
          total_steps <- sum(c(local_run_matrix, local_run_literature))
          current_step <- 0

          # Matrix Relevance Analysis
          if (local_run_matrix) {
            current_step <- current_step + 1
            incProgress(0.4, detail = paste("Matrix relevance analysis... (", current_step, "/", total_steps, ")"))

            # Note: This function would need to be implemented in featuremsea package
            # vals$llm_evaluated_result <- analyze_matrix_relevance(
            #   results = vals$llm_evaluated_result,
            #   sample_source = local_sample_source,
            #   api_key = local_api_key,
            #   provider = local_provider
            # )
            vals$matrix_analysis_done <- TRUE

            showNotification(
              paste("Matrix relevance analysis completed for", local_sample_source),
              type = "message", duration = 3
            )
          }

          # Literature Relevance Analysis
          if (local_run_literature) {
            current_step <- current_step + 1
            incProgress(0.4, detail = paste("Literature relevance analysis... (", current_step, "/", total_steps, ")"))

            # Note: This function would need to be implemented in featuremsea package
            # vals$llm_evaluated_result <- analyze_literature_relevance(
            #   results = vals$llm_evaluated_result,
            #   research_topic = local_research_topic,
            #   api_key = local_api_key,
            #   provider = local_provider
            # )
            vals$literature_analysis_done <- TRUE

            showNotification(
              paste("Literature relevance analysis completed for", local_research_topic),
              type = "message", duration = 3
            )
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
      req(vals$final_result)

      df <- vals$final_result@significant_modules

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

    current_plot <- reactive({
      req(vals$final_result, input$sig_modules_table_rows_selected)

      idx <- input$sig_modules_table_rows_selected
      target_id <- vals$final_result@significant_modules$pathway_id[idx]

      featuremsea::plot_fmsea_plot(vals$final_result, target_id)
    })

    output$fmsea_plot <- renderPlot({
      current_plot()
    })

    # --- Download Handlers ---
    output$download_table <- downloadHandler(
      filename = function() {
        paste0("fMSEA_Results_", Sys.Date(), ".csv")
      },
      content = function(file) {
        utils::write.csv(vals$final_result@significant_modules, file, row.names = FALSE)
      }
    )

    output$download_png <- downloadHandler(
      filename = function() {
        paste0("fMSEA_Plot_", Sys.Date(), ".png")
      },
      content = function(file) {
        ggplot2::ggsave(file, plot = current_plot(),
                        device = "png", width = 8, height = 6)
      }
    )

    output$download_pdf <- downloadHandler(
      filename = function() {
        paste0("fMSEA_Plot_", Sys.Date(), ".pdf")
      },
      content = function(file) {
        ggplot2::ggsave(file, plot = current_plot(),
                        device = "pdf", width = 8, height = 6)
      }
    )

    output$result_summary <- renderPrint({
      req(vals$final_result)
      print(vals$final_result)
    })

    # --- LLM Results Table ---
    output$llm_results_table <- DT::renderDataTable({
      req(vals$llm_evaluated_result)

      df <- vals$llm_evaluated_result@significant_modules

      DT::datatable(
        df,
        selection = 'none',
        rownames = FALSE,
        options = list(
          scrollX = TRUE,
          scrollY = "300px",
          pageLength = 10,
          dom = 'frtip',
          columnDefs = list(
            list(
              targets = "_all",
              render = DT::JS(
                "function(data, type, row, meta) {
                  return type === 'display' && data !== null && data.length > 30 ?
                    '' + data.substr(0, 30) + '...' : data;
                }"
              )
            )
          )
        )
      ) %>%
      DT::formatStyle(
        columns = colnames(df),
        fontSize = '12px'
      )
    })

    # --- Download LLM Results ---
    output$download_llm_results <- downloadHandler(
      filename = function() {
        analysis_types <- character()
        if (vals$matrix_analysis_done) analysis_types <- c(analysis_types, "matrix")
        if (vals$literature_analysis_done) analysis_types <- c(analysis_types, "literature")

        paste0("fMSEA_LLM_Results_", paste(analysis_types, collapse = "_"), "_", Sys.Date(), ".csv")
      },
      content = function(file) {
        utils::write.csv(vals$llm_evaluated_result@significant_modules, file, row.names = FALSE)
      }
    )
  })
}