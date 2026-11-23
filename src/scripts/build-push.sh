#!/usr/bin/env bash
# ============================================================================
# 构建并推送 Book app 镜像到 SWR
# ----------------------------------------------------------------------------
# 安全：凭据一律从环境变量读取，切勿硬编码 AK/SK。
#   export HW_REGION=cn-north-4
#   export HW_ACCESS_KEY=<你的 Access Key>
#   export HW_SECRET_KEY=<你的 Secret Key>
#   export SWR_LOGIN_TOKEN=<SWR 登录密码/临时令牌，来自控制台「容器镜像服务-我的凭证」>
# 或使用统一 CLI 生成临时登录指令：
#   huaweicloud SWR create-secret ...   # 详见华为云 SWR 文档
# ============================================================================
set -euo pipefail

REGION="${HW_REGION:-cn-north-4}"
ORG="${SWR_ORG:-bookapp}"
REPO="book_app"
TAG="${IMAGE_TAG:-latest}"
SWR_DOMAIN="swr.${REGION}.myhuaweicloud.com"
IMAGE_PATH="${SWR_DOMAIN}/${ORG}/${REPO}:${TAG}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="${SCRIPT_DIR}/../app"

echo "[*] 构建镜像: ${IMAGE_PATH}"
docker build -t "${IMAGE_PATH}" "${APP_DIR}"

echo "[*] 登录 SWR: ${SWR_DOMAIN}"
# SWR 登录用户名格式为 <region>@<IAM用户名>（注意：不是 AK 本身），
# 密码为 SWR 临时登录令牌。二者都由「生成临时登录指令」接口返回的
# X-Swr-Dockerlogin 头给出，形如：docker login -u cn-north-4@XXXX -p <token> <domain>
# 直接用该完整命令登录最稳妥；这里拆成两个变量供需要脚本化的场景使用。
docker login -u "${SWR_LOGIN_USER:-${REGION}@CHANGE_ME}" -p "${SWR_LOGIN_TOKEN}" "${SWR_DOMAIN}"

echo "[*] 推送镜像"
docker push "${IMAGE_PATH}"

echo "[+] 完成。镜像地址: ${IMAGE_PATH}"
echo "    请将其填入 src/k8s/deployment.yaml 的 image 字段（替换 <SWR_IMAGE_PATH>）。"
