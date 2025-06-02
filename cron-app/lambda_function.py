import json
import logging
import os
import traceback
from app.services.cronjob_service import run_cronjob_service

# Configure logging for Lambda
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    """
    AWS Lambda handler function for the cronjob service.
    This function will be triggered by EventBridge/CloudWatch Events on a schedule.
    
    Args:
        event: The event data from EventBridge
        context: The Lambda context object
        
    Returns:
        dict: Response with execution status and details
    """
    logger.info(f"Cronjob Lambda triggered with event: {json.dumps(event)}")
    logger.info(f"Lambda function ARN: {context.invoked_function_arn}")
    logger.info(f"CloudWatch log stream name: {context.log_stream_name}")
    logger.info(f"CloudWatch log group name: {context.log_group_name}")
    logger.info(f"Lambda Request ID: {context.aws_request_id}")
    logger.info(f"Lambda function memory limits in MB: {context.memory_limit_in_mb}")
    
    try:
        # Run the cronjob service
        execution_results = run_cronjob_service(event, context)
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Cronjob service executed successfully',
                'timestamp': event.get('time', ''),
                'requestId': context.aws_request_id,
                'execution_results': execution_results
            }, default=str)
        }
    except Exception as e:
        # Log the full exception traceback
        error_traceback = traceback.format_exc()
        logger.error(f"Error executing cronjob service: {str(e)}")
        logger.error(f"Traceback: {error_traceback}")
        
        return {
            'statusCode': 500,
            'body': json.dumps({
                'message': f'Error executing cronjob service: {str(e)}',
                'timestamp': event.get('time', ''),
                'requestId': context.aws_request_id
            })
        }
