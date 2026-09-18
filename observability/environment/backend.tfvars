bucket         = "eks-final-project-tfstate"
key            = "observability/terraform.tfstate"
region         = "us-east-1"
dynamodb_table = "eks-final-project-tfstate-lock"
encrypt        = true
