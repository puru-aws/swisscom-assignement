#Create Variables
variable "region" {
  default = "ap-south-1"
  description = "Region for Deployment"
}
variable "function_name" {
  default = ""
  description = "Lambda Function Name"
}
variable "handler_name" {
  default = ""
  description = "Python Handler Name"
}
variable "runtime" {
  default = ""
}
variable "timeout" {
  default = ""
  description = "Lambda Timeout value"
}

variable "lambda_role_name" {
  default = ""
  description = "IAM role to attached to Lambda function"
}

variable "lambda_iam_policy_name" {
  default = ""
}

variable "bucket_name" {
  default = ""
  description = "S3 Bucket Name"
}

variable "environment" {
  default = "dev"
}
