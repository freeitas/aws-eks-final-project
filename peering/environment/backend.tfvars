bucket         = "eks-multicluster-tfstate"
key            = "peering/terraform.tfstate"
region         = "us-east-1"
dynamodb_table = "eks-multicluster-tfstate-lock"
encrypt        = true
