output "api_url" {
  value = "${var.endpoint}/execute-api/${aws_apigatewayv2_api.http.id}/${aws_apigatewayv2_stage.prod.name}"
}