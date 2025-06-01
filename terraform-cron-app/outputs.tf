output "cron_lambda_arn" {
  value       = aws_lambda_function.cron_app.arn
  description = "The ARN of the cron-app Lambda function"
}

output "cron_lambda_function_name" {
  value       = aws_lambda_function.cron_app.function_name
  description = "The name of the cron-app Lambda function"
}

output "eventbridge_rule_arn" {
  value       = aws_cloudwatch_event_rule.cron_schedule.arn
  description = "The ARN of the EventBridge rule for the cron-app Lambda"
}

output "terraform_state_bucket" {
  value       = data.aws_s3_bucket.terraform_state.bucket
  description = "The name of the S3 bucket for Terraform state"
}
