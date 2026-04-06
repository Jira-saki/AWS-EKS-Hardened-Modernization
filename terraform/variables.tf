variable "region" {
  description = "AWS Region"
  type = string
  default = "ap-northeast-1" # tokyo
}

variable "project_name" {
  description = "Project name prefix"
  type = string
  default = "hardened-modernization"
}