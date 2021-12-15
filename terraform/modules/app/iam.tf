resource "aws_iam_role" "magic_role" {
  name = "magic_role"

  assume_role_policy = <<-EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Action": "sts:AssumeRole",
          "Principal": {
            "Service": "lambda.amazonaws.com"
          },
          "Effect": "Allow",
          "Sid": ""
        }
      ]
    }
  EOF
}

data "aws_iam_policy_document" "policy_doc" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "*"
    ]
  }
}


resource "aws_iam_policy" "magic_policy" {
  name        = "magic_policy"
  path        = "/"
  description = "Basic policy"

  policy = data.aws_iam_policy_document.policy_doc.json
}

resource "aws_iam_role_policy_attachment" "magic_policy_attachment" {
  role       = aws_iam_role.magic_role.name
  policy_arn = aws_iam_policy.magic_policy.arn
}