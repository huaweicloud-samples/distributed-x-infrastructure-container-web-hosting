# distributed-x-infrastructure-container-web-hosting · 基于 CCE 的容器 Web 应用最佳实践

<img src="https://img.shields.io/badge/License-MIT--0-blue.svg" alt="License">
![License](https://img.shields.io/badge/license-MIT-green)
![Cloud](https://img.shields.io/badge/Cloud-HuaweiCloud-blue)
![Status](https://img.shields.io/badge/build-passing-brightgreen)
> 在华为云上以「VPC + CCE + 独享型 ELB + SWR + LTS」搭建高可用、可弹性伸缩、可观测的
> 容器化 Web 应用（以 nginx 静态站点 book-app 为例）。

## 1. 简介 / Overview

### 简介


本实践面向希望在华为云上运行容器化 Web 服务的开发者与运维，演示如何仅用 IaC（Terraform）
一键拉起一套生产可用的容器基础设施，并提供镜像构建、部署、弹性伸缩与日志收集的完整链路。

---

## 2. 目录

- [1. 简介 / Overview](#1-简介--overview)
- [2. 目录](#2-目录)
- [3. 架构图](#3-架构图)
- [4. 方案亮点](#4-方案亮点)
- [5. 涉及云服务](#5-涉及云服务)
- [6. 前置条件](#6-前置条件)
- [7. 快速开始](#7-快速开始)
- [8. 分步部署](#8-分步部署)
- [9. 使用方法 / 验证](#9-使用方法--验证)
- [10. 清理资源](#10-清理资源)
- [11. 详细说明](#11-详细说明)
- [12. 依赖](#12-依赖)
- [13. FAQ / 故障排除](#13-faq--故障排除)
- [14. 贡献指南](#14-贡献指南)
- [15. 许可证](#15-许可证)
- [16. 联系方式 / 维护者](#16-联系方式--维护者)

---

## 3. 架构图

```
互联网用户 (HTTP :80)
│
┌───────▼───────┐
│ 独享型 ELB │ 绑定公网 EIP，健康检查 + 负载均衡
└───────┬───────┘
CCE Service(LoadBalancer) 自动注册 Pod 后端
┌───────▼───────┐
│ CCE 集群 │ 节点池弹性 min1~max4
│ book-app 部署 │ HPA(CPU 80%)
└───────┬───────┘
容器日志 → LTS；镜像 ← SWR；出公网 → NAT+EIP
```

---

## 4. 方案亮点

- **纯 IaC**：基础设施全部 Terraform 描述，`terraform plan/apply` 可复现。
- **弹性双层**：节点层弹性伸缩 + Pod 层 HPA，对应业务波峰波谷。
- **开箱可观测**：容器日志经 IAM 委托自动投递 LTS，无需额外 agent。
- **规格可控**：所有规格均显式写死，调试期可将 ELB 入站锁到运维 IP。

---

## 5. 涉及云服务

本实践使用以下华为云服务：

| 服务 | 用途 |
|---|---|
| VPC | 私网/公网子网隔离 |
| CCE | 容器编排 + 节点池 |
| 独享型 ELB | 公网入口 + 后端 Pod 注册 |
| SWR | 容器镜像仓库 |
| OBS | 流水线产物桶 |
| LTS | 容器 stdout/stderr 日志 |

---

## 6. 前置条件

- 华为云账号及 `HW_ACCESS_KEY` / `HW_SECRET_KEY`（从环境变量提供，勿写入代码或配置文件）。
- 已安装：Terraform ≥ 1.5、Docker、huaweicloud CLI、kubectl。
- 默认区域 `cn-north-4`（北京四），可按需修改 `infra/variables.tf` 的 `region`。

---

## 7. 快速开始

```bash
export HW_ACCESS_KEY="<HW_ACCESS_KEY>"
export HW_SECRET_KEY="<HW_SECRET_KEY>"
export HW_REGION_NAME="cn-north-4"

cd infra && terraform init && terraform apply
```

apply 完成后：

```bash
terraform output elb_public_ip # 应用公网入口
bash ../src/scripts/build-push.sh # 构建并推送镜像到 SWR
bash ../src/scripts/deploy.sh # 获取 kubeconfig 并部署工作负载
```

---

## 8. 分步部署

详见 [docs/deployment-guide.md](docs/deployment-guide.md)，包含镜像构建、Service 注解填充
HPA 安装与蓝绿发布（CodeArts）等完整步骤。

---

## 9. 使用方法 / 验证

### 使用方法与验证

通过 `kubectl` 查看 Service 并访问 ELB 公网地址即可验证 Web 应用，详见下列步骤。

```bash
kubectl get svc book-app -o wide
curl -I http://<elb_public_ip>/
# 期望返回 HTTP/1.1 200
```

浏览器访问 `http://<elb_public_ip>/` 即可看到 book-app 首页。

部署完成后请按本节步骤自行验证，确认业务功能可用，方可视为交付完成。

---

## 10. 清理资源

```bash
kubectl delete -f src/k8s/ # 先释放工作负载与 ELB 后端
terraform destroy # 回收云资源
```

---

## 11. 详细说明

- 架构与组件职责：[docs/architecture.md](docs/architecture.md)
- 部署全流程：[docs/deployment-guide.md](docs/deployment-guide.md)
- 质量门禁与约束：所有资源规格显式写死，便于复现；调试期建议把 ELB 入站锁到运维 IP；VPC 仅使用 1 张私网路由表以符合配额约束。

---

## 12. 依赖

- Terraform ≥ 1.5
- huaweicloud Provider ~> 1.70
- kubectl / docker / swr-login（构建推送镜像用）
- 本实践基于华为云 CCE/ECS/ELB/SWR 等公开服务构建。

仓库结构如下：

```
.
├── docs/        # 华为云实践文档
├── infra/       # Terraform + huaweicloud Provider
├── src/         # 应用代码与脚本
└── README.md
```

---

## 13. FAQ / 故障排除

### FAQ

**Q：ELB 健康检查一直异常？**
A：确认节点安全组已放行来自 ELB 安全组的 80 端口（本实践已建 `ecs_ingress_from_elb` 规则）
且 Pod 就绪探针返回 200。

**Q：HPA 不生效？**
A：集群需安装 metrics-server 插件（CCE 控制台或社区组件），否则 HPA 取不到 CPU 指标。

**Q：apply 报 ELB 需要指定 flavor？**
A：取消 `infra/elb.tf` 中关于 `l7_flavor_id` 的注释，用 `data "huaweicloud_elb_flavors"` 查
本区域可用 L7 规格后显式赋值。

---

## 14. 贡献指南

欢迎提交 Issue 反馈问题或改进建议。请通过项目 Issue 渠道提交反馈。

---

## 15. 许可证

本实践采用 **MIT No Attribution** 许可证，详见仓库根目录 [`LICENSE`](LICENSE) 文件。


本项目基于 MIT 许可证开源。

---

## 16. 联系方式 / 维护者
| 项 | 内容 |
|---|---|
| **创建者** | [dgc-git](https://github.com/dgc-git) |
| **维护者** | [dgc-git](https://github.com/dgc-git) |
| **联系方式** | GitHub Issues / PR（见[第 14 节](#14-贡献指南)） |
