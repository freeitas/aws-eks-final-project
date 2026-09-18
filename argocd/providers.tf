terraform {
  required_version = ">= 1.5.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = var.tags
  }
}

provider "kubernetes" {
  host                   = data.aws_ssm_parameter.argocd_endpoint.value
  cluster_ca_certificate = base64decode(data.aws_ssm_parameter.argocd_certificate_authority.value)
  token                  = data.aws_eks_cluster_auth.argocd.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_ssm_parameter.argocd_endpoint.value
    cluster_ca_certificate = base64decode(data.aws_ssm_parameter.argocd_certificate_authority.value)
    token                  = data.aws_eks_cluster_auth.argocd.token
  }
}
