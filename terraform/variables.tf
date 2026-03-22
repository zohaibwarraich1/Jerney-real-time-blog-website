variable "common_tags" {
  type = map(string)
  default = {
    "Application Name" = "jerney-blog-website"
    "Environment"      = "prod"
    "Terraform"        = "true"
    "Managed By"       = "Terraform"
  }
}

variable "AWS_account_id" {
  type    = string
  default = "162499216321"
}

variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnets" {
  type    = list(string)
  default = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

variable "private_subnets" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "public_subnet_suffix" {
  type    = string
  default = "pub"
}

variable "private_subnet_suffix" {
  type    = string
  default = "priv"
}

variable "eks_encryption_policy_name" {
  type    = string
  default = "jerney-cluster-encryption-policy"
}
variable "eks_encryption_policy_use_name_prefix" {
  type    = bool
  default = true
}

variable "eks_endpoint_public_access" {
  type    = bool
  default = true
}

variable "eks_endpoint_private_access" {
  type    = bool
  default = true
}

variable "eks_control_plane_iam_role_use_name_prefix" {
  type    = bool
  default = true
}

variable "eks_control_plane_iam_role_name" {
  type    = string
  default = "EKSAutoClusterRole"
}

variable "eks_control_plane_create_security_group" {
  type    = bool
  default = true
}

variable "eks_node_iam_role_use_name_prefix" {
  type    = bool
  default = true
}

variable "eks_create_node_iam_role" {
  type    = bool
  default = true
}

variable "eks_node_iam_role_name" {
  type    = string
  default = "EKSAutoNodeRole"
}

variable "eks_node_security_group_name" {
  type    = string
  default = "jerney-cluster-node-sg"
}

variable "eks_node_security_group_enable_recommended_rules" {
  type    = bool
  default = true
}

variable "eks_node_security_group_use_name_prefix" {
  type    = bool
  default = true
}

variable "eks_enable_auto_mode_custom_tags" {
  type    = bool
  default = true
}

variable "eks_enable_irsa" {
  type    = bool
  default = true
}

variable "eks_control_plane_security_group_use_name_prefix" {
  type    = bool
  default = true
}

variable "eks_service_ipv4_cidr" {
  type    = string
  default = "10.200.0.0/16"
}

variable "eks_authentication_mode" {
  type    = string
  default = "API"
}

variable "eks_ip_family" {
  type    = string
  default = "ipv4"
}

variable "eks_cluster_upgrade_policy" {
  type = map(string)
  default = {
    support_type = "STANDARD"
  }
}

variable "eks_cluster_name" {
  type    = string
  default = "jerney-cluster"
}

variable "eks_kubernetes_version" {
  type    = string
  default = "1.35"
}

variable "eks_zonal_shift_config" {
  type = object({
    enabled = bool
  })
  default = {
    "enabled" = true
  }
}

variable "eks_addons" {
  type = map(object({
    name                 = optional(string) # will fall back to map key
    before_compute       = optional(bool, false)
    most_recent          = optional(bool, true)
    addon_version        = optional(string)
    configuration_values = optional(string)
    pod_identity_association = optional(list(object({
      role_arn        = string
      service_account = string
    })))
    preserve                    = optional(bool, true)
    resolve_conflicts_on_create = optional(string, "OVERWRITE")
    resolve_conflicts_on_update = optional(string, "OVERWRITE")
    service_account_role_arn    = optional(string)
    timeouts = optional(object({
      create = optional(string)
      update = optional(string)
      delete = optional(string)
    }), {})
    tags = optional(map(string), {})
  }))
  default = {
    "vpc-cni" = {
      name           = "vpc-cni"
      before_compute = false # when false, it will install after compute node
      most_recent    = true  # when true, it will install the most recent version
    },
    "core-dns" = {
      name        = "coredns"
      most_recent = true
    },
    "kube-proxy" = {
      name        = "kube-proxy"
      most_recent = true
    },
    "eks-node-monitoring-agent" = {
      name        = "eks-node-monitoring-agent"
      most_recent = true
    },
    "aws-ebs-csi-driver" = {
      name        = "aws-ebs-csi-driver"
      most_recent = true
    },
    "kube-state-metrics" = {
      name        = "kube-state-metrics"
      most_recent = true
    },
    "metrics-server" = {
      name        = "metrics-server"
      most_recent = true
    },
    "cert-manager" = {
      name        = "cert-manager"
      most_recent = true
    }
  }
}

variable "eks_auto_mode_compute_config" {
  type = object({
    enabled       = bool
    node_pools    = optional(list(string))
    node_role_arn = optional(string)
  })
  default = {
    enabled    = true
    node_pools = ["general-purpose"]
  }
}

variable "eks_enable_cluster_creator_admin_permissions" {
  type    = bool
  default = false
}

variable "eks_access_entries" {
  type = map(object({
    kubernetes_groups = optional(list(string))
    principal_arn     = string
    type              = optional(string, "STANDARD")
    user_name         = optional(string)
    tags              = optional(map(string), {})
    # Access policy association
    policy_associations = optional(map(object({
      policy_arn = string
      access_scope = object({
        namespaces = optional(list(string))
        type       = string
      })
  })), {}) }))

  default = {
    "admin-access" = {
      user_name     = "Zohaib"
      principal_arn = "arn:aws:iam::162499216321:user/Zohaib"
      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }
}

variable "enable_eks_access_entries" {
  type    = bool
  default = true
}


variable "route53_records" {
  type = map(object({
    alias = optional(object({
      evaluate_target_health = optional(bool, false)
      name                   = string
      zone_id                = string
    }))
    allow_overwrite = optional(bool)
    cidr_routing_policy = optional(object({
      collection_id = string
      location_name = string
    }))
    failover_routing_policy = optional(object({
      type = string
    }))
    geolocation_routing_policy = optional(object({
      continent   = optional(string)
      country     = optional(string)
      subdivision = optional(string)
    }))
    geoproximity_routing_policy = optional(object({
      aws_region = optional(string)
      bias       = optional(number)
      coordinates = optional(list(object({
        latitude  = number
        longitude = number
      })))
      local_zone_group = optional(string)
    }))
    health_check_id = optional(string)
    latency_routing_policy = optional(object({
      region = string
    }))
    multivalue_answer_routing_policy = optional(bool)
    name                             = optional(string)
    full_name                        = optional(string)
    records                          = optional(list(string))
    set_identifier                   = optional(string)
    ttl                              = optional(number)
    type                             = string
    weighted_routing_policy = optional(object({
      weight = number
    }))
    timeouts = optional(object({
      create = optional(string)
      update = optional(string)
      delete = optional(string)
    }))
  }))

  default = {
    "caa_record" = {
      # name    = "jerney.zohaibofficial.online"
      full_name = "jerney.zohaibofficial.online"
      ttl       = 300
      type      = "CAA"
      records   = ["0 issue \"letsencrypt.org\"", "0 issuewild \"letsencrypt.org\""]
    }
  }
}

variable "create_route53_module" {
  type    = bool
  default = true
}

variable "create_route53_zone" {
  type    = bool
  default = true
}

variable "route53_force_destroy" {
  type    = bool
  default = true
}

variable "route53_zone_name" {
  type    = string
  default = "jerney.zohaibofficial.online"
}

variable "route53_delegation_resource_name" {
  type    = string
  default = "jerney.zohaibofficial.online-NS"
}

variable "iam_policy_name_prefix" {
  type    = string
  default = "JerneyIamPolicy"
}
variable "enable_gateway_dns" {
  description = "Set to true only AFTER the gateway load balancer is created in K8s"
  type        = bool
  default     = false
}
