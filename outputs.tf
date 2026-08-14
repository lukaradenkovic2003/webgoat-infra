output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnets
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnets
}

output "eks_cluster_name" {
  description = "Naziv EKS klastera"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = module.eks.cluster_endpoint
}

output "ecr_repository_url" {
  description = "URL ECR repozitorijuma za WebGoat sliku"
  value       = aws_ecr_repository.webgoat.repository_url
}

output "cloudflare_secret_header" {
  description = "Tajni token koji ALB očekuje u X-Cloudflare-Secret headeru"
  value       = random_password.cloudflare_alb_secret.result
  sensitive   = true
}

output "alb_controller_role_arn" {
  value = aws_iam_role.alb_controller.arn
}# trigger run
