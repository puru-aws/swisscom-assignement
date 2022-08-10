provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "bucket" {
  bucket = var.bucket_name
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "AES256"
      }
    }
  }
  tags = {
    Environment = var.environment
  }
}

resource "aws_dynamodb_table" "S3ObjectTable" {
  name = "S3ObjectTable"
  billing_mode = "PROVISIONED"
  read_capacity = "30"
  write_capacity = "30"
  attribute {
    name = "FileName"
    type = "S"
  }
  hash_key = "FileName"
  point_in_time_recovery {
    enabled = true
  }
  server_side_encryption {
    enabled = true
  }
  tags = {
    Environment = var.environment
  }
}

resource "aws_sfn_state_machine" "sfn_state_machine" {
  name= "sfn-state-machine-DynamoDB"
  role_arn = aws_iam_role.state_machine_role.arn
  definition = <<EOF
  {
  "Comment": "A description of my state machine",
  "StartAt": "PutItem",
  "States": {
    "PutItem": {
      "Type": "Task",
      "Resource": "arn:aws:states:::dynamodb:putItem",
      "Parameters": {
        "TableName": "ObjectTable",
        "Item.$": "$.item"
      },
      "End": true
    }
  }
}
  EOF
  tags = {
    Environment = var.environment
  }
}

resource "aws_cloudwatch_log_group" "lambda_logging" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = 14
}


resource "aws_lambda_function" "lambda_trigger" {
  function_name    = var.function_name
  role             = aws_iam_role.lambda_iam.arn
  handler          = "src/${var.handler_name}.lambda_handler"
  runtime          = var.runtime
  timeout          = var.timeout
  filename         = "./src.zip"
  source_code_hash = filebase64sha256("./src.zip")
  depends_on = [
    aws_iam_role_policy_attachment.lambda_logs,
    aws_cloudwatch_log_group.lambda_logging,
  ]
  environment {
    variables = {
      env            = var.environment
      STATE_MACHINE = aws_sfn_state_machine.sfn_state_machine.arn
    }
  }
  tags = {
    Environment = var.environment
  }
}

resource "aws_lambda_permission" "allow_bucket" {
  statement_id= "AllowExecutionFromS3Bucket"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_trigger.arn
  principal = "s3.amazonaws.com"
  source_arn = aws_s3_bucket.bucket.arn
  source_account = data.aws_caller_identity.current.account_id
}

resource "aws_s3_bucket_notification" "lambda_s3_trigger" {
  bucket = aws_s3_bucket.bucket.id

  lambda_function{
    lambda_function_arn = aws_lambda_function.lambda_trigger.arn
    events = ["s3:ObjectCreated:*"]
  }
  depends_on = [aws_lambda_permission.allow_bucket]
}

