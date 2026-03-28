# 1. Empaquetar el código Python en un .zip
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "../backend/promote_admin.py" # Ruta hacia tu código Python
  output_path = "promote_admin.zip"
}

# 2. Crear el Rol de Permisos (IAM) para la Lambda
resource "aws_iam_role" "lambda_role" {
  name = "icesi_score_lambda_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# 3. Darle permiso a la Lambda para modificar Cognito
resource "aws_iam_role_policy" "lambda_cognito_policy" {
  name   = "lambda_cognito_admin_policy"
  role   = aws_iam_role.lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["cognito-idp:AdminAddUserToGroup"]
      Resource = aws_cognito_user_pool.icesi_score_pool.arn
    }]
  })
}

# 4. Crear la Función Lambda
resource "aws_lambda_function" "promote_admin_lambda" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "promoteAdminFunction"
  role             = aws_iam_role.lambda_role.arn
  handler          = "promote_admin.lambda_handler"
  runtime          = "python3.9"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      USER_POOL_ID = aws_cognito_user_pool.icesi_score_pool.id
    }
  }
}

# 5. Crear el API Gateway
resource "aws_apigatewayv2_api" "icesi_api" {
  name          = "icesi-score-api"
  protocol_type = "HTTP"
  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["POST", "GET", "OPTIONS"]
    allow_headers = ["Content-Type", "Authorization"]
  }
}

# 6. Conectar Cognito como Autorizador del API Gateway
resource "aws_apigatewayv2_authorizer" "cognito_auth" {
  api_id           = aws_apigatewayv2_api.icesi_api.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "cognito-authorizer"

  jwt_configuration {
    audience = [aws_cognito_user_pool_client.flutter_app_client.id]
    issuer   = "https://cognito-idp.${var.region}.amazonaws.com/${aws_cognito_user_pool.icesi_score_pool.id}"
  }
}

# 7. Crear la ruta y conectarla a la Lambda
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id                 = aws_apigatewayv2_api.icesi_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.promote_admin_lambda.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "promote_route" {
  api_id             = aws_apigatewayv2_api.icesi_api.id
  route_key          = "POST /promote-admin"
  target             = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_auth.id
}

# 8. Dar permiso al API Gateway para invocar la Lambda
resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.promote_admin_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.icesi_api.execution_arn}/*/*"
}

# 9. Mostrar la URL final del API
output "api_endpoint" {
  value = aws_apigatewayv2_api.icesi_api.api_endpoint
}