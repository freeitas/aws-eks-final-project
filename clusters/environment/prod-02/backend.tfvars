bucket         = "eks-multicluster-tfstate"
key            = "clusters/prod-02/terraform.tfstate"
region         = "us-east-1"
dynamodb_table = "eks-multicluster-tfstate-lock"
encrypt        = true
