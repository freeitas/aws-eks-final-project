variable "region" {
  description = "AWS region hosting the shared ingress ALB. Every root in this project is pinned to a single region."
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Project name, applied as a tag to every resource created by this root."
  type        = string
  default     = "eks-multicluster"
}

variable "name_prefix" {
  description = "Prefix for the ALB, target group, security group and log bucket names. Keep it short: a target group is named <name_prefix>-<cluster>-<target_port> and an ALB target group name is capped at 32 characters."
  type        = string
  default     = "efp"
}

variable "tags" {
  description = "Extra tags merged into the default tags applied to every resource created by this root."
  type        = map(string)
  default     = {}
}

variable "alb_vpc_cluster_name" {
  description = "Cluster whose VPC hosts the shared ALB. Its /eks/<cluster>/vpc_id SSM parameter is read and both target groups are created in that VPC; the other production cluster is reached over VPC peering."
  type        = string
  default     = "prod-01"
}

variable "prod_01_cluster_name" {
  description = "Name of the first production cluster, used to name and tag its target group."
  type        = string
  default     = "prod-01"
}

variable "prod_02_cluster_name" {
  description = "Name of the second production cluster, used to name and tag its target group."
  type        = string
  default     = "prod-02"
}

variable "prod_01_weight" {
  description = "Relative share of requests the listener forwards to the first production cluster. Set it to 0 to drain that cluster out of rotation. The two weights do not have to add up to 100."
  type        = number
  default     = 50

  validation {
    condition     = var.prod_01_weight >= 0 && var.prod_01_weight <= 999
    error_message = "prod_01_weight must be between 0 and 999, the range an ALB forward action accepts."
  }
}

variable "prod_02_weight" {
  description = "Relative share of requests the listener forwards to the second production cluster. Set it to 0 to drain that cluster out of rotation. The two weights do not have to add up to 100."
  type        = number
  default     = 50

  validation {
    condition     = var.prod_02_weight >= 0 && var.prod_02_weight <= 999
    error_message = "prod_02_weight must be between 0 and 999, the range an ALB forward action accepts."
  }
}

variable "dns_name" {
  description = "Public hostname served by the ALB. It is the ACM certificate subject, the Route 53 alias record and the host header the listener rule matches."
  type        = string
}

variable "route53_zone_name" {
  description = "Name of the public Route 53 hosted zone that owns dns_name. The zone is looked up, not created, and holds the alias and certificate validation records."
  type        = string
}

variable "additional_host_headers" {
  description = "Extra host headers the listener rule matches besides dns_name. Each one must be covered by the certificate, so add it to subject_alternative_names too."
  type        = list(string)
  default     = []
}

variable "subject_alternative_names" {
  description = "Additional names on the ACM certificate besides dns_name. Every name must live in the same hosted zone, because validation records are written there."
  type        = list(string)
  default     = []
}

variable "listener_rule_priority" {
  description = "Priority of the host based listener rule. Lower numbers are evaluated first."
  type        = number
  default     = 100

  validation {
    condition     = var.listener_rule_priority >= 1 && var.listener_rule_priority <= 50000
    error_message = "listener_rule_priority must be between 1 and 50000."
  }
}

variable "ssl_policy" {
  description = "Security policy of the HTTPS listener, controlling the TLS versions and ciphers offered to clients."
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "idle_timeout" {
  description = "Seconds an idle connection is kept open before the ALB closes it."
  type        = number
  default     = 60
}

variable "enable_deletion_protection" {
  description = "Whether the ALB refuses to be deleted. Left off so the teardown pipeline can destroy the root; turn it on for a long lived environment."
  type        = bool
  default     = false
}

variable "ingress_cidr_blocks" {
  description = "IPv4 ranges allowed to reach the ALB on ports 80 and 443."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "target_port" {
  description = "Port the target groups forward to on the registered pods. It must be the containerPort the workload listens on, because the AWS Load Balancer Controller registers pod IPs directly through a TargetGroupBinding in each cluster and no kube-proxy hop remaps the port."
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "Path the ALB requests on each registered pod. It must be a path the workload actually answers with one of health_check_matcher's status codes, otherwise every target stays unhealthy and the ALB returns 503. The default is \"/\" because no root in this project installs a service mesh or a gateway with a known probe endpoint; point it at the workload's own probe (for example \"/healthz\") once that is known."
  type        = string
  default     = "/"

  validation {
    condition     = startswith(var.health_check_path, "/")
    error_message = "health_check_path must start with a slash."
  }
}

variable "health_check_port" {
  description = "Port the health check connects to on each registered pod. \"traffic-port\" means the same port the target group serves on (target_port) and is the default, so the probe follows target_port automatically. Override it with a literal port number only if the workload exposes a separate probe listener on that port."
  type        = string
  default     = "traffic-port"

  validation {
    condition     = var.health_check_port == "traffic-port" || can(tonumber(var.health_check_port))
    error_message = "health_check_port must be \"traffic-port\" or a port number written as a string."
  }
}

variable "health_check_matcher" {
  description = "HTTP status codes that count as a healthy response."
  type        = string
  default     = "200"
}

variable "health_check_interval" {
  description = "Seconds between two health checks of the same target."
  type        = number
  default     = 15
}

variable "health_check_timeout" {
  description = "Seconds the ALB waits for a health check response before calling it a failure."
  type        = number
  default     = 5
}

variable "health_check_healthy_threshold" {
  description = "Consecutive successful checks before an unhealthy target is put back in rotation."
  type        = number
  default     = 2
}

variable "health_check_unhealthy_threshold" {
  description = "Consecutive failed checks before a target is taken out of rotation."
  type        = number
  default     = 2
}

variable "deregistration_delay" {
  description = "Seconds the ALB keeps draining in flight requests to a target after it is deregistered."
  type        = number
  default     = 30
}

variable "target_group_stickiness_enabled" {
  description = "Whether a target group pins a client to one registered pod. Off by default: it assumes the workload is stateless, and pinning only slows down pod level rollouts."
  type        = bool
  default     = false
}

variable "target_group_stickiness_duration" {
  description = "Lifetime in seconds of the target group stickiness cookie."
  type        = number
  default     = 3600
}

variable "listener_stickiness_enabled" {
  description = "Whether the weighted forward pins a client to one cluster. Off by default: while it is on, a cluster drained to weight 0 keeps serving clients that already hold the cookie until it expires."
  type        = bool
  default     = false
}

variable "listener_stickiness_duration" {
  description = "Lifetime in seconds of the cookie that pins a client to one cluster. It is also the worst case time a drained cluster still receives requests."
  type        = number
  default     = 3600

  validation {
    condition     = var.listener_stickiness_duration >= 1 && var.listener_stickiness_duration <= 604800
    error_message = "listener_stickiness_duration must be between 1 and 604800 seconds."
  }
}

variable "enable_access_logs" {
  description = "Whether the ALB writes access logs to the bucket this root creates. The bucket is created either way."
  type        = bool
  default     = true
}

variable "access_logs_prefix" {
  description = "Key prefix under which the ALB writes its access logs in the log bucket."
  type        = string
  default     = "alb"

  validation {
    condition     = length(var.access_logs_prefix) > 0
    error_message = "access_logs_prefix must not be empty: the bucket policy only grants writes under that prefix."
  }
}

variable "access_logs_retention_days" {
  description = "Days an access log object is kept before the bucket lifecycle rule expires it."
  type        = number
  default     = 90
}
