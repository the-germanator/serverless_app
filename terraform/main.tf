
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }

  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_dynamodb_table" "user_data" {
    name           = "user-data"
    billing_mode   = "PROVISIONED"
    read_capacity  = 2
    write_capacity = 2
    hash_key       = "userID"

    attribute {
      name = "userID"
      type = "S"
    }
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "lambda_policy"
  role = aws_iam_role.lambda_role.id
  policy = file("policy.json")
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda_role"
  assume_role_policy = file("assume_role_policy.json")
}

resource "aws_lambda_function" "put_user" {
  function_name = "put-user"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "nodejs16.x"
  filename = "lambda-code.zip"
}