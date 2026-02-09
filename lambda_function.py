import json
import boto3
import os

def lambda_handler(event, context):
    sns = boto3.client('sns')
    
    # Get SNS topic ARN from environment variable
    topic_arn = os.environ['SNSTopicArn']
    
    # Extract GuardDuty finding details
    finding = event['detail']
    
    message = f"""
    GuardDuty Alert!
    
    Finding ID: {finding.get('id', 'N/A')}
    Type: {finding.get('type', 'N/A')}
    Severity: {finding.get('severity', 'N/A')}
    Region: {finding.get('region', 'N/A')}
    
    Description: {finding.get('description', 'N/A')}
    """
    
    # Publish to SNS
    response = sns.publish(
        TopicArn=topic_arn,
        Message=message,
        Subject='GuardDuty Security Alert'
    )
    
    return {
        'statusCode': 200,
        'body': json.dumps('Alert sent successfully')
    }
