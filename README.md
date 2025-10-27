# Multi‑Region Disaster Recovery on AWS (Terraform)

This repo bootstraps a **two‑region DR reference** using Terraform:

- **VPC** in each region (public + private subnets, NAT, basic routing)
- **S3** with **Cross‑Region Replication** (CRR) from Primary → Secondary
- **RDS** in Primary with **Cross‑Region Read Replica** in Secondary (MySQL/Postgres)
- **Route 53** **failover** record pointing to **two regional S3 static websites** (easy to demo failover)
- **CloudWatch + SNS** alarms for Route 53 health and basic RDS metrics
- **CI/CD** examples: `Jenkinsfile` and **GitHub Actions**

> You can extend this later to fail over an ALB/EC2 or EKS service; the DNS failover wiring stays the same.

---

## Quick start (VS Code)

1. **Prereqs**
   - Terraform >= 1.6, AWS CLI v2, an AWS account with admin privileges.
   - A **public hosted zone** (e.g., `example.com`) in Route 53 and the **Hosted Zone ID**.
   - Pick two AWS regions (e.g., `us-east-1` and `us-west-2`).

2. **Configure variables**  
   Copy `.auto.tfvars.example` to `terraform.auto.tfvars` and edit values:
   ```bash
   cp .auto.tfvars.example terraform.auto.tfvars
   ```

3. **Bootstrap**
   ```bash
   terraform init
   terraform validate
   terraform plan
   terraform apply
   ```

4. **Test failover**
   - Upload an `index.html` into the **primary** website bucket. It replicates to the secondary.
   - Note your **CNAME** (`app.<your_domain>`). Open it.  
   - In AWS Console, **disable** the Route 53 **primary health check** → traffic fails over to secondary.  
     Re‑enable to fail back.

5. **Tear down**
   ```bash
   terraform destroy
   ```

> **Tip:** For RDS cross‑region replication, choose **MySQL** or **PostgreSQL** engines. Aurora uses a different pattern (Global Database).

---

## Project layout

```
.
├── README.md
├── Jenkinsfile
├── .github/workflows/terraform.yml
├── .auto.tfvars.example
├── main.tf
├── variables.tf
├── outputs.tf
├── versions.tf
├── modules
│   ├── vpc/
│   ├── s3-crr/
│   ├── rds-cross-region/
│   └── route53-failover/
└── examples/index.html
```

---

## Notes

- The Route 53 records here use **CNAME failover** to two S3 website endpoints because it's simple to demo.  
  Swap those out for ALB/NLB/EKS ingress later (use `A/AAAA Alias` and attach the health check to the primary).

- S3 CRR needs a dedicated **IAM role** (created here) and **versioning** enabled on both buckets.

- Some resources (RDS snapshots, logs, buckets with objects) may block `destroy`; empty buckets or keep snapshots manually if needed.
