# Train Booking Cron App

This is a standalone Lambda application for executing scheduled Tatkal booking jobs. It's designed to be deployed as an AWS Lambda function triggered by EventBridge (CloudWatch Events) on a schedule.

## Overview

The cron app scans the DynamoDB `jobs` table for scheduled jobs that are ready to execute, processes them, and logs the execution details to the `job_logs` table. It's designed to run every 5 minutes via an EventBridge scheduled rule.

## Directory Structure

```
cron-app/
├── app/
│   ├── models/
│   │   └── __init__.py
│   ├── services/
│   │   ├── __init__.py
│   │   └── cronjob_service.py
│   └── __init__.py
├── lambda_function.py
├── requirements.txt
└── README.md
```

## Deployment Instructions

### 1. Create Lambda Deployment Package

```bash
# Navigate to the cron-app directory
cd cron-app

# Install dependencies to a local directory
pip install -r requirements.txt -t .

# Create a ZIP file for deployment
zip -r ../cron-lambda.zip .
```

### 2. Create Lambda Function

1. Go to AWS Lambda console
2. Create a new function:
   - Choose "Author from scratch"
   - Name: `train-booking-cronjob`
   - Runtime: Python 3.9
   - Architecture: x86_64
   - Execution role: Create a new role with DynamoDB permissions

3. Upload the deployment package:
   - Code source → Upload from → .zip file
   - Upload the `cron-lambda.zip` file

4. Configure the Lambda function:
   - Handler: `lambda_function.lambda_handler`
   - Memory: 256 MB
   - Timeout: 3 minutes
   - Environment variables:
     - `JOBS_TABLE`: jobs
     - `JOB_EXECUTIONS_TABLE`: job_executions
     - `JOB_LOGS_TABLE`: job_logs
     - `AWS_REGION`: ap-south-1 (or your preferred region)

### 3. Set Up IAM Permissions

Ensure the Lambda execution role has the following permissions:
- `AWSLambdaBasicExecutionRole` (for CloudWatch Logs)
- Custom policy for DynamoDB access:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "dynamodb:GetItem",
                "dynamodb:PutItem",
                "dynamodb:UpdateItem",
                "dynamodb:Query",
                "dynamodb:Scan"
            ],
            "Resource": [
                "arn:aws:dynamodb:*:*:table/jobs",
                "arn:aws:dynamodb:*:*:table/job_executions",
                "arn:aws:dynamodb:*:*:table/job_logs"
            ]
        }
    ]
}
```

### 4. Create EventBridge Rule

1. Go to Amazon EventBridge console
2. Create a new rule:
   - Name: `train-booking-cronjob-schedule`
   - Description: "Trigger train booking cronjob every 5 minutes"
   - Rule type: Schedule
   - Schedule pattern: Fixed rate of 5 minutes
   - Target: Lambda function
   - Function: `train-booking-cronjob`

## Local Testing

For local testing, you can run the cronjob service directly:

```python
from app.services.cronjob_service import run_cronjob_service

# Run the cronjob service
result = run_cronjob_service()
print(result)
```

## Monitoring

- Check CloudWatch Logs for Lambda execution logs
- The Lambda function will return detailed execution results including:
  - Number of jobs found
  - Number of jobs executed
  - Success/failure counts
  - Execution duration
  - Any errors encountered

## Troubleshooting

If the Lambda function fails:
1. Check CloudWatch Logs for error messages
2. Verify IAM permissions for DynamoDB access
3. Ensure the DynamoDB tables exist and have the correct schema
4. Check that the Lambda timeout is sufficient for processing all jobs
