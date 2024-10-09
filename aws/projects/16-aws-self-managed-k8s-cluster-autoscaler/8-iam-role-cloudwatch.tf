resource "aws_iam_role" "worker_role" {
  name = "worker-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
        Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "cloudwatch_policy" {
  name        = "worker-cloudwatch-policy"
  description = "Policy for publishing CloudWatch metrics"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "cloudwatch:PutMetricData",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_policy" {
  role       = aws_iam_role.worker_role.name
  policy_arn = aws_iam_policy.cloudwatch_policy.arn
}

resource "aws_iam_instance_profile" "worker_profile" {
  name = "worker-node-instance-profile"
  role = aws_iam_role.worker_role.name
}
