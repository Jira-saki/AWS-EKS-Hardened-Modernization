# 💰 S3 Gateway Endpoint: Highway to S3 !!!
resource "aws_vpc_endpoint" "s3_gateway" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.ap-northeast-1.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = [
    aws_route_table.public.id,
    aws_route_table.private.id
]

  policy            = data.aws_iam_policy_document.s3_gateway_endpoint.json
  tags              = {
    Name = "s3-gateway-endpoint"
  }
} 


# 🆔 get Account ID  
data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "s3_gateway_endpoint" {
  # ✅ Statement 1: only our Bucket 
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"]
    resources = [
      "arn:aws:s3:::modernization-logs-${data.aws_caller_identity.current.account_id}",
      "arn:aws:s3:::modernization-logs-${data.aws_caller_identity.current.account_id}/*"
    ]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:ResourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  # 🚫 Statement 2: block other Account(prevent to send the data out )
  statement {
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = ["*"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "StringNotEquals"
      variable = "aws:ResourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

