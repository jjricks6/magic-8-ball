resource "aws_api_gateway_rest_api" "magic_api" {
  name                         = var.app_name
  disable_execute_api_endpoint = true
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "magic_resource" {
  parent_id   = aws_api_gateway_rest_api.magic_api.root_resource_id
  path_part   = "shake"
  rest_api_id = aws_api_gateway_rest_api.magic_api.id
}

resource "aws_api_gateway_method" "magic_options_method" {
  rest_api_id   = aws_api_gateway_rest_api.magic_api.id
  resource_id   = aws_api_gateway_resource.magic_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}
resource "aws_api_gateway_method_response" "magic_options_method_response" {
  rest_api_id = aws_api_gateway_rest_api.magic_api.id
  resource_id = aws_api_gateway_resource.magic_resource.id
  http_method = aws_api_gateway_method.magic_options_method.http_method
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
resource "aws_api_gateway_integration" "magic_options_integration" {
  rest_api_id = aws_api_gateway_rest_api.magic_api.id
  resource_id = aws_api_gateway_resource.magic_resource.id
  http_method = aws_api_gateway_method.magic_options_method.http_method
  type        = "MOCK"
}
resource "aws_api_gateway_integration_response" "magic_options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.magic_api.id
  resource_id = aws_api_gateway_resource.magic_resource.id
  http_method = aws_api_gateway_method.magic_options_method.http_method
  status_code = aws_api_gateway_method_response.magic_options_method_response.status_code
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,POST'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

resource "aws_api_gateway_method" "magic_post_method" {
  authorization = "NONE"
  http_method   = "POST"
  resource_id   = aws_api_gateway_resource.magic_resource.id
  rest_api_id   = aws_api_gateway_rest_api.magic_api.id
}

resource "aws_api_gateway_method_response" "magic_post_method_response" {
  rest_api_id = aws_api_gateway_rest_api.magic_api.id
  resource_id = aws_api_gateway_resource.magic_resource.id
  http_method = aws_api_gateway_method.magic_post_method.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}


resource "aws_api_gateway_integration" "magic_post_integration" {
  rest_api_id             = aws_api_gateway_rest_api.magic_api.id
  resource_id             = aws_api_gateway_resource.magic_resource.id
  http_method             = aws_api_gateway_method.magic_post_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.magic_lambda.invoke_arn
}

resource "aws_api_gateway_deployment" "magic_deployment" {
  rest_api_id = aws_api_gateway_rest_api.magic_api.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.magic_resource.id,
      aws_api_gateway_method.magic_post_method.id,
      aws_api_gateway_integration.magic_post_integration.id,
      aws_api_gateway_integration.magic_options_integration,
      aws_api_gateway_integration_response.magic_options_integration_response,
      aws_api_gateway_method.magic_options_method,
      aws_api_gateway_method_response.magic_options_method_response,
      aws_api_gateway_method_response.magic_post_method_response
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}



resource "aws_api_gateway_stage" "magic_stage" {
  deployment_id = aws_api_gateway_deployment.magic_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.magic_api.id
  stage_name    = "prd"
}



resource "aws_api_gateway_domain_name" "magic_api_domain" {
  depends_on               = [aws_acm_certificate_validation.magic_cert_oregon]
  regional_certificate_arn = aws_acm_certificate.magic_cert_oregon.arn
  domain_name              = "api.${var.domain_name}"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_base_path_mapping" "magic_mapping" {
  api_id      = aws_api_gateway_rest_api.magic_api.id
  stage_name  = aws_api_gateway_stage.magic_stage.stage_name
  domain_name = aws_api_gateway_domain_name.magic_api_domain.domain_name
}