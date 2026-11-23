#!/usr/bin/env bash
# ============================================================================
# 获取 CCE kubeconfig 并部署 Book app（Deployment / Service / HPA）
# ----------------------------------------------------------------------------
# 前置：terraform apply 已完成，且已执行 build-push.sh 推送镜像。
# 需要 huaweicloud CLI 与 kubectl 已在 PATH 中，且已配置好 AK/SK 环境变量。
# ============================================================================
set -euo pipefail

REGION="${HW_REGION:-cn-north-4}"
CLUSTER_ID="${CCE_CLUSTER_ID:?请设置 CCE_CLUSTER_ID（terraform output cce_cluster_id）}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
K8S_DIR="${SCRIPT_DIR}/../k8s"

echo "[*] 获取集群 kubeconfig"
huaweicloud CCE get-credentials --cluster-name "${CLUSTER_ID}" --region "${REGION}" > ~/.kube/config

echo "[*] 部署 Book app 工作负载"
kubectl apply -f "${K8S_DIR}/deployment.yaml"
kubectl apply -f "${K8S_DIR}/service.yaml"
kubectl apply -f "${K8S_DIR}/hpa.yaml"

echo "[*] 等待 Service 分配 ELB 公网 IP（CCE 会基于注解创建监听器/后端池）"
kubectl rollout status deployment/book-app --timeout=120s

echo "[+] 部署完成。查看入口："
kubectl get svc book-app -o wide
echo "访问 http://<EXTERNAL-IP>/ 即可看到 Book app 首页。"
