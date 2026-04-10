locals {

  ############# IAM Policies #############
  iam_policies = {
    "CertManagerRoute53PolicyForEKS" = {
      name        = "CertManagerRoute53PolicyForEKS"
      path        = "/"
      description = "Cert Manager Route53 Policy For EKS Cluster"
      policy = jsonencode(
        {
          "Version" : "2012-10-17",
          "Statement" : [
            {
              "Effect" : "Allow",
              "Action" : "route53:GetChange",
              "Resource" : "arn:aws:route53:::change/*"
            },
            {
              "Effect" : "Allow",
              "Action" : [
                "route53:ChangeResourceRecordSets",
                "route53:ListResourceRecordSets"
              ],
              "Resource" : "arn:aws:route53:::hostedzone/*"
            },
            {
              "Effect" : "Allow",
              "Action" : "route53:ListHostedZonesByName",
              "Resource" : "*"
            }
          ]
        }
      )
      tags = {
        Name = "CertManagerRoute53PolicyForEKS"
      }
    },
    "ESOAccessSecretManagerPolicyForEKS" = {
      name        = "ESOAccessSecretManagerPolicyForEKS"
      path        = "/"
      description = "ESO Access Secret Manager Policy For EKS Cluster"
      policy = jsonencode(
        {
          "Version" : "2012-10-17",
          "Statement" : [
            {
              "Sid" : "Statement1",
              "Effect" : "Allow",
              "Action" : [
                "secretsmanager:DescribeSecret",
                "secretsmanager:GetRandomPassword",
                "secretsmanager:GetResourcePolicy",
                "secretsmanager:GetSecretValue",
                "secretsmanager:ListSecretVersionIds"
              ],
              "Resource" : [
                "${data.aws_secretsmanager_secret.backend_secrets.arn}"
              ]
            }
          ]
        }
      )
      tags = {
        Name = "ESOAccessSecretManagerPolicyForEKS"
      }
    }
  }

  ############# IAM Role For Service Accounts #############
  iam_role_for_service_accounts = {
    "AmazonEBSCSIDriverPolicy" = {
      name = "AmazonEBSCSIDriverRole"
      oidc_providers = {
        one = {
          provider_arn               = module.eks.oidc_provider_arn
          namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
        }
      }
      policies = {
        AmazonEBSCSIDriverPolicy = data.aws_iam_policy.AmazonEBSCSIDriverPolicy.arn
      }
    },
    "CertManagerRoute53PolicyForEKS" = {
      name = "CertManagerRoute53RoleForEKS"
      oidc_providers = {
        one = {
          provider_arn               = module.eks.oidc_provider_arn
          namespace_service_accounts = ["cert-manager:cert-manager"]
        }
      }
      policies = {
        CertManagerRoute53Policy = module.iam_policy["CertManagerRoute53PolicyForEKS"].arn
      }
    },
    "ESOAccessSecretManagerPolicyForEKS" = {
      name = "ESOAccessSecretManagerRoleForEKS"
      oidc_providers = {
        one = {
          provider_arn               = module.eks.oidc_provider_arn
          namespace_service_accounts = ["jerney-ns:eso-sa"]
        }
      }
      policies = {
        ESOAccessSecretManagerPolicy = module.iam_policy["ESOAccessSecretManagerPolicyForEKS"].arn
      }
    },
    "AmazonEKS_CNI_Policy" = {
      name = "AmazonEKS_CNI_RoleForEKS"
      oidc_providers = {
        one = {
          provider_arn               = module.eks.oidc_provider_arn
          namespace_service_accounts = ["kube-system:aws-node"]
        }
      }
      policies = {
        AmazonEKS_CNI_Policy = data.aws_iam_policy.AmazonEKS_CNI_Policy.arn
      }
    }
  }

  ############# EKS Addons With Roles #############
  eks_addons_with_roles = merge(var.eks_addons, {
    "aws-ebs-csi-driver" = merge(var.eks_addons["aws-ebs-csi-driver"], {
      service_account_role_arn = module.iam_role_for_service_accounts["AmazonEBSCSIDriverPolicy"].arn
    }),
    "cert-manager" = merge(var.eks_addons["cert-manager"], {
      service_account_role_arn    = module.iam_role_for_service_accounts["CertManagerRoute53PolicyForEKS"].arn
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
    }),
    "vpc-cni" = merge(var.eks_addons["vpc-cni"], {
      service_account_role_arn = module.iam_role_for_service_accounts["AmazonEKS_CNI_Policy"].arn
    })
  })

  # Safe access to LB data
  gateway_lb = one(data.aws_lb.gateway_lb)

  ############# CDN Origins #############
  cdn_origins = {
    "nginx_gateway_created_nlb" = merge(var.cdn_origins["nginx_gateway_created_nlb"], {
      domain_name = local.gateway_lb.dns_name
    })
  }

}
