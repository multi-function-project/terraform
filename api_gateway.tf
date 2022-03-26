resource "aws_api_gateway_rest_api" "example" {
  name        = "example-api-gateway"
  description = "example API Gateway"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "hello_world" {
  rest_api_id = aws_api_gateway_rest_api.example.id
  parent_id   = aws_api_gateway_rest_api.example.root_resource_id
  path_part   = "hello-world"
}

resource "aws_api_gateway_method" "hello_world" {
  rest_api_id      = aws_api_gateway_rest_api.example.id
  resource_id      = aws_api_gateway_resource.hello_world.id
  http_method      = "POST"
  authorization    = "NONE"
  api_key_required = true
}

resource "aws_api_gateway_method_response" "hello_world" {
  rest_api_id = aws_api_gateway_rest_api.example.id
  resource_id = aws_api_gateway_resource.hello_world.id
  http_method = aws_api_gateway_method.hello_world.http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
  depends_on = [aws_api_gateway_method.hello_world]
}

resource "aws_api_gateway_integration" "hello_world" {
  rest_api_id             = aws_api_gateway_rest_api.example.id
  resource_id             = aws_api_gateway_resource.hello_world.id
  http_method             = aws_api_gateway_method.hello_world.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.main.invoke_arn
}

resource "aws_lambda_permission" "hello_world" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.main.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.example.execution_arn}/*/${aws_api_gateway_method.hello_world.http_method}/${aws_api_gateway_resource.hello_world.path_part}"
}


resource "aws_api_gateway_deployment" "example" {
  rest_api_id       = aws_api_gateway_rest_api.example.id
  stage_name        = "example"
  stage_description = "timestamp = ${timestamp()}"

  depends_on = [
    aws_api_gateway_integration.hello_world
  ]

  lifecycle {
    create_before_destroy = true
  }
}

# resource "aws_api_gateway_method_settings" "example" {
#   rest_api_id = aws_api_gateway_rest_api.example.id
#   stage_name  = aws_api_gateway_deployment.example.stage_name
#   method_path = "*/*"

#   settings {
#     data_trace_enabled = true
#     logging_level      = "INFO"
#   }
# }

resource "aws_api_gateway_api_key" "example" {
  name    = "example_api_key"
  value = "AGq69sKI438ZJELb4DOR4cjuQKMqe4V6bf91GeXd"
  enabled = true
}

resource "aws_api_gateway_usage_plan" "example" {
  name       = "example_usage_plan"
  depends_on = [aws_api_gateway_deployment.example]

  api_stages {
    api_id = aws_api_gateway_rest_api.example.id
    stage  = aws_api_gateway_deployment.example.stage_name
  }
}

resource "aws_api_gateway_usage_plan_key" "example" {
  key_id        = aws_api_gateway_api_key.example.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.example.id
}