resource "aws_lambda_function" "main" {
  for_each = var.function_list

  function_name = each.key
  role          = aws_iam_role.lambda_role.arn

  handler     = each.value.handler
  runtime     = each.value.runtime
  filename    = data.archive_file.dummy.output_path
  memory_size = each.value.memory_size
  timeout     = each.value.timeout
  publish     = true

  lifecycle {
    ignore_changes = all
  }
}

resource "aws_lambda_alias" "main" {
  depends_on = [
    aws_lambda_function.main
  ]

  for_each         = aws_lambda_function.main
  function_name    = aws_lambda_function.main[each.key].function_name
  function_version = aws_lambda_function.main[each.key].version
  name             = var.app_version
}

# resource aws_lambda_provisioned_concurrency_config hello {
#   function_name                     = aws_lambda_function.main.function_name
#   provisioned_concurrent_executions = 2
#   qualifier                         = aws_lambda_alias.main.name
# }


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

  for_each = aws_lambda_function.main

  name = "/aws/lambda/${each.key}"
}