# GuardDuty Environment Monitoring with Lambda & SNS Automation

## 📋 Overview

This project implements an automated security monitoring solution using AWS GuardDuty, Lambda, and SNS to detect and notify security threats in your AWS environment in real-time.

## 🏗️ Architecture

```
GuardDuty → EventBridge → Lambda Function → SNS Topic → Email/SMS Notifications
```

### Components:
- **AWS GuardDuty**: Threat detection service that monitors malicious activity
- **Amazon EventBridge**: Event-driven service that triggers Lambda on GuardDuty findings
- **AWS Lambda**: Serverless function that processes findings and formats notifications
- **Amazon SNS**: Notification service that delivers alerts via email/SMS
- **Terraform**: Infrastructure as Code for automated deployment

## 🚀 Features

- ✅ Real-time security threat detection
- ✅ Automated incident notifications
- ✅ Customizable alert severity filtering
- ✅ Multi-channel notifications (Email/SMS)
- ✅ Infrastructure as Code deployment
- ✅ Detailed finding information in notifications

## 📁 Project Structure

```
.
├── main.tf                 # Main Terraform configuration (all resources)
├── variables.tf            # Variable definitions
├── lambda_function.py     # Lambda handler code
├── lambda_function.zip    # Auto-generated Lambda deployment package
├── .gitignore            # Git ignore rules
└── README.md             # This file
```

## 🔧 Prerequisites

- AWS Account with appropriate permissions
- Terraform >= 1.0
- AWS CLI configured
- Email address for notifications
- Troubleshooting knowledge (Trust me you will need it )

## 📋 Required Variables

The following variables need to be defined in your `variables.tf`:

```hcl
#Email address for GuardDuty notifications
variable "endpointemail" {
  default = "input-your-email-here"
  type        = string
}

variable "GD-publisher_SNS" {
  description = "Name of the Lambda function"
  type        = string
  default     = "GD_publisher_SNS"
}

variable "lambda_rt" {
  description = "Lambda runtime version"
  type        = string
  default     = "python3.9"
}
```

## 📦 Installation

### 1. Clone the Repository

```bash
git clone https://github.com/daniel09077/GUARD_DUTY_FOR_ENVIRONMENT_MONITORING_LAMBDA_AUTOMATION_NOTIFIER_SNS.git
cd GUARD_DUTY_FOR_ENVIRONMENT_MONITORING_LAMBDA_AUTOMATION_NOTIFIER_SNS
```

### 2. Configure Variables

Edit the `variables.tf` file and set your values, or pass them during deployment:

**Option 1: Edit variables.tf directly** (set default values)

**Option 2: Pass variables during deployment:**

```bash
terraform apply -var="endpointemail=your-email@example.com" -var="GD-publisher_SNS=your-function-name"
```

### 3. Initialize Terraform

```bash
terraform init
```

### 4. Review the Plan

```bash
terraform plan
```

### 5. Deploy Infrastructure

```bash
terraform apply
```

### 6. Confirm SNS Subscription

Check your email and confirm the SNS subscription to start receiving notifications.

## 🔐 Security Findings Monitored

GuardDuty detects various threat types including:

- **Reconnaissance**: Unusual API activity, port scanning
- **Instance Compromise**: Malware, backdoor communication, cryptocurrency mining
- **Account Compromise**: Credential exposure, unusual authentication patterns
- **Bucket Compromise**: Suspicious S3 access patterns
- **Malicious IP Activity**: Communication with known malicious IPs
- **Unauthorized Access**: Privilege escalation attempts

**Alert Severity Filter**: Currently configured to alert on findings with severity >= 4 (Medium, High, and Critical)

## 🏗️ Deployed Resources

This Terraform configuration creates:

1. **SNS Topic**: `Guard-duty-alert` - for sending notifications
2. **SNS Subscription**: Email subscription to `your-email-will-be-used`
3. **IAM Role**: `GD_Lambda_role` - Lambda execution role with SNS publish permissions
4. **Lambda Function**: Processes GuardDuty findings and publishes to SNS
5. **EventBridge Rule**: `Evbridge_GD` - captures GuardDuty findings (severity >= 4)
6. **EventBridge Target**: Routes findings to Lambda function
7. **Lambda Permission**: Allows EventBridge to invoke the Lambda function

