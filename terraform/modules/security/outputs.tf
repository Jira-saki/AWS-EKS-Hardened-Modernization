# get ID value to sent to EKS
output "node_sg_id" {
  value = aws_security_group.node_sg.id
  description = "The ID of the security group for EKS worker nodes"
}