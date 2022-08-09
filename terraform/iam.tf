resource "aws_iam_role" "state_machine_role" {
  name = "step-function-role"
  assume_role_policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "states.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": "StepFunctionAssumeRole"
      }
    ]
  }
  EOF
  inline_policy {
    name = "DynamoPermission"
    policy = jsonencode({
    Version = "2012-10-17"
    Statement =[
      {
        Action=[
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem"
        ]
        Effect ="Allow"
        Resource = "*"  
      }
    ]
  })
  }
  
}
resource "aws_iam_role" "lambda_iam" {
  name = var.lambda_role_name

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}


data "aws_iam_policy_document" "lambda_policy_document" {
  statement{
    sid = "1"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "states:StartExecution"
    ]
    resources = [
      aws_sfn_state_machine.sfn_state_machine.arn
    ]
  }
}

resource "aws_iam_policy" "lambda_policy" {
  name = "LambdaStateMachinePermissions"
  path = "/"
  policy = data.aws_iam_policy_document.lambda_policy_document.json
}

resource "aws_iam_role_policy_attachment" "lambda-attachment" {
  role = aws_iam_role.lambda_iam.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

