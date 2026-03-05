module "api_gateway" {
  source = "./src/modules/api_gateway"

  lambda_invoke_arns = {
    for k, v in aws_lambda_function.lambdas : k => v.invoke_arn
  }

  lambda_function_names = {
    for k, v in aws_lambda_function.lambdas : k => v.function_name
  }
}

output "api_url" {
  value = module.api_gateway.invoke_url
}