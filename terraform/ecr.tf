resource "aws_ecr_repository" "worpress-app" {
  name = "wordpress-app"
  image_tag_mutability = "MUTABLE" # can change the tag

  # # ✅ Hardened: Vulnerability Scan start when Push!
  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256" # default
  }
}