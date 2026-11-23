# ============================================================================
# 输出
# ============================================================================

output "vpc_id" {
  description = "VPC ID"
  value       = huaweicloud_vpc.main.id
}

output "private_subnet_ids" {
  description = "私网子网 ID 列表（CCE 节点所在）"
  value = [
    huaweicloud_vpc_subnet.private_1.id,
    huaweicloud_vpc_subnet.private_2.id,
  ]
}

output "elb_id" {
  description = "独享型 ELB ID（填入 src/k8s/service.yaml 的 kubernetes.io/loadbalance.id 注解）"
  value       = huaweicloud_elb_loadbalancer.main.id
}

output "elb_public_ip" {
  description = "ELB 自动分配的公网 EIP 地址（应用访问入口）"
  value       = huaweicloud_elb_loadbalancer.main.ipv4_eip
}

output "elb_subnet_id" {
  description = "ELB 所在公网子网 ID（填入 src/k8s/service.yaml 的 kubernetes.io/elb.subnet-id 注解）"
  value       = huaweicloud_vpc_subnet.public_1.subnet_id
}

output "swr_login_server" {
  description = "SWR 登录/拉取域名（镜像推送与拉取前缀）"
  value       = huaweicloud_swr_organization.main.login_server
}

output "swr_image_path" {
  description = "Book app 镜像完整路径（SWR 仓库 path）"
  value       = huaweicloud_swr_repository.book_app.path
}

output "cce_cluster_id" {
  description = "CCE 集群 ID"
  value       = huaweicloud_cce_cluster.main.id
}

output "lts_group_id" {
  description = "LTS 日志组 ID（容器日志投递目标）"
  value       = huaweicloud_lts_group.app.id
}

# 获取 kubeconfig 的命令（文档化，非真实凭据）：
#   huaweicloud CCE get-credentials --cluster-name <cluster_id> --region <region> > ~/.kube/config
output "kubeconfig_hint" {
  description = "获取集群 kubeconfig 的命令提示"
  value       = "huaweicloud CCE get-credentials --cluster-name ${huaweicloud_cce_cluster.main.id} --region ${var.region}"
}
