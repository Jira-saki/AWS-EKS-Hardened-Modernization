resource "aws_security_group" "node_sg" {
  name = "${var.project_name}-node-sg"
  description = "Security group for EKS worker nodes"
  vpc_id = var.vpc_id

  # ✅ Allow internal: Nodes can talking on every Port
  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    self = true
  }
  # ✅ Hardened Egress: allow to pull Image/update (0.0.0.0/0)
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-node-sg"
    "kubernetes.io/cluster/${var.project_name}" = "owned"
  }
}