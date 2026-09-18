variable "region" {
  description = "AWS region where the VPC and the EKS cluster are created."
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster and the SSM prefix other roots read from (/eks/<cluster_name>/...). One of prod-01, prod-02, argocd or observability."
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes minor version of the EKS control plane, for example 1.35. Keep it inside the EKS standard support window."
  type        = string
}

variable "vpc_cidr" {
  description = "Primary IPv4 CIDR block of the VPC that hosts this cluster."
  type        = string
}

variable "public_subnets" {
  description = "Public subnets, one per availability zone, used by the NAT gateways and by internet-facing load balancers."
  type = list(object({
    name              = string
    cidr              = string
    availability_zone = string
  }))
}

variable "private_subnets" {
  description = "Private subnets, one per availability zone, where the managed node group and the pods run."
  type = list(object({
    name              = string
    cidr              = string
    availability_zone = string
  }))
}

variable "single_nat_gateway" {
  description = "Create one shared NAT gateway instead of one NAT gateway per public subnet."
  type        = bool
  default     = true
}

variable "service_ipv4_cidr" {
  description = "CIDR block the cluster allocates Kubernetes service IPs from. Must not overlap the VPC CIDR nor the service CIDR of the other clusters."
  type        = string
  default     = null
}

variable "cluster_enabled_log_types" {
  description = "Control plane log types delivered to CloudWatch Logs."
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "cluster_log_retention_in_days" {
  description = "Retention, in days, of the control plane CloudWatch Logs group."
  type        = number
  default     = 30
}

variable "endpoint_public_access_cidrs" {
  description = "CIDR blocks allowed to reach the public Kubernetes API endpoint. The private endpoint stays enabled regardless."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "node_group" {
  description = "Shape of the managed node group: name suffix, instance types, capacity type, AMI type, disk size, scaling bounds, rolling update budget and node labels."
  type = object({
    name            = string
    instance_types  = list(string)
    capacity_type   = string
    ami_type        = string
    disk_size       = number
    min_size        = number
    max_size        = number
    desired_size    = number
    max_unavailable = number
    labels          = map(string)
  })
}

variable "alb_controller" {
  description = "aws-load-balancer-controller Helm release: chart repository, chart version, namespace, service account name and replica count."
  type = object({
    chart_repository = string
    chart_version    = string
    namespace        = string
    service_account  = string
    replica_count    = number
  })
}

variable "cluster_admin_principals" {
  description = "IAM role ARNs granted cluster admin through EKS access entries, such as the role the ArgoCD control plane assumes into this cluster. Empty by default."
  type        = list(string)
  default     = []
}

variable "create_argocd_access_role" {
  description = "Create the IAM role, the EKS access entry and the SSM parameter that let the ArgoCD control plane authenticate against this cluster. Only the production clusters need it, so it stays false for the argocd and observability environments."
  type        = bool
  default     = false
}

variable "argocd_access_role_name" {
  description = "Name of the IAM role the ArgoCD control plane assumes into this cluster. It must match the name the argocd root puts in awsAuthConfig.roleARN. Null falls back to argocd-access-<cluster_name>."
  type        = string
  default     = null
}

variable "argocd_access_trusted_principal_arns" {
  description = "Full IAM principal ARNs allowed to assume the ArgoCD access role of this cluster. Use it when the ArgoCD control plane lives in another account; inside the same account prefer argocd_access_trusted_role_names, which keeps the account id out of the tfvars."
  type        = list(string)
  default     = []
}

variable "argocd_access_trusted_role_names" {
  description = "Names of IAM roles in the caller account allowed to assume the ArgoCD access role of this cluster, normally the ArgoCD control plane role. Each name is expanded to an ARN with data.aws_caller_identity, so no account id is written down."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags applied to every resource created by this root."
  type        = map(string)
  default     = {}
}
