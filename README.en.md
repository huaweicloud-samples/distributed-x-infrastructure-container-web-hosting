# distributed-x-infrastructure-container-web-hosting · Containerized Web Application Hosting on CCE

<img src="https://img.shields.io/badge/License-MIT--0-blue.svg" alt="License">
![License](https://img.shields.io/badge/license-MIT-green)
![Cloud](https://img.shields.io/badge/Cloud-HuaweiCloud-blue)
![Status](https://img.shields.io/badge/build-passing-brightgreen)
> Build a highly available, elastically scalable, and observable containerized web application on Huawei Cloud with "VPC + CCE + Dedicated ELB + SWR + LTS" (an nginx static site, book-app, as the example).

## 1. Overview

### Overview

This practice targets developers and operators who want to run containerized web services on Huawei Cloud. It demonstrates how to use only IaC (Terraform) to bring up a production-ready container infrastructure with one command, and provides the full chain of image build, deployment, elastic scaling, and log collection.

---

## 2. Table of Contents

- [1. Overview](#1-overview)
- [2. Table of Contents](#2-table-of-contents)
- [3. Architecture Diagram](#3-architecture-diagram)
- [4. Highlights](#4-highlights)
- [5. Cloud Services Used](#5-cloud-services-used)
- [6. Prerequisites](#6-prerequisites)
- [7. Quick Start](#7-quick-start)
- [8. Step-by-Step Deployment](#8-step-by-step-deployment)
- [9. Usage / Verification](#9-usage--verification)
- [10. Cleanup](#10-cleanup)
- [11. Detailed Explanation](#11-detailed-explanation)
- [12. Dependencies](#12-dependencies)
- [13. FAQ / Troubleshooting](#13-faq--troubleshooting)
- [14. Contributing](#14-contributing)
- [15. License](#15-license)
- [16. Contact / Maintainers](#16-contact--maintainers)

---

## 3. Architecture Diagram

```
Internet users (HTTP :80)
│
┌───────▼───────┐
│ Dedicated ELB │  Bound to an EIP; health check + load balancing
└───────┬───────┘
CCE Service(LoadBalancer) auto-registers Pod backends
┌───────▼───────┐
│ CCE cluster   │  Node pool autoscaling min 1 ~ max 4
│ book-app dep. │  HPA (CPU 80%)
└───────┬───────┘
Container logs → LTS; images ← SWR; outbound → NAT + EIP
```

---

## 4. Highlights

- **Pure IaC**: all infrastructure described in Terraform; `terraform plan/apply` is reproducible.
- **Two-layer elasticity**: node-level autoscaling plus Pod-level HPA to handle business peaks and valleys.
- **Observable out of the box**: container logs are delivered to LTS automatically through an IAM agency, with no extra agent.
- **Controlled specs**: all specifications are explicit; during debugging the ELB inbound rule can be locked to the operations IP.

---

## 5. Cloud Services Used

This practice uses the following Huawei Cloud services:

| Service | Purpose |
|---|---|
| VPC | Private/public subnet isolation |
| CCE | Container orchestration + node pool |
| Dedicated ELB | Public ingress + backend Pod registration |
| SWR | Container image repository |
| OBS | Pipeline artifact bucket |
| LTS | Container stdout/stderr logs |

---

## 6. Prerequisites

- Huawei Cloud account and `HW_ACCESS_KEY` / `HW_SECRET_KEY` (provided from environment variables; do not write them into code or configuration files).
- Installed: Terraform ≥ 1.5, Docker, huaweicloud CLI, kubectl.
- Default region `cn-north-4` (Beijing-4); modify `region` in `infra/variables.tf` as needed.

---

## 7. Quick Start

```bash
export HW_ACCESS_KEY="<HW_ACCESS_KEY>"
export HW_SECRET_KEY="<HW_SECRET_KEY>"
export HW_REGION_NAME="cn-north-4"

cd infra && terraform init && terraform apply
```

After apply completes:

```bash
terraform output elb_public_ip # application public ingress
bash ../src/scripts/build-push.sh # build and push the image to SWR
bash ../src/scripts/deploy.sh # get kubeconfig and deploy the workload
```

---

## 8. Step-by-Step Deployment

See [docs/deployment-guide.md](docs/deployment-guide.md), which contains the complete steps for image build, Service annotation filling, HPA installation, and blue-green release (CodeArts).

---

## 9. Usage / Verification

### Usage / Verification

Verify the web application by checking the Service with `kubectl` and accessing the ELB public address, as described below.

```bash
kubectl get svc book-app -o wide
curl -I http://<elb_public_ip>/
# Expected: HTTP/1.1 200
```

Open `http://<elb_public_ip>/` in a browser to see the book-app homepage.

After deployment, follow these steps to verify that the business functionality works before considering the delivery complete.

---

## 10. Cleanup

```bash
kubectl delete -f src/k8s/ # release the workload and ELB backends first
terraform destroy # reclaim cloud resources
```

---

## 11. Detailed Explanation

- Architecture and component responsibilities: [docs/architecture.md](docs/architecture.md)
- Full deployment flow: [docs/deployment-guide.md](docs/deployment-guide.md)
- Quality gates and constraints: all resource specifications are explicit for reproducibility; during debugging, lock ELB inbound to the operations IP; only one private route table is used to comply with VPC quota constraints.

---

## 12. Dependencies

- Terraform ≥ 1.5
- huaweicloud Provider ~> 1.70
- kubectl / docker / swr-login (to build and push images)
- This practice is built on public Huawei Cloud services such as CCE/ECS/ELB/SWR.

Repository structure:

```
.
├── docs/        # Huawei Cloud practice documentation
├── infra/       # Terraform + huaweicloud Provider
├── src/         # Application code and scripts
└── README.md
```

---

## 13. FAQ / Troubleshooting

### FAQ

**Q: ELB health check is always unhealthy?**

A: Confirm the node security group allows port 80 from the ELB security group (this practice created the `ecs_ingress_from_elb` rule) and the Pod readiness probe returns 200.

**Q: HPA not taking effect?**

A: The cluster needs the metrics-server add-on (from the CCE console or a community component); otherwise HPA cannot obtain CPU metrics.

**Q: apply reports that ELB requires a flavor?**

A: Uncomment the `l7_flavor_id` setting in `infra/elb.tf`, use `data "huaweicloud_elb_flavors"` to find available L7 flavors in the region, then assign one explicitly.

---

## 14. Contributing

Issues are welcome for bug reports or improvement suggestions. Please submit feedback through the project's issue channel.

---

## 15. License

This practice is licensed under **MIT No Attribution**, see the [`LICENSE`](LICENSE) file in the repository root.

This project is open source under the MIT license.

---

## 16. Contact / Maintainers
| Item | Content |
|---|---|
| **Creator** | [dgc-git](https://github.com/dgc-git) |
| **Maintainer** | [dgc-git](https://github.com/dgc-git) |
| **Contact** | GitHub Issues / PR (see [Section 14](#14-contributing)) |
