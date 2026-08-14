# ==========================================
# 1. GITHUB ACTIONS OIDC & ECR ROLE (CI)
# ==========================================

# Čitamo postojeći GitHub OIDC Provider sa AWS nalozi umesto kreiranja novog
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
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
          Federated = data.aws_iam_openid_connect_provider.github.arn
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

resource "aws_iam_role_policy_attachment" "github_ecr_policy" {
  role       = aws_iam_role.github_actions_ecr.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

# ==========================================
# 2. AWS LOAD BALANCER CONTROLLER (IRSA)
# ==========================================

resource "aws_iam_policy" "alb_controller" {
  name        = "AWSLoadBalancerControllerIAMPolicy"
  path        = "/"
  description = "IAM policy for AWS Load Balancer Controller"
  policy      = file("${path.module}/iam_policy.json")
}

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