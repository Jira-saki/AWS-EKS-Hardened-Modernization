# 1. EKS Cluster (The brian)
resource "aws_eks_cluster" "this" {
  name = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn # get from iam.tf

  vpc_config {
    subnet_ids = var.private_subnet_ids
    endpoint_private_access = true # ✅ Hardened: inside VPC only!
    endpoint_public_access = false # ✅ Hardened: no ingress from internet
  }

  depends_on = [ 
    aws_iam_role_policy_attachment.cluster_policy
  ]
}

# 2. EKS Node Group (The Soldiers - Bottlerocket Edition)
resource "aws_eks_node_group" "this" {
  cluster_name = aws_eks_cluster.this.name
  node_group_name = "${var.cluster_name}-node-group"
  node_role_arn = aws_iam_role.eks_node_role.arn # get from iam.tf
  subnet_ids = var.private_subnet_ids
  ami_type = "BOTTLEROCKET_x86_64" # ✅ Hardened: immutable infrastructure
  instance_types = ["t3.medium"] # ✅ Hardened: choose smaller instance types

  scaling_config {
    desired_size = 2
    max_size = 3
    min_size = 1
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node_AmazonEC2ContainerRegistryReadOnly,
  ]

}
