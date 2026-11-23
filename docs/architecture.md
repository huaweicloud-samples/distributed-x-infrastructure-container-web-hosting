# 架构说明 — 基于 CCE 的容器 Web 应用最佳实践

> 本实践演示如何在华为云上以「VPC + CCE + 独享型 ELB + SWR + LTS」搭建一个高可用
> 可弹性伸缩、可观测的容器化 Web 应用（以 nginx 静态站点 book-app 为例）。

## 1. 架构图

```
互联网用户 (HTTP :80)
│
┌───────────▼───────────┐
│ 独享型 ELB (公网) │ huaweicloud_elb_loadbalancer
│ 绑定 EIP，健康检查 │ + huaweicloud_vpc_eip.elb
└───────────┬───────────┘
│ 转发到 Pod（CCE Service 注解自动注册后端）
┌───────────▼───────────┐
│ CCE 集群 (VPC 网络) │ huaweicloud_cce_cluster
│ ┌───────────────────┐ │
│ │ 节点池(弹性 min1~4)│ │ huaweicloud_cce_node_pool
│ └───────────────────┘ │
│ book-app Deployment │ src/k8s/deployment.yaml
│ └─ Service(LB) │ src/k8s/service.yaml
│ └─ HPA(CPU 80%) │ src/k8s/hpa.yaml
└───────────┬───────────┘
容器日志 ──────────────┤
┌───────────▼───────────┐
│ LTS 日志组 / 日志流 │ huaweicloud_lts_group + lts_stream
└───────────────────────┘

私网子网 ──SNAT──► NAT 网关 + EIP ──► 公网（拉取 SWR 镜像 / 系统更新）
镜像来源：SWR 组织/仓库 ◄── build-push.sh 推送
```

## 2. 组件职责

| 组件 | 华为云资源 | 职责 |
|------|-----------|------|
| 网络边界 | VPC / 4 子网 / 安全组 / NAT / 路由表 | 隔离公私有网段，提供出公网能力 |
| 流量入口 | 独享型 ELB + 公网 EIP | 对外暴露 HTTP 服务、健康检查、负载均衡 |
| 计算 | CCE 集群 + 节点池 | 运行容器工作负载，弹性伸缩 |
| 镜像 | SWR 组织 + 仓库 | 存储 book-app 容器镜像 |
| 可观测 | LTS 日志组 / 流 | 统一收集容器日志 |
| 权限 | IAM 委托（Agency） | 授予节点池拉取 SWR、投递 LTS 的权限 |
| 产物 | OBS 桶 | 存放构建产物 / 部署模板（可选） |

## 3. 设计要点

- **高可用**：节点池跨可用区部署弹性节点；ELB 单 AZ 接入（可按需扩展多 AZ）。
- **弹性**：节点层（`scall_enable` min1/max4）+ Pod 层（HPA CPU 80%）双层伸缩。
- **安全**：ELB 仅开放 80；节点安全组仅放行来自 ELB 的 80 与组内互通；默认 egress 全通。
- **可观测**：容器 stdout/stderr 经 Agency 自动投递 LTS，无需额外 agent。
- **规格可控**：所有资源规格显式写死；调试期建议把 ELB 入站锁到运维 IP。

## 4. 区域与配额

- 默认区域 `cn-north-4`（北京四），可按需修改 `var.region`。
- VPC 自定义路由表配额紧张，本实践仅用 1 张私网路由表（符合配额约束）。
