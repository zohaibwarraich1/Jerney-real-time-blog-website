output "nat_gatways" {
  value = module.vpc.natgw_ids
}

output "private_subnets" {
  value = module.vpc.private_subnets
}

output "public_subnets" {
  value = module.vpc.public_subnets
}

output "igws" {
  value = module.vpc.igw_id
}

output "public_route_table_ids" {
  value = module.vpc.public_route_table_ids
}

output "private_route_table_ids" {
  value = module.vpc.private_route_table_ids
}

output "eks_oidc_url" {
  value = module.eks.cluster_oidc_issuer_url
}

output "eks_addons" {
  value = module.eks.cluster_addons
}

output "route53_zone_NS" {
  value = aws_route53_delegation_set.keep_same_NS_delegation_set.name_servers
}

output "route53_records" {
  value = module.route53.records
}

output "route53_zone_id" {
  value = module.route53.id
}

output "iam_role_for_service_accounts" {
  value = {
    for k, v in module.iam_role_for_service_accounts : k => v.name
  }
}

output "iam_policies" {
  value = {
    for k, v in module.iam_policy : k => v.name
  }
}

# output "argocd_release_name" {
#   value = helm_release.argocd_release.name
# }

output "jerney_app" {
  value = helm_release.jerney_app_release.status
}

# output "argocd_release" {
#   value = helm_release.argocd_release.status
# }

output "nginx_gateway_release" {
  value = helm_release.nginx_gateway_release.status
}

output "external_secrets_release" {
  value = helm_release.external_secrets_release.status
}

output "rds_address" {
  value = module.rds.db_instance_address
}
