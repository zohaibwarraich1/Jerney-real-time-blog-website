module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.6.0"
  name    = "jerney-vpc"
  cidr    = var.vpc_cidr
  providers = {
    aws = aws.ap-south-1
  }

  azs                     = data.aws_availability_zones.azs.names
  private_subnets         = var.private_subnets
  public_subnets          = var.public_subnets
  one_nat_gateway_per_az  = true
  enable_nat_gateway      = true
  enable_dns_hostnames    = true
  enable_dns_support      = true
  map_public_ip_on_launch = true

  public_subnet_suffix  = var.public_subnet_suffix
  private_subnet_suffix = var.private_subnet_suffix

  tags = merge(var.common_tags, {
    Name                                            = "jerney-vpc"
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
  })

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
    "kubernetes.io/role/elb"                        = "1"
    "eks:eks-cluster-name"                          = var.eks_cluster_name
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"               = "1"
    "eks:eks-cluster-name"                          = var.eks_cluster_name
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.15.1"
  providers = {
    aws = aws.ap-south-1
  }

  access_entries = var.enable_eks_access_entries == true ? var.eks_access_entries : {}

  kubernetes_version             = var.eks_kubernetes_version
  name                           = var.eks_cluster_name
  upgrade_policy                 = var.eks_cluster_upgrade_policy
  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets
  control_plane_subnet_ids       = module.vpc.public_subnets
  ip_family                      = var.eks_ip_family
  security_group_use_name_prefix = var.eks_control_plane_security_group_use_name_prefix
  service_ipv4_cidr              = var.eks_service_ipv4_cidr

  authentication_mode = var.eks_authentication_mode
  enable_irsa         = var.eks_enable_irsa

  # EKS Auto Mode Config
  compute_config                 = var.eks_auto_mode_compute_config
  create_auto_mode_iam_resources = true

  enable_auto_mode_custom_tags             = var.eks_enable_auto_mode_custom_tags
  enable_cluster_creator_admin_permissions = var.eks_enable_cluster_creator_admin_permissions
  zonal_shift_config                       = var.eks_zonal_shift_config

  create_node_security_group                   = var.eks_control_plane_create_security_group
  node_security_group_use_name_prefix          = var.eks_node_security_group_use_name_prefix
  node_security_group_enable_recommended_rules = var.eks_node_security_group_enable_recommended_rules
  node_security_group_name                     = var.eks_node_security_group_name
  node_security_group_tags = merge(var.common_tags, {

  })

  create_node_iam_role          = var.eks_create_node_iam_role
  node_iam_role_use_name_prefix = var.eks_node_iam_role_use_name_prefix
  node_iam_role_name            = var.eks_node_iam_role_name
  node_iam_role_tags = merge(var.common_tags, {

  })

  create_security_group    = var.eks_control_plane_create_security_group
  iam_role_use_name_prefix = var.eks_control_plane_iam_role_use_name_prefix
  iam_role_name            = var.eks_control_plane_iam_role_name
  iam_role_tags = merge(var.common_tags, {

  })

  endpoint_public_access  = var.eks_endpoint_public_access
  endpoint_private_access = var.eks_endpoint_private_access

  encryption_policy_name            = var.eks_encryption_policy_name
  encryption_policy_use_name_prefix = var.eks_encryption_policy_use_name_prefix

  cluster_tags = merge(var.common_tags, {
    Name = var.eks_cluster_name
  })

  addons     = local.eks_addons_with_roles
  depends_on = [module.vpc]
}

module "route53" {
  source  = "terraform-aws-modules/route53/aws"
  version = "6.4.0"
  providers = {
    aws = aws.ap-south-1
  }

  create      = var.create_route53_module
  create_zone = var.create_route53_zone
  name        = var.domain_name

  delegation_set_id = aws_route53_delegation_set.keep_same_NS_delegation_set.id
  force_destroy     = var.route53_force_destroy
  records           = var.route53_records

  tags = merge(var.common_tags, {
    Name = "jerney-route53"
  })
}

resource "aws_route53_delegation_set" "keep_same_NS_delegation_set" {
  reference_name = "${var.domain_name}-NS"
}

