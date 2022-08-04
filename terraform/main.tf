
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

// PUT
resource "aws_iam_role" "lambda_put_role" {
  name = "lambda_put_role"
  assume_role_policy = file("assume_role_policy.json")
}
resource "aws_iam_role_policy" "put_lambda_policy" {
  name = "lambda_policy"
  role = aws_iam_role.lambda_put_role.id
  policy = file("policies/dynamodb_put.json")
}
data "archive_file" "put_lambda_zip" {
    type        = "zip"
    source_dir  = "../lambdas/put"
    output_path = "../lambdas/put/put_lambda.zip"
}
resource "aws_lambda_function" "put_lambda" {
  function_name = "put-data"
  filename      = data.archive_file.put_lambda_zip.output_path
  role          = aws_iam_role.lambda_put_role.arn
  handler       = "index.handler"
  runtime       = "nodejs16.x"
  source_code_hash = filebase64sha256(data.archive_file.put_lambda_zip.output_path)
}

// Delete
resource "aws_iam_role" "lambda_delete_role" {
  name = "lambda_delete_role"
  assume_role_policy = file("assume_role_policy.json")
}

resource "aws_iam_role_policy" "delete_lambda_policy" {
  name = "lambda_policy"
  role = aws_iam_role.lambda_delete_role.id
  policy = file("policies/dynamodb_delete.json")
}

data "archive_file" "delete_lambda_zip" {
    type        = "zip"
    source_dir  = "../lambdas/delete"
    output_path = "../lambdas/delete/delete_lambda.zip"
}

resource "aws_lambda_function" "delete_lambda" {
  function_name = "delete-data"
  filename      = data.archive_file.delete_lambda_zip.output_path
  role          = aws_iam_role.lambda_delete_role.arn
  handler       = "index.handler"
  runtime       = "nodejs16.x"
  source_code_hash = filebase64sha256(data.archive_file.delete_lambda_zip.output_path)
}