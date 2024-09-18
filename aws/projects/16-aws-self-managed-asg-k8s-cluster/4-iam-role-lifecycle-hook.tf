# Define the IAM Role for Lifecycle Hooks
resource "aws_iam_role" "lifecycle_hook_role" {
  name = "lifecycle_hook_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "autoscaling.amazonaws.com"
        }
      }
    ]
  })
}

# Attach policies to the IAM role
resource "aws_iam_role_policy_attachment" "lifecycle_hook_policy" {
  role       = aws_iam_role.lifecycle_hook_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforAutoScaling"
}
