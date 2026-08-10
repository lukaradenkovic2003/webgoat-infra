variable "aws_region" {
  description = "AWS region za deploy infrastrukture"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Naziv projekta, koristi se za tagovanje resursa"
  type        = string
  default     = "webgoat-devsecops"
}

variable "vpc_cidr" {
  description = "CIDR blok za VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Lista AZ-ova za subnet raspodelu"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "eks_cluster_version" {
  description = "Verzija Kubernetes-a za EKS klaster"
  type        = string
  default     = "1.36"
}

variable "cloudflare_api_token" {
  description = "Cloudflare API token za upravljanje DNS/WAF pravilima"
  type        = string
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID za webgoat-devsecops.xyz"
  type        = string
}
variable "eks_node_instance_type" {
  description = "EC2 instance tip za EKS worker node-ove"
  type        = string
  default     = "t3.micro"
}

variable "eks_node_desired_size" {
  description = "Zeljeni broj worker node-ova"
  type        = number
  default     = 1
}

variable "eks_node_min_size" {
  description = "Minimalan broj worker node-ova"
  type        = number
  default     = 1
}

variable "eks_node_max_size" {
  description = "Maksimalan broj worker node-ova"
  type        = number
  default     = 2
}
