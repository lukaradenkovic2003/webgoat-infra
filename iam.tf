# ==========================================
# 1. GITHUB ACTIONS OIDC & ECR ROLE (CI)
# ==========================================

# GitHub OIDC Provider u AWS-u
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"] # Zvanični GitHub OIDC thumbprint
}

# IAM Rola koju GitHub Actions preuzima za push na ECR
resource "aws_iam_role" "github_actions_ecr" {
  name = "webgoat-github-actions-ecr-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" : "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" : [
              "repo:lukaradenkovic2003/*:*",
              "repo:lukaradenkovic2003@*/*:*"
            ]
          }
        }
      }
    ]
  })
}

# Dozvola za GitHub Actions za rad sa ECR repozitorijumom
resource "aws_iam_role_policy_attachment" "github_ecr_policy" {
  role       = aws_iam_role.github_actions_ecr.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}


# ==========================================
# 2. EKS CLUSTER & NODE GROUP IAM ROLES
# ==========================================
# Napomena: terraform-aws-modules/eks/aws v20 modul (u eks.tf) automatski
# pravi svoje IAM role za cluster i node group preko eks_managed_node_groups
# konfiguracije. Ovi ručni blokovi ispod NISU korišćeni od strane modula
# (modul pravi sopstvene role interno) — ostavljeni su ovde samo ako ih
# eksplicitno referenciraš negde drugde. Ako ih ne koristiš nigde, slobodno
# ih ukloni da izbegneš nepotrebne/neiskorišćene resurse.

# IAM Rola za EKS Control Plane
resource "aws_iam_role" "eks_cluster" {
  name = "webgoat-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster.name
}

# IAM Rola za EKS Worker Node-ove
resource "aws_iam_role" "eks_nodes" {
  name = "webgoat-eks-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "eks_container_registry_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_nodes.name
}


# ==========================================
# 3. AWS LOAD BALANCER CONTROLLER (IRSA)
# ==========================================

# Polisa za ALB Kontroler (učitava lokalni iam_policy.json)
resource "aws_iam_policy" "alb_controller" {
  name        = "AWSLoadBalancerControllerIAMPolicy"
  path        = "/"
  description = "IAM policy for AWS Load Balancer Controller"
  policy      = file("${path.module}/iam_policy.json")
}

# IAM Rola za ServiceAccount u EKS-u (IRSA)
# Koristi OIDC provider koji EKS modul već automatski kreira za IRSA —
# ne pravimo novi aws_iam_openid_connect_provider resurs ovde.
resource "aws_iam_role" "alb_controller" {
  name = "webgoat-alb-controller-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
        Condition = {
          StringEquals = {
            "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub" : "system:serviceaccount:kube-system:aws-load-balancer-controller",
            "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:aud" : "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "alb_controller_attach" {
  role       = aws_iam_role.alb_controller.name
  policy_arn = aws_iam_policy.alb_controller.arn
}