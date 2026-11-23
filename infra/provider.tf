# ============================================================================
# 华为云 Provider 配置
# ----------------------------------------------------------------------------
# 认证凭据从环境变量读取，绝不硬编码 AK/SK：
#   export HW_ACCESS_KEY="<你的 Access Key>"
#   export HW_SECRET_KEY="<你的 Secret Key>"
# 临时凭证（如需要）再加：
#   export HW_SECURITY_TOKEN="<你的 Security Token>"
# ============================================================================

provider "huaweicloud" {
  region = var.region
}
