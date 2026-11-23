# ============================================================================
# 镜像仓库与产物存储
# ----------------------------------------------------------------------------
# 资源映射：
#   huaweicloud_swr_organization + huaweicloud_swr_repository   镜像仓库
#   huaweicloud_obs_bucket                                       流水线产物桶
# ============================================================================

resource "huaweicloud_swr_organization" "main" {
  name = var.swr_organization
}

resource "huaweicloud_swr_repository" "book_app" {
  name         = "book-app"
  organization = huaweicloud_swr_organization.main.name
  description  = "Book app 容器镜像（由 src/scripts/build-push.sh 推送）"
  # 钉住 category，避免 plan 将其置空产生无意义 update（category 默认即 other）。
  category     = "other"
}

resource "huaweicloud_obs_bucket" "pipeline_artifacts" {
  bucket        = var.pipeline_bucket_name
  acl           = "private"
  force_destroy = true
  versioning    = true

  tags = {
    project = local.name_prefix
  }
}
