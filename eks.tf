module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "${var.project_name}-cluster"
  cluster_version = var.eks_cluster_version

  cluster_endpoint_public_access = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  enable_irsa = true

  eks_managed_node_groups = {
    default = {
      min_size     = var.eks_node_min_size
      max_size     = var.eks_node_max_size
      desired_size = var.eks_node_desired_size

      instance_types = [var.eks_node_instance_type]
      ami_type       = "AL2023_x86_64_STANDARD" # <-- OVU LINIJU DODAJ/DOPUNI

      capacity_type = "ON_DEMAND"
    }
  }

  tags = {
    Project     = var.project_name
    Environment = "production"
  }
}