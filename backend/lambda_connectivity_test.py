import json
import logging
import requests

def lambda_handler(event, context):
    url = "https://mockjsonserver.tatkalpro.in/health"
    logging.info(f"Testing connectivity to {url}")
    try:
        resp = requests.get(url, timeout=120)
        logging.info(f"Status code: {resp.status_code}")
        return {
            'statusCode': resp.status_code,
            'body': resp.text
        }
    except Exception as e:
        logging.error(f"Error connecting to {url}: {e}")
        return {
            'statusCode': 500,
            'body': str(e)
        }
