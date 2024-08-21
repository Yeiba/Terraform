data "aws_caller_identity" "current" {}
########################################################
#======create iam role
########################################################
resource "aws_iam_role" "ec2_service_role" {
  name = "EC2ServiceRole"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Principal": {
        Service = "ec2.amazonaws.com"
      }
    }
  ]
}
POLICY
}

resource "aws_iam_role" "this_account_role" {
  name = "Fullaccessrole"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      }
    }
  ]
}
POLICY
}
########################################################
#======create iam policy
########################################################

resource "aws_iam_policy" "iam_profile_policy" {
  name = "IAMprofilepolicy"

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Resource": "arn:aws:iam::${local.prod_account_id}:role/${local.crossAccountRole}"
        }
    ]
}
POLICY
}
########################################################
#======attache iam role to iam policy
########################################################
resource "aws_iam_role_policy_attachment" "cross_account" {
  role       = aws_iam_role.ec2_service_role.name
  policy_arn = aws_iam_policy.iam_profile_policy.arn
}