module "iam_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.4.0"

  for_each    = local.iam_policies
  name        = each.value.name
  path        = each.value.path
  description = each.value.description
  policy      = each.value.policy

  tags = merge(var.common_tags, try(each.value.tags, {}))
}

module "iam_role_for_service_accounts" {
  source         = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  version        = "6.4.0"
  for_each       = local.iam_role_for_service_accounts
  name           = each.value.name
  oidc_providers = each.value.oidc_providers
  policies       = each.value.policies

  # depends_on = [module.iam_oidc_provider]
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  lint             = true
  recreate_pods    = true
  cleanup_on_fail  = true
  wait             = true
  timeout          = 900 # 15 minutes ka timeout diya hai (default 5 min hota hai)
  set = [
    {
      name  = "crds.install"
      value = true
    },
    {
      name  = "redis-ha.enabled"
      value = true
    },
    {
      name  = "server.service.type"
      value = "LoadBalancer"
    },
    {
      name  = "server.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type"
      value = "nlb-ip"
    },
    {
      name  = "server.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-scheme"
      value = "internet-facing"
    },
    {
      name  = "server.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-nlb-target-type"
      value = "ip"
    }
  ]
  depends_on = [module.eks]
}

resource "helm_release" "external_secrets_release" {
  name             = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  namespace        = "external-secrets"
  create_namespace = true
  recreate_pods    = true
  # upgrade_install  = true
  # version          = "2.2.0"
  depends_on = [module.eks]
}

resource "helm_release" "nginx_gateway_release" {
  name       = "ngf"
  repository = "oci://ghcr.io/nginx/charts"
  chart      = "nginx-gateway-fabric"
  namespace  = "nginx-gateway"
  # upgrade_install  = true
  recreate_pods    = true
  create_namespace = true
  # version          = "2.4.2"

  set = [
    {
      name  = "nginx.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type"
      value = "nlb-ip"
    },
    {
      name  = "nginx.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-scheme"
      value = "internet-facing"
    },
    {
      name  = "nginx.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-nlb-target-type"
      value = "ip"
    },
    {
      name  = "nginx.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-manage-backend-security-group-rules"
      value = "true"
    }
  ]

  depends_on = [kubectl_manifest.gateway_crds]
}

resource "time_sleep" "wait_for_nlb" {
  depends_on      = [kubectl_manifest.argocd_application]
  create_duration = "4m" # 4 minutes wait karega
}

resource "kubectl_manifest" "gateway_crds" {
  for_each = data.kubectl_file_documents.gateway_crds.manifests

  yaml_body = each.value
  #fix: annotations are not being applied to the gateway crds. Because previously the annotations size was greater than the limit of bytes size of the annotations
  server_side_apply = true
  lifecycle {
    # prevent_destroy = true
  }

  depends_on = [module.eks]
}

resource "kubectl_manifest" "argocd_project" {
  yaml_body = file("${path.module}/../argocd/app-project.yaml")

  depends_on = [helm_release.argocd, helm_release.nginx_gateway_release, helm_release.external_secrets_release]
}

resource "kubectl_manifest" "argocd_application" {
  yaml_body = templatefile("${path.module}/../argocd/application.yaml", {
    db_host      = module.rds.db_instance_address
    db_port      = tostring(module.rds.db_instance_port)
    eso_role_arn = module.iam_role_for_service_accounts["ESOAccessSecretManagerPolicyForEKS"].arn
    vpc_cidr     = var.vpc_cidr
  })

  depends_on = [kubectl_manifest.argocd_project]
}

resource "aws_security_group" "rds_sg" {
  name        = "jerney-rds-sg"
  description = "RDS PostgreSQL Security Group. EKS nodes only"
  vpc_id      = module.vpc.vpc_id

  # EKS Auto Mode mein pods ka SG node_security_group_id se match nahi karta
  # VPC CIDR use karo — private network ke andar sab pods reach kar sakein
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Allow all VPC private traffic to reach RDS"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, { Name = "jerney-rds-sg" })

  depends_on = [module.eks, module.vpc]
}

module "rds" {
  source = "terraform-aws-modules/rds/aws"
  providers = {
    aws = aws.ap-south-1
  }
  identifier                  = var.rds_db_name
  allow_major_version_upgrade = false
  auto_minor_version_upgrade  = true

