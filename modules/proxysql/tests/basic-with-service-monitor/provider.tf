## if you are testing this in eks cluster uncomment the following  lines and set your cluster name
# data "aws_eks_cluster" "this" {
#   name = local.eks_name
# }

# data "aws_eks_cluster_auth" "this" {
#   name = local.eks_name
# }

# provider "helm" {
#   kubernetes {
#     host                   = data.aws_eks_cluster.this.endpoint
#     cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
#     token                  = data.aws_eks_cluster_auth.this.token
#   }
# }

# locals {
#   eks_name = "eks"
# }
