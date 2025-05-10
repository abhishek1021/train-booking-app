provider "aws" {
  region = "ap-south-1"
}

resource "aws_iam_role" "lambda_exec" {
  name = "mockjson-lambda-exec-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "mockjson" {
  function_name = "mock-json-server"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "lambda.handler"
  runtime       = "nodejs18.x"
  filename      = "../backend/mock_api/lambda.zip"
  source_code_hash = filebase64sha256("../backend/mock_api/lambda.zip")
  timeout = 30
  memory_size = 256
  environment {
    variables = {
      NODE_ENV = "production"
    }
  }
}

resource "aws_apigatewayv2_api" "mockjson_api" {
  name          = "mock-json-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id           = aws_apigatewayv2_api.mockjson_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.mockjson.invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "default_route" {
  api_id    = aws_apigatewayv2_api.mockjson_api.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_stage" "default_stage" {
  api_id      = aws_apigatewayv2_api.mockjson_api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.mockjson.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.mockjson_api.execution_arn}/*/*"
}

resource "aws_apigatewayv2_domain_name" "custom_domain" {
  domain_name = "mockjsonserver.tatkalpro.in"
  domain_name_configuration {
    certificate_arn = var.mockjson_acm_certificate_arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}

resource "aws_apigatewayv2_api_mapping" "custom_domain_mapping" {
  api_id      = aws_apigatewayv2_api.mockjson_api.id
  domain_name = aws_apigatewayv2_domain_name.custom_domain.id
  stage       = aws_apigatewayv2_stage.default_stage.id
}

variable "mockjson_acm_certificate_arn" {
  description = "ACM certificate ARN for mockjsonserver.tatkalpro.in"
  type        = string
}

output "mockjson_api_url" {
  value = aws_apigatewayv2_api.mockjson_api.api_endpoint
}
output "mockjson_custom_domain_target" {
  value = aws_apigatewayv2_domain_name.custom_domain.domain_name_configuration[0].target_domain_name
}
