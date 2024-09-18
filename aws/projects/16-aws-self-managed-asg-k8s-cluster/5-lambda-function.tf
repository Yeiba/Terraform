# Define the SNS topic for worker lifecycle events
resource "aws_sns_topic" "worker_lifecycle_sns" {
  name = "worker-lifecycle-topic"
}

# Define the Lambda function
resource "aws_lambda_function" "ansible_trigger_lambda" {
  filename         = "lambda.zip"
  function_name    = "ansible_trigger_lambda"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  source_code_hash = filebase64sha256("lambda.zip")

  environment {
    variables = {
      BASTION_IP = aws_instance.bastion.public_ip
      SSH_USER   = var.ssh_user
      PRIVATE_KEY = base64encode(tls_private_key.ssh.private_key_pem)
    }
  }
}

# Allow SNS to invoke the Lambda function
resource "aws_lambda_permission" "allow_sns_to_invoke_lambda" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ansible_trigger_lambda.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.worker_lifecycle_sns.arn
}

# SNS Topic Subscription
resource "aws_sns_topic_subscription" "lambda_sns_subscription" {
  topic_arn = aws_sns_topic.worker_lifecycle_sns.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.ansible_trigger_lambda.arn
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "ansible_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Role Policy Attachment for Lambda
resource "aws_iam_role_policy_attachment" "lambda_sns_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Define the Auto Scaling Group lifecycle hooks for worker nodes
resource "aws_autoscaling_lifecycle_hook" "worker_scale_up" {
  name                    = "worker-scale-up-hook"
  lifecycle_hook_type     = "autoscaling:EC2_INSTANCE_LAUNCH"
  autoscaling_group_name  = aws_autoscaling_group.worker_asg.name
  role_arn                = aws_iam_role.lifecycle_hook_role.arn
  notification_target_arn = aws_sns_topic.worker_lifecycle_sns.arn
  heartbeat_timeout       = 3600

  depends_on = [aws_autoscaling_group.worker_asg]
}

resource "aws_autoscaling_lifecycle_hook" "worker_scale_down" {
  name                    = "worker-scale-down-hook"
  lifecycle_hook_type     = "autoscaling:EC2_INSTANCE_TERMINATING"
  autoscaling_group_name  = aws_autoscaling_group.worker_asg.name
  role_arn                = aws_iam_role.lifecycle_hook_role.arn
  notification_target_arn = aws_sns_topic.worker_lifecycle_sns.arn
  heartbeat_timeout       = 3600

  depends_on = [aws_autoscaling_group.worker_asg]
}