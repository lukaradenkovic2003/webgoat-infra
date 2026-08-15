Webgoat-infra

Infrastructure-as-Code repository for the DevSecOps demo project. Contains the Terraform code that provisions the full AWS environment (VPC, EKS, ECR, IAM) and a GitHub Actions pipeline that validates, plans, applies, and (on demand) destroys it.

This is the first of three repositories in the project:

Repo	Role
webgoat-infra (this repo)	AWS infrastructure (Terraform)
WebGoat	Application code + DevSecOps CI pipeline
webgoat-helm	Helm chart + ArgoCD GitOps + DAST
Repository contents
.
├── vpc.tf                # VPC, subnets
├── eks.tf                 # EKS cluster + managed node group
├── ecr.tf                   # ECR registry for docker images
├── iam.tf                     # IAM roles (incl. GitHub OIDC role for ECR push, ALB controller role)
├── iam_policy.json              # Policy document for ALB Controller / ECR access
├── cloudflare.tf                   # Cloudflare DNS record + WAF (geo-blocking) rules
├── providers.tf                       # AWS + Cloudflare providers
├── variables.tf                          # Input variables (project_name, node sizing, etc.)
├── outputs.tf                               # Outputs (eks_cluster_name, alb_controller_role_arn, vpc_id...)
├── bootstrap/                                  # Bootstrap config (e.g. remote state backend)
└── .github/workflows/terraform.yml                # CI/CD pipeline (validate → plan → apply → destroy)
What gets provisioned
VPC with private subnets for EKS nodes
EKS cluster (eks_managed_node_groups, ON_DEMAND instances, AL2023 AMI)
ECR registry for storing the application's Docker images
IAM roles, including the role GitHub Actions assumes via OIDC to push to ECR (github-actions-ecr-push) and the role for the AWS Load Balancer Controller (IRSA)
Cloudflare DNS record (proxied) and WAF rules for geo-restricting access to the origin
CI/CD Pipeline (.github/workflows/terraform.yml)

Triggers on push/PR to main (only when .tf files change), plus manually via workflow_dispatch with an action choice (plan / apply / destroy).

Jobs
validate — terraform fmt -check, terraform validate
plan — terraform plan, plan output saved as an artifact (runs for both PRs and pushes to main)
apply — runs only on push to main (or manually via workflow_dispatch: action=apply):
terraform apply -auto-approve
Installs the Helm CLI
Reads eks_cluster_name, alb_controller_role_arn, and vpc_id from Terraform outputs
Updates the kubeconfig and deploys the AWS Load Balancer Controller via Helm into the kube-system namespace, wired to the IRSA role through a service account annotation
Sends a Slack notification on apply success/failure
destroy — runs only manually via workflow_dispatch: action=destroy; runs terraform destroy -auto-approve and sends a Slack notification with the result status

Note: the plan job effectively doubles as drift detection, since every push/PR runs terraform plan against the live AWS state and surfaces any differences. There is currently no separate scheduled (cron) job that runs plan on its own and sends a Slack alert independent of a push/PR. If you need true "background" drift detection (e.g. once a day), add a schedule: trigger to a workflow that calls the plan job and posts to Slack without an apply step.

GitHub Secrets & Variables

Repository secrets:

Secret	Purpose
AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY	AWS access for Terraform
CLOUDFLARE_API_TOKEN	Managing DNS/WAF via the Cloudflare provider
SLACK_WEBHOOK_URL	Sending notifications to the Slack channel

Repository variables:

Variable	Purpose
AWS_DEFAULT_REGION	AWS region (us-east-1)
CLOUDFLARE_ZONE_ID	Cloudflare zone for DNS/WAF resources
Running locally
bash
terraform init
terraform plan
terraform apply

To tear down infrastructure, use only the GitHub Actions workflow_dispatch with action: destroy (controlled deletion — it never runs automatically on push).

Relationship to the other repositories
This repo creates the ECR registry that the WebGoat repo's pipeline pushes images to
This repo creates the EKS cluster that webgoat-helm (via ArgoCD) deploys the application onto
The Cloudflare configuration here (DNS + WAF) is the "edge" layer in front of the ALB Ingress defined in webgoat-helm
