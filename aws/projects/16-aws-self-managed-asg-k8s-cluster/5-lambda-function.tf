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

resource "aws_iam_role_policy_attachment" "lambda_sns_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
