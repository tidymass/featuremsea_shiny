# 服务器部署避免依赖冲突指南

## 方案1：使用 renv（推荐）

### 在本地准备
1. 运行 `source("setup_renv.R")` 初始化 renv 环境
2. 确保所有包都正确安装和测试
3. 检查生成的 `renv.lock` 文件

### 在服务器部署
```r
# 1. 克隆项目到服务器
# 2. 安装 renv
install.packages("renv")

# 3. 恢复完全相同的包环境
renv::restore()

# 4. 启动应用
library(featuremseashiny)
run_app()
```

### 优点
- 完全隔离的包环境
- 版本锁定，确保一致性
- 不影响服务器其他 R 项目
- 可重复部署

## 方案2：Docker 容器化部署

### 创建 Dockerfile
```dockerfile
FROM rocker/shiny:4.3.0

# 安装系统依赖
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libgit2-dev \
    && rm -rf /var/lib/apt/lists/*

# 设置工作目录
WORKDIR /srv/shiny-server

# 复制项目文件
COPY . .

# 安装 R 包依赖
RUN R -e "install.packages('remotes')"
RUN R -e "remotes::install_deps('.', dependencies = TRUE)"
RUN R -e "remotes::install_local('.', force = TRUE)"

# 暴露端口
EXPOSE 3838

# 启动应用
CMD ["R", "-e", "featuremseashiny::run_app(host='0.0.0.0', port=3838)"]
```

### 优点
- 完全隔离的运行环境
- 包含所有系统依赖
- 易于部署和扩展
- 不影响服务器任何其他环境

## 方案3：自定义 R 库路径

### 在服务器上创建独立的库目录
```r
# 创建项目专用的包库
project_lib <- "/path/to/your/project/lib"
dir.create(project_lib, recursive = TRUE)

# 设置库路径（只对当前会话有效）
.libPaths(c(project_lib, .libPaths()))

# 或者在 .Rprofile 中设置永久路径
```

### 优点
- 简单快速
- 不需要额外工具
- 适合测试环境

### 缺点
- 需要手动管理版本
- 不够自动化

## 方案4：检查和解决版本冲突

### 检查当前服务器包版本
```r
# 检查关键包版本
key_packages <- c("shiny", "bslib", "DT", "ggplot2")
for (pkg in key_packages) {
  if (require(pkg, quietly = TRUE)) {
    cat(sprintf("%s: %s\n", pkg, packageVersion(pkg)))
  }
}

# 检查版本兼容性
tools::package_dependencies("featuremseashiny",
                            which = c("Depends", "Imports"),
                            recursive = TRUE)
```

## 建议的部署流程

1. **开发阶段**：使用 renv 锁定版本
2. **测试阶段**：在类似服务器环境中测试 renv 部署
3. **生产部署**：根据服务器环境选择 renv 或 Docker
4. **监控**：定期检查包版本和兼容性

## 注意事项

- featuremsea 和 fmseadatabase 是从 GitHub 安装的包，需要确保服务器能访问 GitHub
- 如果服务器网络受限，考虑离线安装方式
- 定期更新依赖包以获得安全修复
- 保存当前工作环境的备份

## 故障排除

如果遇到包冲突：
1. 使用 `renv::status()` 检查环境状态
2. 使用 `renv::diagnostics()` 诊断问题
3. 清理缓存：`renv::purge()`
4. 重建环境：`renv::restore(rebuild = TRUE)`