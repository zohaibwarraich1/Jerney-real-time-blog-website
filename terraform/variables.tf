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
  default = "154810815000"
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
      principal_arn = "arn:aws:iam::154810815000:user/Zohaib"
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
      full_name = "jerney.zohaibofficial.online"
      ttl       = 300
      type      = "CAA"
      records = [
        "0 issue \"letsencrypt.org\"",
        "0 issuewild \"letsencrypt.org\"",
        "0 issue \"amazon.com\"",
        "0 issuewild \"amazon.com\""
      ]
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

variable "domain_name_aliases" {
  type    = list(string)
  default = ["www.jerney.zohaibofficial.online", "jerney.zohaibofficial.online"]
}

variable "domain_name" {
  type    = string
  default = "jerney.zohaibofficial.online"
}

variable "iam_policy_name_prefix" {
  type    = string
  default = "JerneyIamPolicy"
}

variable "enable_gateway_dns" {
  description = "Set to true only AFTER the gateway load balancer is created in K8s"
  type        = bool
  default     = true
}

variable "rds_db_name" {
  type    = string
  default = "jerneydb"
}

variable "rds_db_pass" {
  type    = string
  default = "test123456"
}

variable "rds_db_user" {
  type    = string
  default = "dbadmin"
}

variable "rds_db_port" {
  type    = string
  default = "5432"
}

variable "rds_manage_master_user_password" {
  type    = bool
  default = false
}

variable "rds_multi_az" {
  type    = bool
  default = true
}

variable "rds_availability_zone" {
  type    = string
  default = null
}

variable "rds_iam_database_authentication_enabled" {
  type    = bool
  default = false
}

variable "rds_storage_encrypted" {
  type    = bool
  default = true
}

variable "rds_storage_type" {
  type    = string
  default = "gp3"
}

variable "rds_family" {
  type    = string
  default = "postgres16"
}

variable "rds_instance_class" {
  type    = string
  default = "db.t3.micro" # Free Tier eligible instance
}

variable "rds_engine" {
  type    = string
  default = "postgres"
}

variable "rds_engine_version" {
  type    = string
  default = "16"
}

variable "rds_create_db_subnet_group" {
  type    = bool
  default = true
}

variable "rds_db_subnet_group_name" {
  type    = string
  default = "jerneydb-subnet-group"
}

variable "rds_allocated_storage" {
  type    = number
  default = 20
}

variable "rds_max_allocated_storage" {
  type    = number
  default = 100
}

variable "rds_publicly_accessible" {
  type    = bool
  default = false
}

