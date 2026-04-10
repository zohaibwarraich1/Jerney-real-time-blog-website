data "aws_availability_zones" "azs" {
  state = "available"
}

data "aws_lb" "gateway_lb" {
  count = var.enable_gateway_dns ? 1 : 0

  tags = {
    "service.eks.amazonaws.com/stack" = "jerney-ns/jerney-gateway-nginx"
    "eks:eks-cluster-name"            = var.eks_cluster_name
  }
  timeouts {
    read = "5m"
  }
  depends_on = [time_sleep.wait_for_nlb]
}

data "aws_secretsmanager_secret" "backend_secrets" {
  name = "prod/jerney/backend"
}

data "aws_iam_policy" "AmazonEBSCSIDriverPolicy" {
  name = "AmazonEBSCSIDriverPolicy"
}

data "aws_iam_policy" "AmazonEKS_CNI_Policy" {
  name = "AmazonEKS_CNI_Policy"
}

data "http" "nginx_gateway_crds" {
  url = "https://raw.githubusercontent.com/nginx/nginx-gateway-fabric/v2.4.2/deploy/crds.yaml"
}

data "http" "experimental_gateway_api_crds" {
  url = "https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.1.0/experimental-install.yaml"
}

# YAML ko multiple documents mein split karo
data "kubectl_file_documents" "gateway_crds" {
  content = "${data.http.experimental_gateway_api_crds.response_body}\n---\n${data.http.nginx_gateway_crds.response_body}"
}
