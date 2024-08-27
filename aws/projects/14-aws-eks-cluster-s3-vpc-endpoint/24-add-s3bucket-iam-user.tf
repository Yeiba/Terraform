resource "aws_iam_user" "s3bucket-user" {
  name = "s3bucket-user"
}

resource "aws_iam_policy" "s3bucket" {
  name = "AmazonEKSDeveloperPolicy"

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:GetBucketLocation"
            ],
            "Resource": "arn:aws:s3:::your-bucket-name"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:DeleteObject",
                "s3:ListMultipartUploadParts",
                "s3:AbortMultipartUpload"
            ],
            "Resource": "arn:aws:s3:::your-bucket-name/*"
        }
    ]
}
POLICY
}

resource "aws_iam_user_policy_attachment" "s3bucket" {
  user       = aws_iam_user.s3bucket-user.name
  policy_arn = aws_iam_policy.s3bucket.arn
}
