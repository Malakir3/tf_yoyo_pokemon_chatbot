#####################################################
# API Gateway本体
#####################################################
resource "aws_api_gateway_rest_api" "this" {
  name           = "yoyo_pokemon_line_chatbot"
  api_key_source = "HEADER"
  endpoint_configuration {
    types = [
      "REGIONAL",
    ]
  }
}

# リソース
resource "aws_api_gateway_resource" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = var.parent_api_resource_id
  path_part   = "judge"
}

# モデル
resource "aws_api_gateway_model" "message_check" {
  rest_api_id  = aws_api_gateway_rest_api.this.id
  name         = "MessageCheck"
  content_type = "application/json"
  schema       = templatefile("./iam/message-check.json", {})
}

# リクエストの検証
resource "aws_api_gateway_request_validator" "this" {
  name                  = "本文の検証"
  rest_api_id           = aws_api_gateway_rest_api.this.id
  validate_request_body = true
}

# メソッドリクエスト
resource "aws_api_gateway_method" "post" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.this.id
  http_method   = "POST"
  authorization = "NONE"
  request_models = {
    "application/json" = aws_api_gateway_model.message_check.name
  }
  request_validator_id = aws_api_gateway_request_validator.this.id
}

# 統合リクエスト
resource "aws_api_gateway_integration" "post" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.this.id
  http_method             = "POST"
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.main.invoke_arn
  content_handling        = "CONVERT_TO_TEXT"
}

# 統合レスポンス
resource "aws_api_gateway_integration_response" "post" {
  http_method = "POST"
  resource_id = aws_api_gateway_resource.this.id
  rest_api_id = aws_api_gateway_rest_api.this.id
  status_code = "200"
  response_templates = {
    "application/json" = ""
  }
}

# メソッドレスポンス
resource "aws_api_gateway_method_response" "post" {
  http_method = "POST"
  resource_id = aws_api_gateway_resource.this.id
  rest_api_id = aws_api_gateway_rest_api.this.id
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
}

# デプロイ
resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id
}

# ステージ
resource "aws_api_gateway_stage" "dev" {
  rest_api_id          = aws_api_gateway_rest_api.this.id
  stage_name           = "dev"
  deployment_id        = aws_api_gateway_deployment.this.id
  xray_tracing_enabled = true
  tags = {
    Name = "${var.SystemName}-${var.env}-api_gateway_stage-dev"
  }
}

# メソッドの設定
resource "aws_api_gateway_method_settings" "post" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  stage_name  = aws_api_gateway_stage.dev.stage_name
  method_path = "*/*"
  settings {
    data_trace_enabled                      = true
    logging_level                           = "INFO"
    require_authorization_for_cache_control = true
    throttling_burst_limit                  = 5000
    throttling_rate_limit                   = 10000
  }
}

# lambdaを実行する許可
resource "aws_lambda_permission" "main" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.main.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.this.execution_arn}/*/POST/judge"
}


#####################################################
# CloudwatchLogs関係
#####################################################
# Cloudwatchロググループ
resource "aws_cloudwatch_log_group" "apigw" {
  name              = "API-Gateway-Execution-Logs_${var.api_id}/dev"
  retention_in_days = var.retention_in_days
  tags = {
    "Name" = "API-Gateway-Execution-Logs_${var.api_id}/dev"
  }
}

# Cloudwatchlogsのロール
resource "aws_iam_role" "logs" {
  name                 = "APIGateway-CloudWatchLogs-Connection"
  assume_role_policy   = templatefile("./iam/trust-apigw.json", {})
  description          = "Allows API Gateway to push logs to CloudWatch Logs."
  max_session_duration = 3600
}

# AWS管理ポリシー
data "aws_iam_policy" "logs" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

# AWS管理ポリシーをロールにアタッチ
resource "aws_iam_role_policy_attachment" "logs" {
  role       = aws_iam_role.logs.name
  policy_arn = data.aws_iam_policy.logs.arn
}

# アカウント全体の設定で、Cloudwatchlogsのロールをapi-gatewayにアタッチ
resource "aws_api_gateway_account" "this" {
  cloudwatch_role_arn = aws_iam_role.logs.arn
}