  # Explicitly subnet group banao otherwise RDS default VPC mein chala jata hai
  create_db_subnet_group      = var.rds_create_db_subnet_group
  db_subnet_group_name        = var.rds_db_subnet_group_name
  subnet_ids                  = module.vpc.private_subnets
  engine                      = var.rds_engine
  engine_version              = var.rds_engine_version
  instance_class              = var.rds_instance_class
  family                      = var.rds_family
  allocated_storage           = var.rds_allocated_storage
  max_allocated_storage       = var.rds_max_allocated_storage
  db_name                     = var.rds_db_name
  username                    = var.rds_db_user
  port                        = var.rds_db_port
  manage_master_user_password = var.rds_manage_master_user_password
  password_wo                 = var.rds_db_pass
  password_wo_version         = "1"

  storage_type                        = var.rds_storage_type
  publicly_accessible                 = var.rds_publicly_accessible
  network_type                        = "IPV4"
  storage_encrypted                   = var.rds_storage_encrypted
  multi_az                            = var.rds_multi_az
  availability_zone                   = var.rds_availability_zone
  iam_database_authentication_enabled = var.rds_iam_database_authentication_enabled

  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  tags = merge(var.common_tags, {
    Name = "jerneydb"
  })

  parameters = [
    {
      name         = "max_connections"
      value        = "200"
      apply_method = "pending-reboot"
    },
    {
      name         = "log_min_duration_statement"
      value        = "2000" # 2000ms = 2 sec se zyada queries log hongi
      apply_method = "immediate"
    }
  ]
  depends_on = [module.vpc]
}

resource "aws_acm_certificate" "cdn_cert" {
  provider    = aws.us-east-1 # CloudFront STRICTLY requires certificates to be in N. Virginia (us-east-1)
  domain_name = var.domain_name
  subject_alternative_names = [
    "www.${var.domain_name}"
  ]
  validation_method = "DNS"
  key_algorithm     = "RSA_2048"
  tags = merge(var.common_tags, {
    name = "cdn_certificate"
  })

  depends_on = [module.route53]
}

resource "aws_route53_record" "cdn_cert_validation_records" {
  for_each = {
    for dvo in aws_acm_certificate.cdn_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = module.route53.id

  depends_on = [aws_acm_certificate.cdn_cert]
}

resource "aws_acm_certificate_validation" "validate_cdn_cert" {
  provider                = aws.us-east-1
  certificate_arn         = aws_acm_certificate.cdn_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cdn_cert_validation_records : record.fqdn]

  depends_on = [aws_route53_record.cdn_cert_validation_records]
}

module "cdn" {
  source  = "terraform-aws-modules/cloudfront/aws"
  version = "6.4.0"
  providers = {
    aws = aws.ap-south-1
  }

  aliases             = var.domain_name_aliases
  comment             = "CloudFront for Jerney Blog Website"
  create              = true
  is_ipv6_enabled     = false
  enabled             = true
  wait_for_deployment = true

  origin = local.cdn_origins

  ordered_cache_behavior = var.cdn_ordered_cache_behavior

  default_cache_behavior = var.cdn_default_cache_behaviour

  viewer_certificate = {
    acm_certificate_arn = aws_acm_certificate.cdn_cert.arn
    ssl_support_method  = "sni-only"
  }

  depends_on = [aws_acm_certificate_validation.validate_cdn_cert, module.route53, time_sleep.wait_for_nlb]
}

resource "aws_route53_record" "cdn_alias" {
  count   = local.gateway_lb != null ? 1 : 0
  zone_id = module.route53.id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = module.cdn.cloudfront_distribution_domain_name
    zone_id                = module.cdn.cloudfront_distribution_hosted_zone_id
    evaluate_target_health = false
  }

  depends_on = [module.cdn, module.route53]
}

resource "aws_route53_record" "cdn_cname_www" {
  count   = local.gateway_lb != null ? 1 : 0
  zone_id = module.route53.id
  name    = "www"
  type    = "CNAME"
  ttl     = 300
  records = [module.cdn.cloudfront_distribution_domain_name]

  depends_on = [module.cdn, module.route53]
}
