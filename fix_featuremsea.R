# 修复 featuremsea 包加载问题

options(repos = c(CRAN = "https://cloud.r-project.org/"))
source("renv/activate.R")

# 检查包是否实际安装了
cat("检查 featuremsea 安装状态：\n")

# 查看已安装包
installed_pkgs <- installed.packages()
if ("featuremsea" %in% rownames(installed_pkgs)) {
  cat("✅ featuremsea 已安装，版本：", installed_pkgs["featuremsea", "Version"], "\n")

  # 尝试加载并查看详细错误信息
  cat("尝试加载 featuremsea...\n")
  result <- tryCatch({
    library(featuremsea)
    cat("✅ featuremsea 加载成功\n")
    TRUE
  }, error = function(e) {
    cat("❌ featuremsea 加载失败：\n")
    cat("错误信息：", conditionMessage(e), "\n")
    return(FALSE)
  })

  if (!result) {
    # 尝试重新安装
    cat("\n正在重新安装 featuremsea...\n")
    tryCatch({
      remotes::install_github("tidymass/featuremsea", force = TRUE, upgrade = "never")
      cat("✅ featuremsea 重新安装完成\n")

      # 再次尝试加载
      library(featuremsea)
      cat("✅ featuremsea 现在可以正常加载\n")
    }, error = function(e) {
      cat("❌ 重新安装失败：", conditionMessage(e), "\n")
    })
  }

} else {
  cat("❌ featuremsea 未安装\n")
  cat("正在安装 featuremsea...\n")
  remotes::install_github("tidymass/featuremsea", force = TRUE)
}

# 最终验证
cat("\n=== 最终验证 ===\n")
key_packages <- c("featuremsea", "fmseadatabase", "shiny", "ggplot2")
for (pkg in key_packages) {
  if (require(pkg, quietly = TRUE, character.only = TRUE)) {
    cat(sprintf("✅ %s 工作正常\n", pkg))
  } else {
    cat(sprintf("❌ %s 仍有问题\n", pkg))
  }
}

# 创建最终快照
cat("\n创建最终 renv 快照...\n")
renv::snapshot(force = TRUE, prompt = FALSE)