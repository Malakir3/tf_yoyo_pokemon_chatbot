# 自アカウントID
data "aws_caller_identity" "self" {}

# Lambdaソースコード
data "archive_file" "main" {
  type        = "zip"
  source_file = "./src/lambda_function.py"
  output_path = "./src/lambda_function.zip"
}