## 📧 Notification Format

Alerts include:
- Finding severity (Critical/High/Medium/Low)
- Finding type and description
- Affected AWS resource
- Account ID and region
- Timestamp
- Recommended actions

## 🛠️ Configuration Options

### Severity Filtering

The current configuration alerts on severity >= 4 (Medium and above). To change this, modify the EventBridge rule in `main.tf`:

```hcl
# For High and Critical only (severity 7-9)
 event_pattern = jsonencode({
    source        = ["aws.guardduty"],
    "detail-type" = ["GuardDuty Finding"],
    detail = {
      severity = [
        { "numeric" : [">=", 4] }
      ]
    }
  })
```

### Notification Channels

Add SMS notifications:

```hcl
resource "aws_sns_topic_subscription" "GD-duty-alert-sub" {
  topic_arn = aws_sns_topic.sub.Guard-duty-alert.arn
  protocol  = "email"
  endpoint  = var.endpointemail
}
```

## 📊 Monitoring and Logging

- Lambda execution logs: CloudWatch Logs
- GuardDuty findings: GuardDuty Console
- SNS delivery status: SNS Console

## 💰 Cost Estimation

**Monthly costs (approximate):**
- GuardDuty: $4.64 per million CloudTrail events analyzed
- Lambda: Free tier covers most use cases
- SNS: $0.50 per million email notifications
- EventBridge: Free for AWS service events

## 🧹 Cleanup

To destroy all resources:

```bash
terraform destroy
```

## 🔄 CI/CD Integration

This project can be integrated with:
- GitHub Actions
- GitLab CI/CD
- AWS CodePipeline
- Jenkins

## 📝 Best Practices

1. **Enable GuardDuty in all regions** where you have resources
2. **Review findings regularly** even with automation
3. **Tune alert sensitivity** based on your environment
4. **Use least privilege IAM roles** for Lambda
5. **Enable CloudTrail** for comprehensive monitoring
6. **Test notifications** before production deployment

## 🐛 Troubleshooting

### Not receiving notifications?
- Check SNS subscription confirmation in your email
- Verify Lambda execution in CloudWatch Logs
- Check EventBridge rule `Evbridge_GD` is enabled
- Verify GuardDuty is enabled in the region

### Lambda errors?
- Check IAM role `GD_Lambda_role` permissions
- Review CloudWatch Logs for the Lambda function
- Verify SNS topic ARN is correct in environment variables
- Ensure `lambda_function.py` exists in the project directory

### No findings appearing?
- GuardDuty takes 30 minutes to 7 hours to generate initial findings
- Severity filter is set to >= 4 (Medium and above)
- Generate sample findings for testing:
  ```bash
  aws guardduty create-sample-findings \
    --detector-id <your-detector-id> \
    --finding-types Backdoor:EC2/C&CActivity.B!DNS
  ```

## 📝 Lambda Function Requirements

Your `lambda_function.py` should:
- Read the `SNSTopicArn` environment variable
- Parse GuardDuty finding details from the event
- Format and publish a message to SNS
- Handle errors gracefully

Example structure:
```python
import json
import boto3
import os

def lambda_handler(event, context):
    sns = boto3.client('sns')
    topic_arn = os.environ['SNSTopicArn']
    
    # Extract finding details
    finding = event['detail']
    
    # Format message
    message = f"""
    GuardDuty Finding Alert!
    Severity: {finding['severity']}
    Type: {finding['type']}
    Description: {finding['description']}
    """
    
    # Publish to SNS
    sns.publish(TopicArn=topic_arn, Message=message)
    
    return {'statusCode': 200}
```

## 🤝 Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request



## 👤 Author

**Daniel**
- GitHub: [@daniel09077](https://github.com/daniel09077)
- Email: danielokuguni15@gmail.com

## 🙏 Acknowledgments

- AWS Documentation
- Terraform Registry
- GuardDuty Best Practices Guide

## 📞 Support

For issues and questions:
- Open an issue on GitHub
- Email: danielokuguni15@gmail.com

## 🔗 Related Resources

- [AWS GuardDuty Documentation](https://docs.aws.amazon.com/guardduty/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Lambda Best Practices](https://docs.aws.amazon.com/lambda/latest/dg/best-practices.html)

---

⭐ If you find this project useful, please consider giving it a star!