variable "cdn_origins" {
  type = map(object({
    connection_attempts = optional(number)
    connection_timeout  = optional(number)
    custom_header       = optional(map(string))
    custom_origin_config = optional(object({
      http_port                = number
      https_port               = number
      ip_address_type          = optional(string)
      origin_keepalive_timeout = optional(number)
      origin_read_timeout      = optional(number)
      origin_protocol_policy   = string
      origin_ssl_protocols     = optional(list(string), ["TLSv1.2"])
    }))
    domain_name               = string
    origin_access_control_key = optional(string)
    origin_access_control_id  = optional(string)
    origin_id                 = optional(string)
    origin_path               = optional(string)
    origin_shield = optional(object({
      enabled              = bool
      origin_shield_region = optional(string)
    }))
    response_completion_timeout = optional(number)
    vpc_origin_config = optional(object({
      origin_keepalive_timeout = optional(number)
      origin_read_timeout      = optional(number)
      vpc_origin_id            = optional(string)
      vpc_origin_key           = optional(string)
    }))
  }))

  default = {
    "nginx_gateway_created_nlb" = {
      domain_name         = ""
      connection_attempts = 3
      custom_origin_config = {
        http_port              = 80
        https_port             = 443
        ip_address_type        = "ipv4"
        origin_protocol_policy = "https-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }
  }
}

variable "cdn_default_cache_behaviour" {
  type = object({
    allowed_methods           = optional(list(string), ["GET", "HEAD", "OPTIONS"])
    cache_policy_id           = optional(string)
    cache_policy_name         = optional(string)
    cached_methods            = optional(list(string), ["GET", "HEAD"])
    compress                  = optional(bool, true)
    default_ttl               = optional(number)
    field_level_encryption_id = optional(string)
    forwarded_values = optional(object({
      cookies = object({
        forward           = optional(string, "none")
        whitelisted_names = optional(list(string))
      })
      headers                 = optional(list(string))
      query_string            = optional(bool, false)
      query_string_cache_keys = optional(list(string))
      }),
      {
        cookies = {
          forward = "none"
        }
        query_string = false
      }
    )
    function_association = optional(map(object({
      event_type   = optional(string)
      function_arn = optional(string)
      function_key = optional(string)
    })))
    grpc_config = optional(object({
      enabled = optional(bool)
    }))
    lambda_function_association = optional(map(object({
      event_type   = optional(string)
      include_body = optional(bool)
      lambda_arn   = string
    })))
    max_ttl                      = optional(number)
    min_ttl                      = optional(number)
    origin_request_policy_id     = optional(string)
    origin_request_policy_name   = optional(string)
    realtime_log_config_arn      = optional(string)
    response_headers_policy_id   = optional(string)
    response_headers_policy_key  = optional(string)
    response_headers_policy_name = optional(string)
    smooth_streaming             = optional(bool)
    target_origin_id             = string
    trusted_key_groups           = optional(list(string))
    trusted_signers              = optional(list(string))
    viewer_protocol_policy       = optional(string, "https-only")
  })

  default = {
    target_origin_id       = "nginx_gateway_created_nlb"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods  = ["GET", "HEAD"]
    compress        = true
    min_ttl         = 0
    default_ttl     = 7200  # 2 hour
    max_ttl         = 86400 # 1 day
    forwarded_values = {
      cookies      = { forward = "all" }
      query_string = true
      headers      = ["Host", "Origin", "Authorization"]
    }
  }
}

variable "cdn_ordered_cache_behavior" {
  type = list(object({
    allowed_methods           = optional(list(string), ["GET", "HEAD", "OPTIONS"])
    cached_methods            = optional(list(string), ["GET", "HEAD"])
    cache_policy_id           = optional(string)
    cache_policy_name         = optional(string)
    compress                  = optional(bool, true)
    default_ttl               = optional(number)
    field_level_encryption_id = optional(string)
    forwarded_values = optional(object({
      cookies = object({
        forward           = optional(string, "none")
        whitelisted_names = optional(list(string))
      })
      headers                 = optional(list(string))
      query_string            = optional(bool, false)
      query_string_cache_keys = optional(list(string))
      }),
      {
        cookies = {
          forward = "none"
        }
        query_string = false
      }
    )
    function_association = optional(map(object({
      event_type   = optional(string)
      function_arn = optional(string)
      function_key = optional(string)
    })))
    grpc_config = optional(object({
      enabled = optional(bool)
    }))
    lambda_function_association = optional(map(object({
      event_type   = optional(string)
      include_body = optional(bool)
      lambda_arn   = string
    })))
    max_ttl                      = optional(number)
    min_ttl                      = optional(number)
    origin_request_policy_id     = optional(string)
    origin_request_policy_name   = optional(string)
    path_pattern                 = string
    realtime_log_config_arn      = optional(string)
    response_headers_policy_id   = optional(string)
    response_headers_policy_key  = optional(string)
    response_headers_policy_name = optional(string)
    smooth_streaming             = optional(bool)
    target_origin_id             = string
    trusted_key_groups           = optional(list(string))
    trusted_signers              = optional(list(string))
    viewer_protocol_policy       = string
  }))

  default = [
    {
      path_pattern           = "/api/*"
      target_origin_id       = "nginx_gateway_created_nlb"
      viewer_protocol_policy = "redirect-to-https"

      allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
      cached_methods  = ["GET", "HEAD"]
      compress        = true
      min_ttl         = 0
      default_ttl     = 0
      max_ttl         = 0
      forwarded_values = {
        cookies      = { forward = "all" }
        query_string = true
        headers      = ["Host", "Origin", "Authorization", "Accept", "Content-Type", "Referer"]
      }
    }
  ]
}
