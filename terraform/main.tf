# /aws-eks-hardened-modernization/terraform/main.tf

module "vpc" {
  source = "./modules/vpc" # <--- บอกทางไปหาลูกน้อง

  # ส่งค่า Variables ไปให้ Module (ต้องตรงกับที่ประกาศใน modules/vpc/variables.tf)
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["ap-northeast-1a", "ap-northeast-1c"]
}