resource "aws_dynamodb_table" "links" {
  name         = "links"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "code"

  attribute {
    name = "code"
    type = "S"
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
  function_name    = "shortener"
  role             = aws_iam_role.lambda.arn
  runtime          = "python3.12"
  handler          = "handler.handler"
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256
}