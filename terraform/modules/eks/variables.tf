# terraform/modules/eks/variables.tf

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type = string
}

variable "vpc_id" {
  description = "The VPC ID where the cluster will be deployed"
  type = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for EKS nodes"
  type        = list(string)
}