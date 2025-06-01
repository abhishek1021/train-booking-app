provider "aws" {
  region = var.aws_region
}

# Reference the existing S3 bucket for Terraform state management
data "aws_s3_bucket" "terraform_state" {
  bucket = "train-booking-terraform-state"
}

# Enable versioning on the existing bucket if not already enabled
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = data.aws_s3_bucket.terraform_state.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# DynamoDB table for Terraform state locking
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

# IAM role for the cron-app Lambda
resource "aws_iam_role" "cron_lambda_exec" {
  name = "cron_lambda_exec_role"
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

# IAM policy for DynamoDB access
resource "aws_iam_policy" "dynamodb_access" {
  name        = "lambda_dynamodb_access"
  description = "IAM policy for accessing DynamoDB tables"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Scan",
          "dynamodb:Query",
          "dynamodb:BatchGetItem",
          "dynamodb:BatchWriteItem"
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:dynamodb:${var.aws_region}:*:table/jobs",
          "arn:aws:dynamodb:${var.aws_region}:*:table/job_executions",
          "arn:aws:dynamodb:${var.aws_region}:*:table/job_logs"
        ]
      }
    ]
  })
}

# Attach policies to the cron Lambda role
resource "aws_iam_role_policy_attachment" "cron_lambda_policy" {
  role       = aws_iam_role.cron_lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "cron_dynamodb_policy" {
  role       = aws_iam_role.cron_lambda_exec.name
  policy_arn = aws_iam_policy.dynamodb_access.arn
}

# Lambda function for the cron-app
resource "aws_lambda_function" "cron_app" {
  function_name = "train-booking-cronjob"
  role          = aws_iam_role.cron_lambda_exec.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  timeout       = 180  # 3 minutes
  memory_size   = 256

  filename         = "${path.module}/../cron-app.zip"
  source_code_hash = filebase64sha256("${path.module}/../cron-app.zip")

  environment {
    variables = {
      JOBS_TABLE           = "jobs"
      JOB_EXECUTIONS_TABLE = "job_executions"
      JOB_LOGS_TABLE       = "job_logs"
      REGION               = var.aws_region  # Using REGION instead of AWS_REGION as it's a reserved key
    }
  }
}

# EventBridge rule to trigger the cron Lambda every 5 minutes
resource "aws_cloudwatch_event_rule" "cron_schedule" {
  name                = "train-booking-cronjob-schedule"
  description         = "Triggers the train-booking-cronjob Lambda every 5 minutes"
  schedule_expression = "rate(5 minutes)"
}

# Target the Lambda function from the EventBridge rule
resource "aws_cloudwatch_event_target" "cron_lambda_target" {
  rule      = aws_cloudwatch_event_rule.cron_schedule.name
  target_id = "train-booking-cronjob"
  arn       = aws_lambda_function.cron_app.arn
}

# Permission for EventBridge to invoke the Lambda
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cron_app.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cron_schedule.arn
}

# CloudWatch Log Group for the Lambda
resource "aws_cloudwatch_log_group" "cron_lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.cron_app.function_name}"
  retention_in_days = 30
}
