# Book app 容器镜像：基于官方 nginx，将静态页面 index.html 放入默认站点目录。
FROM nginx:stable-alpine

COPY index.html /usr/share/nginx/html/index.html

EXPOSE 80

# 容器以非 root 运行、健康检查由 K8s 探针接管（见 src/k8s/deployment.yaml）
HEALTHCHECK --interval=10s --timeout=3s --retries=3 \
  CMD wget -qO- http://127.0.0.1:80/ >/dev/null 2>&1 || exit 1
