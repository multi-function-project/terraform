resource "aws_lambda_function" "main" {
  for_each = var.function_list

  function_name = each.key
  role          = aws_iam_role.lambda_role.arn

  handler       = each.value.handler
  runtime       = each.value.runtime
  filename      = data.archive_file.dummy.output_path
  memory_size   = each.value.memory_size
  timeout       = each.value.timeout
  architectures = ["x86_64"]
  publish       = true

  lifecycle {
    ignore_changes = all
  }
}

locals {
  function_list = [
    for key, value in aws_lambda_function.main : {
      key              = key
      function_name    = value.function_name
      function_version = value.version
    }
  ]
  alias_list = [
    for pair in setproduct(local.function_list, var.api_version_list) : {
      function_name    = pair[0].key
      function_version = pair[0].function_version
      alias_name       = pair[1]
      key              = "${pair[0].key}:${pair[1]}"
    }
  ]
}
resource "aws_lambda_alias" "main" {
  depends_on = [
    aws_lambda_function.main
  ]

  for_each         = { for alias in local.alias_list : alias.key => alias }
  function_name    = each.value.function_name
  function_version = each.value.function_version
  name             = each.value.alias_name
}

# resource aws_lambda_provisioned_concurrency_config main {
#   function_name                     = aws_lambda_function.main.function_name
#   provisioned_concurrent_executions = 1
#   qualifier                         = aws_lambda_alias.main.name
# }

resource "aws_lambda_function_url" "main" {
  for_each           = aws_lambda_alias.main
  function_name      = each.value.function_name
  qualifier          = each.value.name
  authorization_type = "AWS_IAM"

  cors {
    allow_credentials = true
    allow_origins     = ["*"]
    allow_methods     = ["*"]
    allow_headers     = ["date", "keep-alive"]
    expose_headers    = ["keep-alive", "date"]
    max_age           = 86400
  }
}


resource "aws_lambda_permission" "main" {
  depends_on = [
    aws_lambda_function_url.main
  ]

  for_each      = aws_lambda_function_url.main
  statement_id  = "lambda-invoke-url"
  action        = "lambda:InvokeFunctionUrl"
  function_name = each.value.function_name
  principal     = "arn:aws:iam::321058214401:root"
  qualifier     = each.value.qualifier
}


data "archive_file" "dummy" {
  type        = "zip"
  source_dir  = "src"
  output_path = "${path.module}/dummy.zip"
}

resource "aws_iam_role" "lambda_role" {
  name = "hello-function-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
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
  for_each = aws_lambda_function.main
  name     = "/aws/lambda/${each.key}"
}
