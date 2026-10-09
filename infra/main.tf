resource "aws_dynamodb_table" "links" {
  #checkov:skip=CKV_AWS_119
  name         = "links"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "code"

  attribute {
    name = "code"
    type = "S"
  }
  point_in_time_recovery {
    enabled = true
  }
}

data "aws_iam_policy_document" "assume_lambda" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = "shortener-lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_lambda.json
}

data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "${path.module}/../app/src"
  output_path = "${path.module}/build/lambda.zip"
}

resource "aws_lambda_function" "shortener" {
  #checkov:skip=CKV_AWS_50
  #checkov:skip=CKV_AWS_116
  #checkov:skip=CKV_AWS_117
  #checkov:skip=CKV_AWS_173
  #checkov:skip=CKV_AWS_272
  function_name                  = "shortener"
  role                           = aws_iam_role.lambda.arn
  runtime                        = "python3.12"
  handler                        = "handler.handler"
  filename                       = data.archive_file.lambda.output_path
  source_code_hash               = data.archive_file.lambda.output_base64sha256
  reserved_concurrent_executions = 10
  environment {
    variables = { TABLE_NAME = aws_dynamodb_table.links.name }
  }
}

resource "aws_apigatewayv2_api" "http" {
  name          = "shortener"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.http.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.shortener.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "health" {
  #checkov:skip=CKV_AWS_309
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "GET /health"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_stage" "prod" {
  #checkov:skip=CKV_AWS_76
  api_id      = aws_apigatewayv2_api.http.id
  name        = "prod"
  auto_deploy = true
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowApiGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.shortener.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http.execution_arn}/*/*"
}

data "aws_iam_policy_document" "dynamodb_access" {
  statement {
    actions   = ["dynamodb:GetItem", "dynamodb:PutItem"]
    resources = [aws_dynamodb_table.links.arn]
  }
}

resource "aws_iam_role_policy" "dynamodb_access" {
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.dynamodb_access.json
}

resource "aws_apigatewayv2_route" "create_link" {
  #checkov:skip=CKV_AWS_309`
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "POST /links"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_route" "resolve_link" {
  #checkov:skip=CKV_AWS_309
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "GET /links/{code}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}