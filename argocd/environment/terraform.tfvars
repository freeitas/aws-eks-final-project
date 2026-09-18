project_name = "aws-eks-final-project"
region       = "us-east-1"

tags = {
  "Project"     = "aws-eks-final-project"
  "Environment" = "control-plane"
  "ManagedBy"   = "terraform"
}

argocd_cluster_name = "argocd"
argocd_namespace    = "argocd"
argocd_release_name = "argocd"

argocd_chart_repository = "https://argoproj.github.io/argo-helm"
argocd_chart_name       = "argo-cd"
argocd_chart_version    = "7.7.11"

argocd_host            = "argocd.example.com"
argocd_server_insecure = true

argocd_controller_replicas      = 2
argocd_server_replicas          = 2
argocd_repo_server_replicas     = 2
argocd_application_set_replicas = 2
argocd_redis_ha_enabled         = true

argocd_service_accounts = {
  "controller"      = "argocd-application-controller"
  "server"          = "argocd-server"
  "repo_server"     = "argocd-repo-server"
  "application_set" = "argocd-applicationset-controller"
}

ingress_class_name = "alb"
helm_timeout       = 900
argo_api_group     = "argoproj.io"

argocd_ingress_annotations = {
  "alb.ingress.kubernetes.io/scheme"           = "internet-facing"
  "alb.ingress.kubernetes.io/target-type"      = "ip"
  "alb.ingress.kubernetes.io/listen-ports"     = "[{\"HTTP\": 80}, {\"HTTPS\": 443}]"
  "alb.ingress.kubernetes.io/ssl-redirect"     = "443"
  "alb.ingress.kubernetes.io/backend-protocol" = "HTTP"
  "alb.ingress.kubernetes.io/healthcheck-path" = "/healthz"
  "alb.ingress.kubernetes.io/group.name"       = "argocd-control-plane"
}

prod_01_cluster_name = "prod-01"

prod_01_cluster_labels = {
  "environment" = "production"
  "cluster"     = "prod-01"
  "rotation"    = "active"
}

prod_02_cluster_name = "prod-02"

prod_02_cluster_labels = {
  "environment" = "production"
  "cluster"     = "prod-02"
  "rotation"    = "active"
}

cluster_generator_match_labels = {
  "environment" = "production"
}

argo_project_name                    = "production"
argo_project_additional_source_repos = []

application_set_name         = "workloads"
applications_repo_url        = "https://github.com/argoproj/argocd-example-apps.git"
applications_target_revision = "HEAD"
applications_path            = "guestbook"
applications_namespace       = "workloads"

application_sync_prune     = true
application_sync_self_heal = true
