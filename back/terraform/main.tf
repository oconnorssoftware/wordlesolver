provider "aws" {
  region  = "us-east-2"
  profile = "default"
}

resource "random_pet" "lambda_bucket_name" {
  prefix = "wordle-backend-resources"
  length = 4
}

resource "aws_s3_bucket" "lambda_bucket" {
  bucket = random_pet.lambda_bucket_name.id

  force_destroy = true
}

// Zip of lambda handler
data "archive_file" "lambda_wordle" {
  output_path = "${path.module}/lambda_zip/lambda.zip"
  source_dir  = "${path.module}/../lambda"
  excludes    = ["__init__.py", "*.pyc"]
  type        = "zip"
}

resource "aws_s3_bucket_object" "lambda_wordle" {
  bucket = aws_s3_bucket.lambda_bucket.id

  key    = "lambda.zip"
  source = data.archive_file.lambda_wordle.output_path

  etag = filemd5(data.archive_file.lambda_wordle.output_path)
}

resource "aws_lambda_function" "wordle" {
  function_name    = "Wordle"
  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = aws_s3_bucket_object.lambda_wordle.key
  handler          = "handler.handler"
  role             = aws_iam_role.lambda_exec.arn
  runtime          = "python3.8"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cloudwatch_log_group" "wordle" {
  name = "/aws/lambda/${aws_lambda_function.wordle.function_name}"

  retention_in_days = 30
}

resource "aws_iam_role" "lambda_exec" {
  name = "serverless_lambda"

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
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

//api gateway
resource "aws_apigatewayv2_api" "lambda" {
  name          = "serverless_lambda_gw"
  protocol_type = "HTTP"
  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["*"]
    allow_headers = ["*"]
    max_age = 300//remove?
  }
}
resource "aws_apigatewayv2_stage" "lambda" {
  api_id = aws_apigatewayv2_api.lambda.id

  name        = "serverless_lambda_stage"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      }
    )
  }
}

resource "aws_apigatewayv2_integration" "wordle" {
  api_id = aws_apigatewayv2_api.lambda.id

  integration_uri    = aws_lambda_function.wordle.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "wordle" {
  api_id = aws_apigatewayv2_api.lambda.id

  route_key = "POST /hello"
  target    = "integrations/${aws_apigatewayv2_integration.wordle.id}"
}

resource "aws_cloudwatch_log_group" "api_gw" {
  name = "/aws/api_gw/${aws_apigatewayv2_api.lambda.name}"

  retention_in_days = 30
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.wordle.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.lambda.execution_arn}/*/*"
}

resource "aws_ssm_parameter" "api_url" {
  name  = "/wordle/invokeURL"
  type  = "String"
  value = aws_apigatewayv2_stage.lambda.invoke_url
}
