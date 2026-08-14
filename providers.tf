terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.12" # Omogućava korišćenje Helm verzije 3.x bez konflikta sa lock fajlom
    }
  }

  backend "s3" {
    bucket         = "webgoat-devsecops-tfstate"
    key            = "infra/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "webgoat-devsecops-tf-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}

provider "cloudflare" {
  email   = "lukaradenkovic@libero.it"
  api_key = var.cloudflare_api_token
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
}

provider "helm" {
  kubernetes = {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
      command     = "aws"
    }
  }
}

