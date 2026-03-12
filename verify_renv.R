# 验证和修复 renv 环境
# 处理 Bioconductor 版本冲突并验证关键包

options(repos = c(CRAN = "https://cloud.r-project.org/"))

# 激活 renv 环境
if (file.exists("renv/activate.R")) {
  source("renv/activate.R")
  cat("✅ renv 环境已激活\n")
} else {
  cat("❌ renv 环境未找到\n")
  quit(status = 1)
}

# 检查关键包是否可用
check_packages <- function() {
  key_packages <- c(
    "shiny", "bslib", "DT", "ggplot2",
    "featuremsea", "fmseadatabase",
    "htmltools", "patchwork"
  )

  cat("检查关键包安装状态：\n")
  all_ok <- TRUE

  for (pkg in key_packages) {
    if (require(pkg, quietly = TRUE, character.only = TRUE)) {
      cat(sprintf("✅ %s: %s\n", pkg, packageVersion(pkg)))
    } else {
      cat(sprintf("❌ %s: 未安装或无法加载\n", pkg))
      all_ok <- FALSE
    }
  }

  return(all_ok)
}

# 检查包状态
packages_ok <- check_packages()

if (packages_ok) {
  cat("\n🎉 所有关键包都可用！\n")

  # 尝试强制创建快照（忽略 Bioconductor 版本警告）
  cat("\n正在创建 renv 快照...\n")
  tryCatch({
    # 使用 force = TRUE 强制创建快照
    renv::snapshot(force = TRUE, prompt = FALSE)
    cat("✅ renv 快照创建成功\n")
  }, error = function(e) {
    cat("⚠️  快照创建有警告，但环境可用\n")
    cat("错误信息：", conditionMessage(e), "\n")
  })

  cat("\n📋 环境摘要：\n")
  cat("- R 版本：", R.Version()$version.string, "\n")
  cat("- renv 版本：", packageVersion("renv"), "\n")
  cat("- 项目库路径：", .libPaths()[1], "\n")

} else {
  cat("\n❌ 部分关键包不可用，需要重新安装\n")
}

cat("\n📁 生成的文件：\n")
if (file.exists("renv.lock")) cat("✅ renv.lock\n")
if (dir.exists("renv")) cat("✅ renv/ 目录\n")

cat("\n🚀 部署说明：\n")
cat("1. 将整个项目文件夹复制到服务器\n")
cat("2. 在服务器上运行：install.packages('renv')\n")
cat("3. 然后运行：renv::restore()\n")
cat("4. 启动应用：library(featuremseashiny); run_app()\n")