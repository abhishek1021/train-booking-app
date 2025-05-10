output "mockjson_api_url" {
  value = aws_apigatewayv2_api.mockjson_api.api_endpoint
}

output "mockjson_custom_domain_target" {
  value = aws_apigatewayv2_domain_name.custom_domain.domain_name_configuration[0].target_domain_name
}
