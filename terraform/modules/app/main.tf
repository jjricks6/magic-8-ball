# ==================== IAM ====================

resource "aws_iam_role" "magic_role" {
  name = "magic_role"

  assume_role_policy = <<-EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Action": "sts:AssumeRole",
          "Principal": {
            "Service": "lambda.amazonaws.com"
          },
          "Effect": "Allow",
          "Sid": ""
        }
      ]
    }
  EOF
}

data "aws_iam_policy_document" "policy_doc" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "*"
    ]
  }
}


resource "aws_iam_policy" "magic_policy" {
  name        = "magic_policy"
  path        = "/"
  description = "Basic policy"

  policy = data.aws_iam_policy_document.policy_doc.json
}

resource "aws_iam_role_policy_attachment" "magic_policy_attachment" {
  role       = aws_iam_role.magic_role.name
  policy_arn = aws_iam_policy.magic_policy.arn
}

# ==================== Lambda ====================

data "archive_file" "magic_lambda" {
  type        = "zip"
  source_file = "../../../lambda/${var.app_name}.py"
  output_path = "../../../lambda/${var.app_name}.zip"
}
resource "aws_lambda_function" "magic_lambda" {
  filename         = data.archive_file.magic_lambda.output_path
  function_name    = var.app_name
  role             = aws_iam_role.magic_role.arn
  handler          = "${var.app_name}.lambda_handler"
  runtime          = "python3.8"
  source_code_hash = data.archive_file.magic_lambda.output_base64sha256
  timeout          = 10
  tags             = var.tags

  environment {
    variables = {
      PARAMETER_STORE_PREFIX = "/${var.app_name}/"
      BUCKET_NAME            = "magic-bucket-${var.account_number}"
    }
  }
}

# ================ API Gateway ===============

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

# Lambda
resource "aws_lambda_permission" "magic_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.magic_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:us-west-2:${var.account_number}:${aws_api_gateway_rest_api.magic_api.id}/*/${aws_api_gateway_method.magic_post_method.http_method}/shake"
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



# resource "aws_api_gateway_domain_name" "magic_domain" {
#   regional_certificate_arn = module.acs.certificate.arn
#   domain_name              = "magic.byu-org-trn.amazon.byu.edu"

#   endpoint_configuration {
#     types = ["REGIONAL"]
#   }
# }

# resource "aws_api_gateway_base_path_mapping" "magic_mapping" {
#   api_id      = aws_api_gateway_rest_api.magic_api.id
#   stage_name  = aws_api_gateway_stage.magic_stage.stage_name
#   domain_name = aws_api_gateway_domain_name.magic_domain.domain_name
# }

# resource "aws_route53_record" "magic_r53_record" {
#   name    = aws_api_gateway_domain_name.magic_domain.domain_name
#   type    = "A"
#   zone_id = module.acs.route53_zone.zone_id

#   alias {
#     evaluate_target_health = true
#     name                   = aws_api_gateway_domain_name.magic_domain.regional_domain_name
#     zone_id                = aws_api_gateway_domain_name.magic_domain.regional_zone_id
#   }
# }
# ==================== S3 ====================

resource "aws_s3_bucket" "magic_bucket" {
  bucket = "magic-bucket-${var.account_number}"
  acl    = "public-read"
  tags   = var.tags
  policy = <<-EOF
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "PublicReadGetObject",
                "Effect": "Allow",
                "Principal": "*",
                "Action": "s3:GetObject",
                "Resource": "arn:aws:s3:::magic-bucket-${var.account_number}/*"
            }
        ]
    }
  EOF

  website {
    index_document = "index.html"
    error_document = "error.html"
  }
}

module "template_files" {
  source = "hashicorp/dir/template"

  base_dir = "../../../dist"
}

resource "aws_s3_bucket_object" "magic_dist" {
  for_each = module.template_files.files

  bucket       = aws_s3_bucket.magic_bucket.bucket
  key          = each.key
  content_type = each.value.content_type

  source  = each.value.source_path
  content = each.value.content

  etag = each.value.digests.md5
}