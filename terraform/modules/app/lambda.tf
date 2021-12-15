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

resource "aws_lambda_permission" "magic_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.magic_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:us-west-2:${var.account_number}:${aws_api_gateway_rest_api.magic_api.id}/*/${aws_api_gateway_method.magic_post_method.http_method}/shake"
}