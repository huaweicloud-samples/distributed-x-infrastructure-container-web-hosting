# ============================================================================
# 负载均衡层：ELB（独享型，绑定 EIP 对外）
# ----------------------------------------------------------------------------
# 说明：
#  - 独享型 ELB 默认即「应用型」，可通过注解交由 CCE Service 自动创建监听器/后端池
#    （见 src/k8s/service.yaml 的 kubernetes.io/loadbalance.id 注解），因此这里只建
#    ELB 本身 + 绑定公网 EIP，监听器/后端池交给 CCE 托管，避免与 Terraform 重复管理。
#  - l7_flavor_id 留空使用站点默认规格；如需精确控费，可显式指定一个小规格 L7 flavor
#    （用 `data "huaweicloud_elb_flavors" "l7" { type = "L7" }` 查本区域可用规格后赋值）。
# ============================================================================

resource "huaweicloud_elb_loadbalancer" "main" {
  name              = "${local.name_prefix}-elb"
  availability_zone = [local.az1]
  vpc_id            = huaweicloud_vpc.main.id
  # 注意：huaweicloud_vpc_subnet 的 id 与 subnet_id 在本 provider 下并不一致，
  # 真实子网 UUID 是 subnet_id；ELB 严格按真实子网 UUID 查，故此处用 .subnet_id（见 docs/13 通用坑）。
  ipv4_subnet_id    = huaweicloud_vpc_subnet.public_1.subnet_id
  # 由 ELB 自动分配公网 EIP（iptype=5_bgp），避免独立 EIP 资源与 ELB 抢资源导致创建冲突。
  iptype            = "5_bgp"
  # 自动分配 EIP 的带宽配置（按流量计费，峰值 5Mbps，独享）
  bandwidth_charge_mode = "traffic"
  bandwidth_size        = 5
  sharetype             = "PER"

  # 独享型 ELB 创建时由 API 默认分配的规格（已存在于 state），必须显式钉住，
  # 否则 plan 会把 l4/l7 flavor 置空，触发 ELB.8959（不允许同时清空两个 flavor）报错。
  l4_flavor_id = "ec6df27e-8ae9-45e3-828f-a6de45e3e109"
  l7_flavor_id = "66da67e5-e36b-4c9a-8c06-197ae9e92988"

  # 调试期建议：用安全组把入站锁到运维者 IP（替换 0.0.0.0/0 为你的办公网段），
  # 公网 ELB 默认即对全互联网开放 80 端口。
  tags = {
    project = local.name_prefix
  }
}
