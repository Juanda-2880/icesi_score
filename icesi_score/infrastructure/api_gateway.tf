# ---------------------------------------------------------------------------
# GET /user/profile — devuelve el perfil del usuario autenticado
# ---------------------------------------------------------------------------
resource "aws_apigatewayv2_integration" "get_user_profile_integration" {
  api_id                 = aws_apigatewayv2_api.icesi_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.get_user_profile.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "get_user_profile_route" {
  api_id             = aws_apigatewayv2_api.icesi_api.id
  route_key          = "GET /user/profile"
  target             = "integrations/${aws_apigatewayv2_integration.get_user_profile_integration.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_auth.id
}

resource "aws_lambda_permission" "api_gw_get_user_profile" {
  statement_id  = "AllowAPIGatewayInvokeGetUserProfile"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_user_profile.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.icesi_api.execution_arn}/*/*"
}

# ---------------------------------------------------------------------------
# PUT /user/profile — actualiza el perfil del usuario autenticado
# ---------------------------------------------------------------------------
resource "aws_apigatewayv2_integration" "update_user_profile_integration" {
  api_id                 = aws_apigatewayv2_api.icesi_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.update_user_profile.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "update_user_profile_route" {
  api_id             = aws_apigatewayv2_api.icesi_api.id
  route_key          = "PUT /user/profile"
  target             = "integrations/${aws_apigatewayv2_integration.update_user_profile_integration.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_auth.id
}

resource "aws_lambda_permission" "api_gw_update_user_profile" {
  statement_id  = "AllowAPIGatewayInvokeUpdateUserProfile"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.update_user_profile.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.icesi_api.execution_arn}/*/*"
}

# ---------------------------------------------------------------------------
# DELETE /user — elimina la cuenta del usuario autenticado
# ---------------------------------------------------------------------------
resource "aws_apigatewayv2_integration" "delete_user_integration" {
  api_id                 = aws_apigatewayv2_api.icesi_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.delete_user.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "delete_user_route" {
  api_id             = aws_apigatewayv2_api.icesi_api.id
  route_key          = "DELETE /user"
  target             = "integrations/${aws_apigatewayv2_integration.delete_user_integration.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_auth.id
}

resource "aws_lambda_permission" "api_gw_delete_user" {
  statement_id  = "AllowAPIGatewayInvokeDeleteUser"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.delete_user.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.icesi_api.execution_arn}/*/*"
}

# ---------------------------------------------------------------------------
# POST /admin/users — crea un administrador (solo SUPERADMIN)
# ---------------------------------------------------------------------------
resource "aws_apigatewayv2_integration" "create_admin_user_integration" {
  api_id                 = aws_apigatewayv2_api.icesi_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.create_admin_user.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "create_admin_user_route" {
  api_id             = aws_apigatewayv2_api.icesi_api.id
  route_key          = "POST /admin/users"
  target             = "integrations/${aws_apigatewayv2_integration.create_admin_user_integration.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_auth.id
}

resource "aws_lambda_permission" "api_gw_create_admin_user" {
  statement_id  = "AllowAPIGatewayInvokeCreateAdminUser"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create_admin_user.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.icesi_api.execution_arn}/*/*"
}
