# ============================================================================
# 变量定义
# ============================================================================

variable "region" {
  description = "华为云区域（AZ 后缀由 locals 追加，如 cn-north-4a）"
  type        = string
  default     = "cn-north-4"
}

variable "project_name" {
  description = "项目名称，用作绝大多数资源的命名前缀"
  type        = string
  default     = "bookapp-web-demo"
}

variable "vpc_cidr" {
  description = "VPC 网段"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_1_cidr" {
  description = "公网子网 1（放置 ELB，AZ-a）"
  type        = string
  default     = "10.0.0.0/24"
}

variable "public_subnet_2_cidr" {
  description = "公网子网 2（AZ-b，备用）"
  type        = string
  default     = "10.0.2.0/24"
}

variable "private_subnet_1_cidr" {
  description = "私网子网 1（放置 CCE 节点，AZ-a）"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_2_cidr" {
  description = "私网子网 2（放置 CCE 节点，AZ-b）"
  type        = string
  default     = "10.0.3.0/24"
}

variable "node_flavor" {
  description = "CCE 节点规格（通用计算型，2vCPU/4GB）。"
  type        = string
  default     = "s6.large.2"
}

variable "container_network_cidr" {
  description = "CCE 容器（Pod）网络 CIDR，vpc-router 模式必填。须与 VPC CIDR（10.0.0.0/16）不重叠。"
  type        = string
  default     = "172.16.0.0/16"
}

variable "swr_organization" {
  description = "SWR 组织名。须小写字母开头、3-30 字符。"
  type        = string
  default     = "bookapp"
}

variable "pipeline_bucket_name" {
  description = "OBS 桶名（存放流水线产物）。须全局唯一且符合 DNS 命名。"
  type        = string
  default     = "bookapp-pipeline-artifacts"
}

variable "node_login_password" {
  description = "CCE 节点登录口令（仅 demo 默认，生产请改用 key_pair 并删除）。须满足复杂度要求。"
  type        = string
  sensitive   = true
  default     = "Huawei@2026Demo"
}
