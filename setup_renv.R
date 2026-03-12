# 设置 renv 环境的脚本
# 运行这个脚本来初始化项目的独立包环境

# 设置 CRAN 镜像
options(repos = c(CRAN = "https://cloud.r-project.org/"))

# 1. 安装和初始化 renv
if (!require(renv, quietly = TRUE)) {
  install.packages("renv")
}

# 2. 初始化 renv 环境
renv::init()

# 3. 安装项目依赖
# 这会根据 DESCRIPTION 文件安装所有依赖包
renv::install()

# 4. 创建快照 - 锁定当前包版本
renv::snapshot()

# 5. 验证安装
print("renv 环境设置完成！")
print("包库位置：")
print(.libPaths())

# 6. 查看已安装的包
installed_packages <- installed.packages()[, c("Package", "Version")]
print("已安装的关键包：")
key_packages <- c("shiny", "bslib", "DT", "ggplot2", "featuremsea", "fmseadatabase")
for (pkg in key_packages) {
  if (pkg %in% rownames(installed_packages)) {
    cat(sprintf("%s: %s\n", pkg, installed_packages[pkg, "Version"]))
  } else {
    cat(sprintf("%s: 未安装\n", pkg))
  }
}