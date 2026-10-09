resource "aws_dynamodb_table" "links" {
  name         = "links"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "code"

  attribute {
    name = "code"
    type = "S"
  }
}