# AWS EKS Hardened Modernization & Security Platform

## 🚀 Overview

Migrating 14 legacy sites (WordPress/Static) from shared hosting to a high-security, immutable AWS EKS platform running Bottlerocket OS.

## 🏗️ Architecture (Phase 1: Ongoing)

- **VPC:** 3-Tier Multi-AZ (Public, Private, Data)
- **Security:** Zero-SSH, Private-only Workloads
- **IaC:** Terraform (Modular)

## 🛡️ Hardened Security Features (Phase 1.2)

### 🛰️ Data Perimeter & Networking

- **S3 Gateway Endpoint:** Private routing to S3 within the VPC — no Internet or NAT traversal, reducing cost and attack surface.
- **Data Exfiltration Prevention:** Strict VPC Endpoint Policy that:
  - Allows access only to designated S3 buckets within the AWS Resource Account.
  - Explicitly denies all cross-account S3 traffic, even if IAM credentials are compromised.
- **3-Tier Network Isolation:**
  - `Public` — ALBs & IGW only.
  - `Private` — EKS Nodes & Workloads (no public IP).
  - `Data` — Isolated database tier, egress via NAT for patching only.

### 🧩 IaC Design Patterns

- **Modular Terraform:** VPC, Endpoints, and Security Groups separated for maintainability.
- **Identity-based Hardening:** `aws_caller_identity` for dynamic, zero-hardcoded account referencing.

## 🛠️ Tech Stack

- AWS (EKS, VPC, S3, Bedrock)
- Terraform
- Kubernetes (CKA Standards)
