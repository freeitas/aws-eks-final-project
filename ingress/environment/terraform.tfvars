region      = "us-east-1"
project     = "eks-multicluster"
name_prefix = "efp"

# The ALB and both target groups live in this cluster's VPC; the other
# production cluster reaches its target group over VPC peering.
alb_vpc_cluster_name = "prod-01"
prod_01_cluster_name = "prod-01"
prod_02_cluster_name = "prod-02"

# Active/active, 50/50. Set one side to 0 and apply to drain that cluster.
prod_01_weight = 50
prod_02_weight = 50

dns_name                  = "app.example.com"
route53_zone_name         = "example.com"
subject_alternative_names = []
additional_host_headers   = []
listener_rule_priority    = 100

ssl_policy                 = "ELBSecurityPolicy-TLS13-1-2-2021-06"
idle_timeout               = 60
enable_deletion_protection = false
ingress_cidr_blocks        = ["0.0.0.0/0"]

# The health check must match what the pods registered by the TargetGroupBinding
# actually serve. "traffic-port" probes the same port the group forwards to, and
# "/" is the neutral default: nothing in this project installs a service mesh or
# an ingress gateway with its own probe endpoint. Narrow the path to the
# workload's own probe once it is known.
target_port                      = 80
health_check_path                = "/"
health_check_port                = "traffic-port"
health_check_matcher             = "200"
health_check_interval            = 15
health_check_timeout             = 5
health_check_healthy_threshold   = 2
health_check_unhealthy_threshold = 2
deregistration_delay             = 30

target_group_stickiness_enabled  = false
target_group_stickiness_duration = 3600
listener_stickiness_enabled      = false
listener_stickiness_duration     = 3600

enable_access_logs         = true
access_logs_prefix         = "alb"
access_logs_retention_days = 90

tags = { Environment = "production", Owner = "platform" }
