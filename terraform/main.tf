# /aws-eks-hardened-modernization/terraform/main.tf
provider "aws" {
  region = var.region
}


module "vpc" {
  source = "./modules/vpc" # <--- บอกทางไปหาลูกน้อง

  # ส่งค่า Variables ไปให้ Module (ต้องตรงกับที่ประกาศใน modules/vpc/variables.tf)
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["ap-northeast-1a", "ap-northeast-1c"]
}

module "eks" {
  source = "./modules/eks"
  vpc_id          = module.vpc.vpc_id # get from output of VPC
  private_subnet_ids      = module.vpc.private_subnet_ids  # get from output of VPC
  cluster_name    = "${var.project_name}-cluster"

}