variable "region" {
  description = "AWS region where the ArgoCD control plane cluster lives."
  type        = string
}

variable "project_name" {
  description = "Name prefix applied to every IAM resource created by this root."
  type        = string
}

variable "tags" {
  description = "Tags applied to every taggable AWS resource created by this root."
  type        = map(string)
  default     = {}
}

variable "argocd_cluster_name" {
  description = "EKS cluster name of the control plane, used to read the /eks/<name>/* parameters written by the clusters root."
  type        = string
}

variable "argocd_namespace" {
  description = "Kubernetes namespace where ArgoCD and its cluster secrets are installed."
  type        = string
  default     = "argocd"
}

variable "argocd_release_name" {
  description = "Helm release name for the ArgoCD installation."
  type        = string
  default     = "argocd"
}

variable "argocd_chart_repository" {
  description = "Helm repository that serves the ArgoCD chart."
  type        = string
}

variable "argocd_chart_name" {
  description = "Name of the ArgoCD Helm chart."
  type        = string
  default     = "argo-cd"
}

variable "argocd_chart_version" {
  description = "Pinned version of the ArgoCD Helm chart."
  type        = string
}

variable "argocd_host" {
  description = "Hostname the ArgoCD API and UI are served on through the shared ALB."
  type        = string
}

variable "argocd_server_insecure" {
  description = "Run argocd-server without in-cluster TLS because the ALB terminates TLS in front of it."
  type        = bool
  default     = true
}

variable "argocd_controller_replicas" {
  description = "Replica count for the ArgoCD application controller."
  type        = number
  default     = 2
}

variable "argocd_server_replicas" {
  description = "Replica count for the ArgoCD API server."
  type        = number
  default     = 2
}

variable "argocd_repo_server_replicas" {
  description = "Replica count for the ArgoCD repo server."
  type        = number
  default     = 2
}

variable "argocd_application_set_replicas" {
  description = "Replica count for the ArgoCD ApplicationSet controller."
  type        = number
  default     = 2
}

variable "argocd_redis_ha_enabled" {
  description = "Enable the highly available Redis deployment shipped with the ArgoCD chart."
  type        = bool
  default     = true
}

variable "argocd_service_accounts" {
  description = "Service account name the chart creates for each ArgoCD component, keyed by component. The same names are what the IRSA trust policy allows, so the two can never drift."
  type        = map(string)
  default = {
    controller      = "argocd-application-controller"
    server          = "argocd-server"
    repo_server     = "argocd-repo-server"
    application_set = "argocd-applicationset-controller"
  }
}

variable "argocd_ingress_annotations" {
  description = "Annotations placed on the ArgoCD server Ingress so the load balancer controller provisions the ALB."
  type        = map(string)
}

variable "ingress_class_name" {
  description = "Ingress class used by the ArgoCD server Ingress."
  type        = string
  default     = "alb"
}

variable "helm_timeout" {
  description = "Seconds to wait for the ArgoCD Helm release to converge."
  type        = number
  default     = 900
}

variable "argo_api_group" {
  description = "API group of the ArgoCD custom resources, also used to build the cluster secret label key."
  type        = string
  default     = "argoproj.io"
}

variable "prod_01_cluster_name" {
  description = "EKS cluster name of the first production cluster, used to read its /eks/<name>/* parameters and to name its ArgoCD cluster secret."
  type        = string
}

variable "prod_01_cluster_labels" {
  description = "Labels placed on the ArgoCD cluster secret of the first production cluster for the ApplicationSet cluster generator to select on."
  type        = map(string)
}

variable "prod_02_cluster_name" {
  description = "EKS cluster name of the second production cluster, used to read its /eks/<name>/* parameters and to name its ArgoCD cluster secret."
  type        = string
}

variable "prod_02_cluster_labels" {
  description = "Labels placed on the ArgoCD cluster secret of the second production cluster for the ApplicationSet cluster generator to select on."
  type        = map(string)
}

variable "argo_project_name" {
  description = "Name of the ArgoCD AppProject the generated Applications belong to."
  type        = string
}

variable "argo_project_additional_source_repos" {
  description = "Repositories the AppProject may pull from on top of applications_repo_url, which is always allowed."
  type        = list(string)
  default     = []
}

variable "application_set_name" {
  description = "Name of the ApplicationSet whose cluster generator fans one Application out to every registered production cluster."
  type        = string
}

variable "applications_repo_url" {
  description = "Git repository the generated Applications render their manifests from."
  type        = string
  default     = "https://github.com/argoproj/argocd-example-apps.git"
}

variable "applications_target_revision" {
  description = "Git revision the generated Applications track: a branch, a tag or a commit."
  type        = string
  default     = "HEAD"
}

variable "applications_path" {
  description = "Directory inside applications_repo_url holding the manifests the generated Applications sync."
  type        = string
  default     = "guestbook"
}

variable "applications_namespace" {
  description = "Namespace the generated Applications deploy into on each production cluster."
  type        = string
}

variable "cluster_generator_match_labels" {
  description = "Labels the ApplicationSet cluster generator matches against the registered cluster secrets."
  type        = map(string)
}

variable "application_sync_prune" {
  description = "Let the generated Applications delete resources that disappear from the desired state."
  type        = bool
  default     = true
}

variable "application_sync_self_heal" {
  description = "Let the generated Applications revert drift detected on the production clusters."
  type        = bool
  default     = true
}
