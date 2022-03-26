locals {
  function_name = "hello-function"
}

resource "aws_lambda_function" "main" {
  function_name = local.function_name
  role          = aws_iam_role.lambda_role.arn

  handler  = "org.springframework.cloud.function.adapter.aws.FunctionInvoker::handleRequest"
  runtime  = "provided.al2"
  filename = data.archive_file.dummy.output_path
  memory_size = 192
  timeout = 3
  publish = true

  lifecycle {
    ignore_changes = all
  }
}

 resource aws_lambda_alias hello_alias {
   function_name    = aws_lambda_function.main.function_name
   function_version = aws_lambda_function.main.version
   name             = var.app_version
}

resource aws_lambda_provisioned_concurrency_config hello {
  function_name                     = aws_lambda_function.main.function_name
  provisioned_concurrent_executions = 1
  qualifier                         = aws_lambda_alias.hello_alias.name
}


data "archive_file" "dummy" {
  type        = "zip"
  output_path = "${path.module}/dummy.zip"

  source {
    content  = "dummy"
    filename = "bootstrap"
  }
}

resource "aws_iam_role" "lambda_role" {
  name = "hello-function-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name = "/aws/lambda/${local.function_name}"
}