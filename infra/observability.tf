# ============================================================================
# 可观测：LTS 日志组 / 日志流
# ----------------------------------------------------------------------------
# 说明：容器 stdout/stderr 日志由 CCE 通过前面 Agency 的 LTS 权限自动投递到该日志组。
# ============================================================================

resource "huaweicloud_lts_group" "app" {
  group_name  = "${local.name_prefix}-lts"
  ttl_in_days = 7
}

resource "huaweicloud_lts_stream" "app" {
  group_id    = huaweicloud_lts_group.app.id
  stream_name = "${local.name_prefix}-app"
  ttl_in_days = 7
}
