bucket         = "eks-final-project-tfstate"
key            = "clusters/prod-02/terraform.tfstate"
region         = "us-east-1"
dynamodb_table = "eks-final-project-tfstate-lock"
encrypt        = true
