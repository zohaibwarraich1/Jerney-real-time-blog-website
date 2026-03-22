module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.6.0"
  name    = "jerney-vpc"
  cidr    = var.vpc_cidr

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

  create      = var.create_route53_module
  create_zone = var.create_route53_zone
  name        = var.route53_zone_name

  delegation_set_id = aws_route53_delegation_set.keep_same_NS_delegation_set.id
  force_destroy     = var.route53_force_destroy
  records           = local.route53_records

  tags = merge(var.common_tags, {
    Name = "jerney-route53"
  })
  depends_on = [module.eks, helm_release.jerney_app_release]
}

resource "aws_route53_delegation_set" "keep_same_NS_delegation_set" {
  reference_name = var.route53_delegation_resource_name
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
  source             = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  version            = "6.4.0"
  for_each           = local.iam_role_for_service_accounts
  name               = each.value.name
  oidc_providers     = each.value.oidc_providers
  policies           = each.value.policies

  # depends_on = [module.iam_oidc_provider]
}

resource "helm_release" "argocd_release" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  atomic           = true
  timeout          = 600
  # upgrade_install  = true
  lint            = true
  recreate_pods   = true
  cleanup_on_fail = true
  wait            = true
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
      name  = "controller.replicas"
      value = 1
    },
    {
      name  = "repoServer.autoscaling.enabled"
      value = true
    },
    {
      name  = "repoServer.autoscaling.minReplicas"
      value = 2
    },
    {
      name  = "server.autoscaling.enabled"
      value = true
    },
    {
      name  = "server.autoscaling.minReplicas"
      value = 2
    },
    {
      name  = "applicationSet.replicas"
      value = 2
    }
  ]
  depends_on = [module.eks.access_entries]
}

resource "helm_release" "external_secrets_release" {
  name             = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  namespace        = "external-secrets"
  create_namespace = true
  recreate_pods    = true
  atomic           = true
  cleanup_on_fail  = true
  timeout          = 600
  # upgrade_install  = true
  # version          = "2.2.0"
  depends_on = [module.eks.access_entries]
}

resource "helm_release" "nginx_gateway_release" {
  name       = "ngf"
  repository = "oci://ghcr.io/nginx/charts"
  chart      = "nginx-gateway-fabric"
  namespace  = "nginx-gateway"
  # upgrade_install  = true
  recreate_pods    = true
  create_namespace = true
  cleanup_on_fail  = true
  atomic           = true
  timeout          = 600
  # version          = "2.4.2"

  set = [
    {
      name  = "nginxGateway.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type"
      value = "nlb-ip"
    },
    {
      name  = "nginxGateway.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-scheme"
      value = "internet-facing"
    },
    {
      name  = "nginxGateway.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-nlb-target-type"
      value = "ip"
    }
  ]

  depends_on = [kubectl_manifest.gateway_crds]
}

/**
resource "time_sleep" "wait_for_eks_rbac" {
  depends_on      = [module.eks]
  create_duration = "120s"
}
**/

resource "kubectl_manifest" "gateway_crds" {
  for_each = data.kubectl_file_documents.gateway_crds.manifests

  yaml_body = each.value
  #fix: annotations are not being applied to the gateway crds. Because previously the annotations size was greater than the limit of bytes size of the annotations
  server_side_apply = true
  # lifecycle {
  #   prevent_destroy = true
  # }

  depends_on = [module.eks]
}

resource "helm_release" "jerney_app_release" {
  name             = "jerney-app"
  chart            = "../helm"
  namespace        = "jerney-ns"
  create_namespace = true
  recreate_pods    = true
  lint             = true
  cleanup_on_fail  = true
  atomic           = true
  timeout          = 600
  wait             = true
  # upgrade_install  = true
  set = [
    {
      name  = "infrastructure.clusterIssuer.roleArn"
      value = module.iam_role_for_service_accounts["CertManagerRoute53PolicyForEKS"].arn
    },
    {
      name  = "infrastructure.serviceAccount.roleArn"
      value = module.iam_role_for_service_accounts["ESOAccessSecretManagerPolicyForEKS"].arn
    }
  ]
  depends_on = [helm_release.nginx_gateway_release]
}
