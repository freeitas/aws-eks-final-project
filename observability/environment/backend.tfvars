bucket         = "eks-multicluster-tfstate"
key            = "observability/terraform.tfstate"
region         = "us-east-1"
dynamodb_table = "eks-multicluster-tfstate-lock"
encrypt        = true
