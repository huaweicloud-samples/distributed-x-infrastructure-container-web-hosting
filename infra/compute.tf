# ============================================================================
# 计算层：CCE 集群 + 节点池
# ----------------------------------------------------------------------------
# 资源组成：
#   CCE 集群         : huaweicloud_cce_cluster + huaweicloud_cce_node_pool
#   容器工作负载     : src/k8s/deployment.yaml（K8s Deployment）
#   服务与入口       : src/k8s/service.yaml（K8s Service + ELB 注解）
#   弹性伸缩         : 节点池 scall_enable + src/k8s/hpa.yaml（HPA）
# ============================================================================

# 说明：不在此处自建 IAM 委托（Agency）。
# 原因：本账号以 IAM 子用户（<HW_USER_NAME>）操作，调用 IAM 创建委托会返回
# "Could not find domain: cce"（子用户无创建委托权限，404 为误导信息）。
# CCE 创建集群时会自动建立默认委托 cce_admin（含 SWR/OBS 等常用权限），
# 节点拉取 SWR 镜像、节点注册等均走该默认委托，无需自建。

# 集群 API 公网访问用 EIP：仅作为运维/部署通道（kubectl 从 VPC 外直连 kube-apiserver）。
# 应用流量走 ELB 公网 EIP，节点出网走 SWR/LTS 内网，与 NAT 无关。
# 如不需从 VPC 外访问集群，删除该资源并把下方集群的 eip {} 块一并移除即可收回。
resource "huaweicloud_vpc_eip" "cluster_api" {
  publicip {
    type = "5_bgp"
  }
  bandwidth {
    name        = "${local.name_prefix}-cluster-api-bw"
    size        = 5
    share_type  = "PER"
    charge_mode = "traffic"
  }
}

# CCE 集群（VirtualMachine 类型，容器网络直通 VPC，便于 ELB 直接后端 Pod）
resource "huaweicloud_cce_cluster" "main" {
  name                   = "${local.name_prefix}-cce"
  cluster_type           = "VirtualMachine"
  flavor_id              = "cce.s1.small"
  vpc_id                 = huaweicloud_vpc.main.id
  subnet_id              = huaweicloud_vpc_subnet.private_1.id
  container_network_type = "vpc-router"
  # Pod 网络 CIDR（与 VPC CIDR 10.0.0.0/16 不重叠），vpc-router 模式必填
  container_network_cidr = var.container_network_cidr

  # 为集群绑定公网 EIP，开启 kube-apiserver 公网访问（便于从 VPC 外用 kubectl 部署）。
  # 如不需可从 VPC 外访问，移除该行即可收回（不影响集群内业务）。
  # 注意：eip 参数要的是「公网 IP 地址」字符串，不是 EIP 资源 id。
  eip = huaweicloud_vpc_eip.cluster_api.address
}

# 节点池：CCE 受管节点池承载容器；开启弹性伸缩（min1/max4）
resource "huaweicloud_cce_node_pool" "main" {
  cluster_id         = huaweicloud_cce_cluster.main.id
  name               = "${local.name_prefix}-nodepool"
  flavor_id          = var.node_flavor
  # 节点操作系统（VM 节点必填）。集群为 v1.35，须用受支持的版本化 OS 名；
  # 裸名 "EulerOS" 对应的旧版本在 v1.35 已停建，此处用 v1.35 支持的 HCE 2.0。
  os                 = "Huawei Cloud EulerOS 2.0"
  initial_node_count = 1
  availability_zone  = local.az1
  subnet_id          = huaweicloud_vpc_subnet.private_1.id

  # 节点登录口令（CCE 节点池要求二选一：key_pair 或 password）。
  # 生产请改用 key_pair 并删除 password；此处给出可改的默认值，请务必替换为强口令。
  password = var.node_login_password

  # 节点池弹性伸缩（min_node_count=1 / max_node_count=4）
  scall_enable    = true
  min_node_count  = 1
  max_node_count  = 4
  # 节点数由弹性伸缩器在运行期改写，TF 建出初始值后不再回滚（ignore_initial_node_count）
  ignore_initial_node_count = true

  root_volume {
    size       = 40
    volumetype = "SSD"
  }

  data_volumes {
    size       = 100
    volumetype = "SSD"
  }

  # 节点安全组：允许来自 ELB 的 80 端口及节点间互通
  security_groups = [
    huaweicloud_networking_secgroup.ecs.id,
  ]
}
