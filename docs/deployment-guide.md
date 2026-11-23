# 部署指导书 — 基于 CCE 的容器 Web 应用

> 预计耗时：首次约 30–45 分钟（含镜像构建与集群就绪）。前置：已安装 Terraform ≥1.5
> Docker、huaweicloud CLI、kubectl，并配置好访问密钥环境变量。

## 0. 准备凭据（环境变量，勿硬编码）

```bash
export HW_ACCESS_KEY="<HW_ACCESS_KEY>" # 你的 Access Key
export HW_SECRET_KEY="<HW_SECRET_KEY>" # 你的 Secret Key
export HW_REGION_NAME="cn-north-4" # 目标区域
```

## 1. 部署基础设施（Terraform）

```bash
cd infra
terraform init
terraform validate
terraform plan # 确认 27 个资源、无错误
terraform apply # 创建 VPC/CCE/ELB/SWR/LTS 等
```

apply 完成后记录以下输出（后续步骤要用）：

```bash
terraform output elb_id # ELB ID
terraform output elb_subnet_id # ELB 所在公网子网 ID
terraform output elb_public_ip # 应用公网入口
terraform output swr_image_path # book-app 镜像路径
terraform output cce_cluster_id # CCE 集群 ID
```

## 2. 构建并推送镜像到 SWR

```bash
cd ../src
# 设置镜像相关环境变量（SWR 登录令牌从控制台「容器镜像服务-我的凭证」获取）
export HW_REGION=cn-north-4
export SWR_ORG=bookapp
export SWR_LOGIN_TOKEN=<SWR_LOGIN_TOKEN>
export HW_ACCESS_KEY=<HW_ACCESS_KEY> # build-push.sh 登录 SWR 用
bash scripts/build-push.sh
```

脚本会构建 `src/app/Dockerfile` 并把镜像推送到 SWR。记下输出的镜像地址。

## 3. 部署工作负载到 CCE

1. 编辑 `src/k8s/deployment.yaml`，把 `image: <SWR_IMAGE_PATH>` 替换为上一步的真实镜像地址。
2. 编辑 `src/k8s/service.yaml`，把注解里的两个占位符替换为第 1 步的输出：
- `kubernetes.io/loadbalance.id: "<ELB_ID>"`
- `kubernetes.io/elb.subnet-id: "<ELB_SUBNET_ID>"`
3. 执行部署：

```bash
export CCE_CLUSTER_ID=<第1步的 cce_cluster_id>
bash scripts/deploy.sh
```

`deploy.sh` 会获取 kubeconfig 并依次应用 Deployment / Service / HPA。
（若集群尚未安装 metrics-server，HPA 不生效但不影响基础运行；可在 CCE 控制台安装。）

## 4. 验证

```bash
kubectl get svc book-app -o wide # 查看 EXTERNAL-IP（= ELB 公网 IP）
curl -I http://<elb_public_ip>/ # 应返回 200
```

浏览器访问 `http://<elb_public_ip>/` 即可看到 book-app 首页。

## 5. 蓝绿发布（可选，进阶）

生产环境可使用 **CodeArts Pipeline / Build / Deploy**（SaaS）实现蓝绿发布。简要思路：

1. 在 CodeArts 创建源码仓库（导入 GitHub 或 CodeHub）。
2. 构建任务：执行 `src/scripts/build-push.sh` 推送带版本标签的镜像到 SWR。
3. 部署任务：用新镜像创建第二个 Deployment（`book-app-green`），就绪后切换 Service 的
selector / 或切换 ELB 后端池，实现零停机切换。
详细流水线编排请参考华为云 CodeArts 文档。

## 6. 清理

```bash
# 先删工作负载，避免占用 ELB/节点
kubectl delete -f src/k8s/
terraform destroy # 回收所有云资源
```

> 销毁后请到控制台 API 直查 EIP / ELB / EVS 无残留（尤其是状态 available 的孤儿云硬盘）。
