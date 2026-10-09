output "api_url" {
  value = "http://localhost:4566/execute-api/${aws_apigatewayv2_api.http.id}/${aws_apigatewayv2_stage.prod.name}"
}