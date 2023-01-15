# LambdaにアタッチするIAMロール
resource "aws_iam_role" "lambda_main" {
  name               = "${local.lambda_name}-role-${var.role_id}"
  assume_role_policy = templatefile("./iam/trust-lambda.json", {})
  managed_policy_arns = [
    aws_iam_policy.basic_exe.arn,
  ]
  path = "/service-role/"
  tags = {
    "Name" = "${local.lambda_name}-role-${var.role_id}"
  }
}

# IAMポリシー
resource "aws_iam_policy" "basic_exe" {
  name = "${local.lambda_name}-policy"
  path = "/service-role/"
  policy = templatefile("./iam/lambda-basic-exe.json", {
    region             = var.region
    account_id         = data.aws_caller_identity.self.account_id
    lambda_name        = local.lambda_name
    dynamodb_table_arn = aws_dynamodb_table.main.arn
  })
  tags = {
    "Name" = "${local.lambda_name}-policy"
  }
}

# メイン処理Lambda
resource "aws_lambda_function" "main" {
  function_name = local.lambda_name
  role          = aws_iam_role.lambda_main.arn
  handler       = "lambda_function.lambda_handler"
  filename      = data.archive_file.main.output_path
  runtime       = "python3.9"
  memory_size   = 512
  timeout       = 5
  environment {
    variables = {
      "CLOUDFRONT_DISTRIBUTION_URL" = var.lambda_envs.cloudfront_distribution_url
      "KIMYAS_PROFILE_URL"          = var.lambda_envs.kimyas_profile_url
      "LINE_CHANNEL_ACCESS_TOKEN"   = var.lambda_envs.line_channel_access_token
      "REPLY_URL"                   = var.lambda_envs.reply_url
    }
  }
  tags = {
    "Name" = "${var.SystemName}-${var.env}-lambda-main"
  }
}

# CloudWatchロググループ
resource "aws_cloudwatch_log_group" "lambda_main" {
  name              = "/aws/lambda/${local.lambda_name}"
  retention_in_days = var.retention_in_days
  tags = {
    "Name" = "/aws/lambda/${local.lambda_name}"
  }
}
