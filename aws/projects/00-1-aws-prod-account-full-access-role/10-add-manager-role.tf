########################################################
#======create iam role
########################################################
resource "aws_iam_role" "full_admin" {
  name = "crossAccountRole-full_admin"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Principal": {
        "AWS": "arn:aws:iam::${local.dev_account_id}:root"
      }
    }
  ]
}
POLICY
}

########################################################
#======create iam policy
########################################################

resource "aws_iam_policy" "full_admin" {
  name = "AmazonEKSAdminPolicy"

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "*",
            "Resource": "*"
        }
    ]
}
POLICY
}
########################################################
#======attache iam role to iam policy
########################################################
resource "aws_iam_role_policy_attachment" "full_admin" {
  role       = aws_iam_role.full_admin.name
  policy_arn = aws_iam_policy.full_admin.arn
}
