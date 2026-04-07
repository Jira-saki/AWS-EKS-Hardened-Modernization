# the variables needed to receive values ​​from VPC and EKS.

variable "vpc_id" {
  type = string
  description = "VPC ID from VPC module"
}

variable "project_name" {
  type = string
  description = "Project Name from tagging"
}