terraform {
  required_version = ">= 1.5"

  required_providers {
    huaweicloud = {
      source  = "huaweicloud/huaweicloud"
      version = "~> 1.70"
    }
  }

  # 状态文件默认存本地；生产环境建议改为 OBS 远程后端（见下方注释）。
  backend "local" {}

  # 生产环境推荐远程后端（避免本地 state 丢失，并支持团队协作）：
  # backend "s3" {
  #   endpoint   = "https://obs.cn-north-4.myhuaweicloud.com"
  #   bucket     = "your-tfstate-bucket"
  #   key        = "bookapp-web-demo/terraform.tfstate"
  #   region     = "cn-north-4"
  #   access_key = var.hw_access_key   # 或直接用环境变量，勿硬编码
  #   secret_key = var.hw_secret_key
  # }
}
