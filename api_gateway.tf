resource "aws_api_gateway_rest_api" "main" {
  name        = "example-api-gateway"
  description = "example API Gateway"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "main" {
  depends_on = [
    aws_lambda_function.main
  ]

  for_each    = aws_lambda_function.main
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = replace(aws_lambda_function.main[each.key].function_name, "-function", "")
}

resource "aws_api_gateway_method" "main" {
  depends_on = [
    aws_api_gateway_resource.main
  ]

  for_each         = aws_api_gateway_resource.main
  rest_api_id      = aws_api_gateway_rest_api.main.id
  resource_id      = aws_api_gateway_resource.main[each.key].id
  http_method      = "POST"
  authorization    = "NONE"
  api_key_required = true
}

resource "aws_api_gateway_method_response" "main" {
  depends_on = [
    aws_api_gateway_method.main
  ]

  for_each    = aws_api_gateway_method.main
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_method.main[each.key].resource_id
  http_method = aws_api_gateway_method.main[each.key].http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
}

// https://qiita.com/neruneruo/items/87fab83e25c723ef878c
// https://zenn.dev/masaino/articles/dd9ee709799af0
resource "aws_api_gateway_method" "option" {
  depends_on = [
    aws_api_gateway_resource.main
  ]

  for_each      = aws_api_gateway_resource.main
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.main[each.key].id
  http_method   = "OPTIONS"
  authorization = "NONE"
}
resource "aws_api_gateway_method_response" "option" {
  depends_on = [
    aws_api_gateway_method.option
  ]

  for_each    = aws_api_gateway_method.option
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_method.option[each.key].resource_id
  http_method = aws_api_gateway_method.option[each.key].http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}
resource "aws_api_gateway_integration_response" "option" {
  depends_on = [
    aws_api_gateway_method_response.option
  ]

  for_each    = aws_api_gateway_method_response.option
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_method_response.option[each.key].resource_id
  http_method = aws_api_gateway_method_response.option[each.key].http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}
resource "aws_api_gateway_integration" "option" {
  depends_on = [
    aws_api_gateway_method.option
  ]

  for_each    = aws_api_gateway_method.option
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_method.option[each.key].resource_id
  http_method = aws_api_gateway_method.option[each.key].http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = <<EOF
{
  "statusCode": 200
}
EOF
  }
}

resource "aws_api_gateway_integration" "main" {
  depends_on = [
    aws_api_gateway_method.main,
    aws_lambda_function.main,
    aws_lambda_alias.main
  ]

  for_each    = aws_api_gateway_method.main
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_method.main[each.key].resource_id
  http_method = aws_api_gateway_method.main[each.key].http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/arn:aws:lambda:${var.region}:${data.aws_caller_identity.self.account_id}:function:${each.key}:${var.app_version}/invocations"
}

resource "aws_lambda_permission" "main" {
  depends_on = [
    aws_lambda_function.main,
    aws_lambda_alias.main
  ]

  for_each = aws_lambda_alias.main

  action        = "lambda:InvokeFunction"
  function_name = each.value.function_name
  principal     = "apigateway.amazonaws.com"
  qualifier     = each.value.name
  # The /*/*/* part allows invocation from any stage, method and resource path
  # within API Gateway REST API.
  source_arn = "${aws_api_gateway_rest_api.main.execution_arn}/*/*/*"
}


resource "aws_api_gateway_deployment" "main" {
  rest_api_id       = aws_api_gateway_rest_api.main.id
  stage_name        = var.app_version
  stage_description = "timestamp = ${timestamp()}"


  depends_on = [
    aws_api_gateway_integration.main
  ]

  lifecycle {
    create_before_destroy = true
  }
}

# resource "aws_api_gateway_method_settings" "main" {
#   rest_api_id = aws_api_gateway_rest_api.main.id
#   stage_name  = aws_api_gateway_deployment.main.stage_name
#   method_path = "*/*"

#   settings {
#     data_trace_enabled = true
#     logging_level      = "INFO"
#   }
# }

resource "aws_api_gateway_api_key" "main" {
  name    = "example_api_key"
  value   = var.api_key
  enabled = true
}

resource "aws_api_gateway_usage_plan" "main" {
  name       = "example_usage_plan"
  depends_on = [aws_api_gateway_deployment.main]

  api_stages {
    api_id = aws_api_gateway_rest_api.main.id
    stage  = aws_api_gateway_deployment.main.stage_name
  }
}

resource "aws_api_gateway_usage_plan_key" "main" {
  key_id        = aws_api_gateway_api_key.main.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.main.id
}
