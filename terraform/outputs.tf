output "api_endpoint" {
  value = aws_apigatewayv2_api.http_api.api_endpoint
}

output "custom_domain_target" {
  value = aws_apigatewayv2_domain_name.custom_domain.domain_name_configuration[0].target_domain_name
}

output "cron_lambda_arn" {
  value = aws_lambda_function.cron_app.arn
  description = "The ARN of the cron-app Lambda function"
}

output "cron_lambda_function_name" {
  value = aws_lambda_function.cron_app.function_name
  description = "The name of the cron-app Lambda function"
}

output "eventbridge_rule_arn" {
  value = aws_cloudwatch_event_rule.cron_schedule.arn
  description = "The ARN of the EventBridge rule for the cron-app Lambda"
}

output "terraform_state_bucket" {
  value = aws_s3_bucket.terraform_state.bucket
  description = "The name of the S3 bucket for Terraform state"
}
