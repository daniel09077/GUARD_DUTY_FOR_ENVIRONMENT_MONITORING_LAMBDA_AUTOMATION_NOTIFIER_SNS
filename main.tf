resource "aws_sns_topic" "Guard-duty-alert" {
  name = "Guard-duty-alert"
}

resource "aws_sns_topic_subscription" "GD-duty-alert-sub" {
  topic_arn = aws_sns_topic.Guard-duty-alert.arn
  protocol  = "email"
  endpoint  = var.endpointemail
}
resource "aws_iam_role" "GD_Lambda_role" {
  name = "GD_Lambda_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Basic Lambda execution policy
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.GD_Lambda_role.name
}

# SNS Publish Policy
resource "aws_iam_role_policy" "sns_publish_policy" {
  name = "sns-publish-policy"
  role = aws_iam_role.GD_Lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.Guard-duty-alert.arn
      }
    ]
  })
}
data "archive_file" "python_file" {
  type        = "zip"
  source_file = "lambda_function.py"
  output_path = "lambda_function.zip"
}
resource "aws_lambda_function" "GD_publisher_SNS" {
  role          = aws_iam_role.GD_Lambda_role.arn
  function_name = var.GD-publisher_SNS
  handler       = "lambda_function.lambda_handler"
  filename      = data.archive_file.python_file.output_path
  runtime       = var.lambda_rt
  environment {
    variables = {
      SNSTopicArn = aws_sns_topic.Guard-duty-alert.arn
    }
  }
}
#event bridge rule
resource "aws_cloudwatch_event_rule" "Evbridge_GD" {
  name        = "Evbridge_GD"
  description = "capture findings from Guard Duty"

  event_pattern = jsonencode({
    source        = ["aws.guardduty"],
    "detail-type" = ["GuardDuty Finding"],
    detail = {
      severity = [
        { "numeric" : [">=", 4] }
      ]
    }
  })
}
#lambda persmissoion to allow event bridge invoke the lambda function
resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.GD_publisher_SNS.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.Evbridge_GD.arn
}

#event bridge target == lambda function
resource "aws_cloudwatch_event_target" "Evnt_Lambda" {
  target_id = "Evnt_Lambda"
  rule      = aws_cloudwatch_event_rule.Evbridge_GD.name
  arn       = aws_lambda_function.GD_publisher_SNS.arn

}

output "email" {
  value = aws_sns_topic_subscription.GD-duty-alert-sub.endpoint
}