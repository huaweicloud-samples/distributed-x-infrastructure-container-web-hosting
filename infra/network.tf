# ============================================================================
# 网络层：VPC / 子网 / 安全组
# ----------------------------------------------------------------------------
# 说明：CCE 节点与 SWR/LTS 等同区域云服务默认走内网链路，镜像拉取无需 NAT；
# 集群 API 也走 VPC 内部端点（cce_cluster 未绑定 eip）。故不创建 NAT 网关 / SNAT / 私网路由表，
# 私网子网回退到 VPC 默认路由表（仅本地路由），天然无公网出网能力。
# ============================================================================

resource "huaweicloud_vpc" "main" {
  name = "${local.name_prefix}-vpc"
  cidr = var.vpc_cidr
}

# ---- 子网（2 公网 + 2 私网，跨双 AZ）----
resource "huaweicloud_vpc_subnet" "public_1" {
  name            = "${local.name_prefix}-public-1"
  vpc_id          = huaweicloud_vpc.main.id
  cidr            = var.public_subnet_1_cidr
  gateway_ip      = cidrhost(var.public_subnet_1_cidr, 1)
  availability_zone = local.az1
}

resource "huaweicloud_vpc_subnet" "public_2" {
  name            = "${local.name_prefix}-public-2"
  vpc_id          = huaweicloud_vpc.main.id
  cidr            = var.public_subnet_2_cidr
  gateway_ip      = cidrhost(var.public_subnet_2_cidr, 1)
  availability_zone = local.az2
}

resource "huaweicloud_vpc_subnet" "private_1" {
  name            = "${local.name_prefix}-private-1"
  vpc_id          = huaweicloud_vpc.main.id
  cidr            = var.private_subnet_1_cidr
  gateway_ip      = cidrhost(var.private_subnet_1_cidr, 1)
  availability_zone = local.az1
}

resource "huaweicloud_vpc_subnet" "private_2" {
  name            = "${local.name_prefix}-private-2"
  vpc_id          = huaweicloud_vpc.main.id
  cidr            = var.private_subnet_2_cidr
  gateway_ip      = cidrhost(var.private_subnet_2_cidr, 1)
  availability_zone = local.az2
}

# ---- 安全组 ----
# 注意：华为云安全组默认自带 allow-all egress，勿重复创建 egress 规则（见 docs/13 通用坑）。
resource "huaweicloud_networking_secgroup" "elb" {
  name        = "${local.name_prefix}-elb-sg"
  description = "面向公网的负载均衡器安全组"
}

resource "huaweicloud_networking_secgroup_rule" "elb_ingress_http" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = huaweicloud_networking_secgroup.elb.id
}

resource "huaweicloud_networking_secgroup" "ecs" {
  name        = "${local.name_prefix}-ecs-sg"
  description = "CCE 节点 / 工作负载安全组"
}

# 允许来自 ELB 安全组的 80 端口入站
resource "huaweicloud_networking_secgroup_rule" "ecs_ingress_from_elb" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_group_id   = huaweicloud_networking_secgroup.elb.id
  security_group_id = huaweicloud_networking_secgroup.ecs.id
}

# 节点 / Pod 间互通（同安全组内部 TCP/UDP/ICMP 全端口放行）
# 注：provider 仅接受 tcp/udp/icmp/icmpv6，"all" 不被支持，故分三条写。
resource "huaweicloud_networking_secgroup_rule" "ecs_ingress_self_tcp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  remote_group_id   = huaweicloud_networking_secgroup.ecs.id
  security_group_id = huaweicloud_networking_secgroup.ecs.id
}

resource "huaweicloud_networking_secgroup_rule" "ecs_ingress_self_udp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "udp"
  remote_group_id   = huaweicloud_networking_secgroup.ecs.id
  security_group_id = huaweicloud_networking_secgroup.ecs.id
}

resource "huaweicloud_networking_secgroup_rule" "ecs_ingress_self_icmp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_group_id   = huaweicloud_networking_secgroup.ecs.id
  security_group_id = huaweicloud_networking_secgroup.ecs.id
}

# ---- 私网子网出网策略 ----
# 不创建 NAT 网关 / SNAT / 自定义私网路由表：CCE 节点与 SWR（镜像）、LTS（日志，若启用）
# 等同区域云服务默认走内网，集群 API 也走 VPC 内部端点（cce_cluster 未绑定 eip）。
# 私网子网自动回退到 VPC 默认路由表（仅本地路由），无需 0.0.0.0/0 出网路由。
# 如未来确有节点出公网需求（如拉取 Docker Hub 公共镜像），再补回 NAT 网关 + SNAT 即可。

