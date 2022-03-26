variable "app_version" {
  type = string
}

variable "api_key" {
  type = string
}

variable "function_list" {

  default = {
    "hello-function" = {
      handler     = "org.springframework.cloud.function.adapter.aws.FunctionInvoker::handleRequest"
      runtime     = "provided.al2"
      memory_size = 192
      timeout     = 3
    }
    "error-notify-function" = {
      handler     = "org.springframework.cloud.function.adapter.aws.FunctionInvoker::handleRequest"
      runtime     = "provided.al2"
      memory_size = 192
      timeout     = 3
    }
  }
}