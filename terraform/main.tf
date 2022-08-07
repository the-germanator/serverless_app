
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
  assume_role_policy = file("policies/assume_role_policy.json")
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
  assume_role_policy = file("policies/assume_role_policy.json")
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
// GET
resource "aws_iam_role" "lambda_get_role" {
  name = "lambda_get_role"
  assume_role_policy = file("policies/assume_role_policy.json")
}

resource "aws_iam_role_policy" "get_lambda_policy" {
  name = "lambda_policy"
  role = aws_iam_role.lambda_get_role.id
  policy = file("policies/dynamodb_get.json")
}

data "archive_file" "get_lambda_zip" {
    type        = "zip"
    source_dir  = "../lambdas/get"
    output_path = "../lambdas/get/get_lambda.zip"
}

resource "aws_lambda_function" "get_lambda" {
  function_name = "get-data"
  filename      = data.archive_file.get_lambda_zip.output_path
  role          = aws_iam_role.lambda_get_role.arn
  handler       = "index.handler"
  runtime       = "nodejs16.x"
  source_code_hash = filebase64sha256(data.archive_file.get_lambda_zip.output_path)
}

// API Gateway

// General Config
resource "aws_api_gateway_rest_api" "dynamo_data_routes" {
  name = "CRUD Methods"
  description = "Route for CRUD operations on DynamoDB data"
}



resource "aws_api_gateway_method" "put_proxy_root" {
  rest_api_id = aws_api_gateway_rest_api.dynamo_data_routes.id
  resource_id = aws_api_gateway_rest_api.dynamo_data_routes.root_resource_id
  http_method = "PUT"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "delete_proxy_root" {
  rest_api_id = aws_api_gateway_rest_api.dynamo_data_routes.id
  resource_id = aws_api_gateway_rest_api.dynamo_data_routes.root_resource_id
  http_method = "DELETE"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "get_proxy_root" {
  rest_api_id = aws_api_gateway_rest_api.dynamo_data_routes.id
  resource_id = aws_api_gateway_rest_api.dynamo_data_routes.root_resource_id
  http_method = "GET"
  authorization = "NONE"
  request_parameters = {"method.request.querystring.userID" = true}
}


resource "aws_api_gateway_integration" "put_lambda_root" {
  rest_api_id = aws_api_gateway_rest_api.dynamo_data_routes.id
  resource_id = aws_api_gateway_method.put_proxy_root.resource_id
  http_method = aws_api_gateway_method.put_proxy_root.http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = aws_lambda_function.put_lambda.invoke_arn
}
resource "aws_api_gateway_integration" "delete_lambda_root" {
  rest_api_id = aws_api_gateway_rest_api.dynamo_data_routes.id
  resource_id = aws_api_gateway_method.delete_proxy_root.resource_id
  http_method = aws_api_gateway_method.delete_proxy_root.http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = aws_lambda_function.delete_lambda.invoke_arn
}

resource "aws_api_gateway_integration" "get_lambda_root" {
  rest_api_id = aws_api_gateway_rest_api.dynamo_data_routes.id
  resource_id = aws_api_gateway_method.get_proxy_root.resource_id
  http_method = aws_api_gateway_method.get_proxy_root.http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = aws_lambda_function.get_lambda.invoke_arn
}


resource "aws_api_gateway_deployment" "put-deployment" {
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_method.put_proxy_root,
      aws_api_gateway_integration.put_lambda_root,
    ]))
  }
  rest_api_id = aws_api_gateway_rest_api.dynamo_data_routes.id
  stage_name = "test"
}

resource "aws_api_gateway_deployment" "delete-deployment" {
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_method.delete_proxy_root,
      aws_api_gateway_integration.delete_lambda_root,
    ]))
  }
  rest_api_id = aws_api_gateway_rest_api.dynamo_data_routes.id
  stage_name = "test"
}

resource "aws_api_gateway_deployment" "get-deployment" {
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_method.get_proxy_root,
      aws_api_gateway_integration.get_lambda_root,
    ]))
  }
  rest_api_id = aws_api_gateway_rest_api.dynamo_data_routes.id
  stage_name = "test"
}

// Permissions
resource "aws_lambda_permission" "put_apigw" {
  statement_id = "AllowAPIGatewayInvoke"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.put_lambda.function_name
  principal = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.dynamo_data_routes.execution_arn}/*/*"
}

resource "aws_lambda_permission" "delete_apigw" {
  statement_id = "AllowAPIGatewayInvoke"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.delete_lambda.function_name
  principal = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.dynamo_data_routes.execution_arn}/*/*"
}

resource "aws_lambda_permission" "get_apigw" {
  statement_id = "AllowAPIGatewayInvoke"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_lambda.function_name
  principal = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.dynamo_data_routes.execution_arn}/*/*"
}

output "base_url" {
  value = aws_api_gateway_deployment.delete-deployment.invoke_url
}
